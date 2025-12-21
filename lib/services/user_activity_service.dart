import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserActivityService {
  static final UserActivityService _instance = UserActivityService._internal();

  factory UserActivityService() {
    return _instance;
  }

  UserActivityService._internal();

  Timer? _heartbeatTimer;
  Timer? _clickFlushTimer;
  int _localClickCount = 0;
  final int _flushIntervalSeconds = 30;
  final int _heartbeatIntervalMinutes = 5;

  void init() {
    _startHeartbeat();
    _startClickFlusher();
  }

  void _startHeartbeat() {
    _sendHeartbeat(); 
    _heartbeatTimer = Timer.periodic(
      Duration(minutes: _heartbeatIntervalMinutes),
      (timer) => _sendHeartbeat(),
    );
  }

  Future<void> _sendHeartbeat() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
          {
            'lastActive': FieldValue.serverTimestamp(),
            'isOnline':
                true, 
          },
        );
      } catch (e) {
        print("Heartbeat failed: $e");
      }
    }
  }

  void logClick() {
    _localClickCount++;
  }

  void _startClickFlusher() {
    _clickFlushTimer = Timer.periodic(
      Duration(seconds: _flushIntervalSeconds),
      (timer) => _flushClicks(),
    );
  }

  Future<void> _flushClicks() async {
    if (_localClickCount > 0) {
      int clicksToSync = _localClickCount;
      _localClickCount = 0; 

      try {
        
        await FirebaseFirestore.instance
            .collection('stats')
            .doc('activity')
            .set({
              'totalClicks': FieldValue.increment(clicksToSync),
              'lastUpdated': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      } catch (e) {
        print("Click flush failed: $e");
        _localClickCount += clicksToSync; 
      }
    }
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _clickFlushTimer?.cancel();
    _flushClicks(); 
  }
}
