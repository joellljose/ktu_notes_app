

from flask import Flask, request, jsonify
from flask_cors import CORS



app = Flask(__name__)
CORS(app)

















    

    







        




















import firebase_admin
from firebase_admin import credentials, messaging, firestore



try:
    cred = credentials.Certificate("serviceAccountKey.json")
    firebase_admin.initialize_app(cred)
    print("Firebase Admin Initialized")
except Exception as e:
    print(f"Warning: Firebase Admin not initialized: {e}")

@app.route('/send-notification', methods=['POST'])
def send_notification():
    data = request.json
    title = data.get('title')
    body = data.get('body')

    if not title or not body:
        return jsonify({"error": "Missing title or body"}), 400

    try:
        
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            topic='all_users',
        )

        
        response = messaging.send(message)
        
        # --- NEW: Save to Firestore ---
        try:
            db = firestore.client()
            db.collection('notifications').add({
                'title': title,
                'body': body,
                'timestamp': firestore.SERVER_TIMESTAMP
            })
            print("Notification saved to Firestore history")
        except Exception as db_error:
            print(f"Error saving to Firestore: {db_error}")
        # ------------------------------

        print('Successfully sent message:', response)
        return jsonify({"status": "success", "messageId": response})
    except Exception as e:
        print('Error sending message:', e)
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    
    app.run(host='0.0.0.0', port=5000, debug=True)




    