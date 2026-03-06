import firebase_admin
from firebase_admin import credentials, firestore, messaging
import logging
from typing import List

logger = logging.getLogger(__name__)

# Initialize Firebase Admin SDK (call this once at startup in main.py)
_app = None

def initialize_firebase_admin():
    """
    Initialize Firebase Admin SDK with service account credentials.
    
    Place your service account JSON file as 'backend/serviceAccountKey.json'
    Download from: Firebase Console → Project Settings → Service Accounts → Generate New Private Key
    
    If file not found, falls back to Application Default Credentials (requires firebase CLI login)
    """
    global _app
    try:
        if not _app:
            import os
            service_account_path = os.path.join(
                os.path.dirname(__file__), 
                '..', 
                'serviceAccountKey.json'
            )
            
            if os.path.exists(service_account_path):
                # Use service account key file
                cred = credentials.Certificate(service_account_path)
                _app = firebase_admin.initialize_app(cred)
                logger.info("[Firebase Admin] ✅ Initialized with service account key")
            else:
                # Use Application Default Credentials
                _app = firebase_admin.initialize_app()
                logger.info("[Firebase Admin] ✅ Initialized with default credentials")
                logger.warning(
                    "[Firebase Admin] No serviceAccountKey.json found. "
                    "For production, download from Firebase Console → Project Settings → Service Accounts"
                )
    except Exception as e:
        logger.error(f"[Firebase Admin] ❌ Failed to initialize: {e}")
        logger.info("[Firebase Admin] See backend/FIREBASE_SETUP.md for setup instructions")


def send_live_broadcast_notification(channel_id: str, broadcast_id: str):
    """
    Send push notification to all users subscribed to a channel when GO LIVE happens.
    Fetches broadcast and channel details from Firestore.
    
    Args:
        channel_id: The ID of the channel going live
        broadcast_id: The ID of the broadcast
    """
    try:
        db = firestore.client()
        
        # 1. Fetch broadcast document to get title
        broadcast_ref = db.collection('broadcasts').document(broadcast_id)
        broadcast_doc = broadcast_ref.get()
        
        if not broadcast_doc.exists:
            logger.warning(f"[FCM] Broadcast '{broadcast_id}' not found in Firestore")
            return
        
        broadcast_data = broadcast_doc.to_dict()
        title = broadcast_data.get('title', 'Untitled Broadcast')
        
        # 2. Fetch channel document to get channel name
        channel_ref = db.collection('channels').document(channel_id)
        channel_doc = channel_ref.get()
        
        if not channel_doc.exists:
            logger.warning(f"[FCM] Channel '{channel_id}' not found in Firestore")
            return
        
        channel_data = channel_doc.to_dict()
        channel_name = channel_data.get('name', 'Unknown Channel')
        
        # 3. Get all users subscribed to this channel
        users_ref = db.collection('users')
        users_query = users_ref.where('joined_channels', 'array_contains', channel_id).stream()
        
        fcm_tokens = []
        for user_doc in users_query:
            user_data = user_doc.to_dict()
            fcm_token = user_data.get('fcmToken')
            if fcm_token:
                fcm_tokens.append(fcm_token)
        
        if not fcm_tokens:
            logger.warning(f"[FCM] No subscribers with FCM tokens for channel '{channel_name}'")
            return
        
        logger.info(f"[FCM] Found {len(fcm_tokens)} subscribers for channel '{channel_name}'")
        
        # 4. Create notification payload
        notification = messaging.Notification(
            title=f"🔴 {channel_name} is LIVE!",
            body=f"{title}",
        )
        
        # 5. Create data payload (for handling notification tap)
        data = {
            'type': 'live_broadcast',
            'broadcastId': broadcast_id,
            'channelId': channel_id,
            'channelName': channel_name,
            'title': title,
        }
        
        # 6. Send to all tokens (batch of 500 max per FCM rules)
        batch_size = 500
        success_count = 0
        failure_count = 0
        
        for i in range(0, len(fcm_tokens), batch_size):
            batch_tokens = fcm_tokens[i:i+batch_size]
            
            message = messaging.MulticastMessage(
                notification=notification,
                data=data,
                tokens=batch_tokens,
                android=messaging.AndroidConfig(
                    priority='high',
                    notification=messaging.AndroidNotification(
                        sound='default',
                        channel_id='live_broadcasts',
                    ),
                ),
                apns=messaging.APNSConfig(
                    payload=messaging.APNSPayload(
                        aps=messaging.Aps(
                            sound='default',
                            badge=1,
                        ),
                    ),
                ),
            )
            
            try:
                batch_response = messaging.send_multicast(message)
                success_count += batch_response.success_count
                failure_count += batch_response.failure_count
                
                # Log failures
                if batch_response.failure_count > 0:
                    for idx, resp in enumerate(batch_response.responses):
                        if not resp.success:
                            logger.error(
                                f"[FCM] Failed to send to token {batch_tokens[idx][:20]}...: "
                                f"{resp.exception}"
                            )
                            
            except Exception as e:
                logger.error(f"[FCM] Error sending batch: {e}")
                failure_count += len(batch_tokens)
        
        logger.info(
            f"[FCM] 🎉 Sent {success_count} notifications successfully, "
            f"{failure_count} failed for broadcast '{title}' on '{channel_name}'"
        )
        
    except Exception as e:
        logger.error(f"[FCM] Error sending live broadcast notifications: {e}")


def send_notification_to_user(user_id: str, title: str, body: str, data: dict = None):
    """
    Send push notification to a specific user.
    
    Args:
        user_id: Firestore user document ID
        title: Notification title
        body: Notification body
        data: Optional data payload
    """
    try:
        db = firestore.client()
        
        # Get user's FCM token
        user_doc = db.collection('users').document(user_id).get()
        if not user_doc.exists:
            logger.warning(f"[FCM] User '{user_id}' not found")
            return
        
        user_data = user_doc.to_dict()
        fcm_token = user_data.get('fcmToken')
        
        if not fcm_token:
            logger.warning(f"[FCM] No FCM token for user '{user_id}'")
            return
        
        # Create and send message
        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data=data or {},
            token=fcm_token,
        )
        
        response = messaging.send(message)
        logger.info(f"[FCM] Sent notification to user '{user_id}': {response}")
        
    except Exception as e:
        logger.error(f"[FCM] Error sending notification to user '{user_id}': {e}")
