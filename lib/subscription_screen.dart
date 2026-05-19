import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionScreen extends StatefulWidget {
  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late Razorpay _razorpay;
  bool _isProcessing = false;
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print("Payment Success: \${response.paymentId}");
    
    // Update Firebase Firestore
    if (user != null) {
      try {
        DateTime startDate = DateTime.now();
        DateTime expiryDate = startDate.add(const Duration(days: 30));
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
          'isSubscribed': true,
          'subscriptionStartDate': Timestamp.fromDate(startDate),
          'subscriptionExpiry': Timestamp.fromDate(expiryDate),
          'paymentId': response.paymentId,
          'amountPaid': 1, // Storing in INR for display
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Subscription activated successfully! ❤️")),
          );
          Navigator.pop(context, true); // Return true indicating success
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error updating subscription: \$e")),
          );
        }
      }
    }
    
    setState(() {
      _isProcessing = false;
    });
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print("Payment Error: \${response.code} - \${response.message}");
    setState(() {
      _isProcessing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment failed: \${response.message}")),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print("External Wallet: \${response.walletName}");
    setState(() {
      _isProcessing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("External Wallet Selected: \${response.walletName}")),
    );
  }

  void _startPayment() {
    setState(() {
      _isProcessing = true;
    });
    
    // Amount is in paisa, so 99 INR = 9900 paisa
    var options = {
      'key': "rzp_live_SUjNShSgFX0cfL", 
      'amount': 100, 
      'name': 'KTU Notes Pro',
      'description': 'Monthly Subscription for AI Features',
      'prefill': {
        'contact': '', // Optional
        'email': user?.email ?? '',
      },
      'theme': {
        'color': '#009688' // Teal
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Premium Access"),
        backgroundColor: Colors.teal,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 80,
                color: Colors.purple,
              ),
              const SizedBox(height: 20),
              const Text(
                "Unlock AI Superpowers",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Supercharge your learning with KTU Notes Premium. Get unlimited access to AI Discovery Tools.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 40),
              
              _buildFeatureItem(Icons.summarize, "Smart PDF Summarizer"),
              _buildFeatureItem(Icons.psychology, "AI Concept Explainer & Doubt Chat"),
              _buildFeatureItem(Icons.quiz, "AI Generated Quizzes for self-evaluation"),
              _buildFeatureItem(Icons.schema, "Automatic Mermaid Diagrams generation"),
              _buildFeatureItem(Icons.search, "Semantic Smart Search across syllabus"),
              
              const SizedBox(height: 40),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Column(
                  children: [
                    const Text(
                      "₹1 / month",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Cancel anytime. No hidden fees.",
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: _isProcessing ? null : _startPayment,
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Upgrade Now",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
