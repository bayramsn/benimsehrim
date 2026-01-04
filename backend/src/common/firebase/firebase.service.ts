import { Injectable, OnModuleInit, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';

@Injectable()
export class FirebaseService implements OnModuleInit {
  private readonly logger = new Logger(FirebaseService.name);
  private firebaseApp: admin.app.App;

  constructor(private configService: ConfigService) {}

  onModuleInit() {
    this.initializeFirebase();
  }

  private initializeFirebase() {
    try {
      // Check if Firebase is already initialized
      if (admin.apps.length > 0) {
        this.firebaseApp = admin.app();
        return;
      }

      // Get credentials from environment
      const projectId = this.configService.get<string>('FIREBASE_PROJECT_ID');
      const clientEmail = this.configService.get<string>('FIREBASE_CLIENT_EMAIL');
      const privateKey = this.configService.get<string>('FIREBASE_PRIVATE_KEY')?.replace(/\\n/g, '\n');

      if (projectId && clientEmail && privateKey) {
        // Initialize with service account credentials
        this.firebaseApp = admin.initializeApp({
          credential: admin.credential.cert({
            projectId,
            clientEmail,
            privateKey,
          }),
        });
        this.logger.log('Firebase Admin SDK initialized with service account');
      } else {
        // Try to initialize with default credentials (for GCP environments)
        this.firebaseApp = admin.initializeApp({
          credential: admin.credential.applicationDefault(),
        });
        this.logger.log('Firebase Admin SDK initialized with default credentials');
      }
    } catch (error) {
      this.logger.warn('Firebase initialization failed. Push notifications will be disabled.', error);
    }
  }

  /**
   * Send push notification to a single device
   */
  async sendToDevice(token: string, notification: NotificationPayload, data?: Record<string, string>): Promise<string | null> {
    if (!this.firebaseApp) {
      this.logger.warn('Firebase not initialized, skipping push notification');
      return null;
    }

    try {
      const message: admin.messaging.Message = {
        token,
        notification: {
          title: notification.title,
          body: notification.body,
          imageUrl: notification.imageUrl,
        },
        data: data || {},
        android: {
          priority: 'high',
          notification: {
            channelId: notification.channelId || 'benimsehrim_default',
            sound: 'default',
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          },
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: notification.title,
                body: notification.body,
              },
              badge: 1,
              sound: 'default',
            },
          },
        },
      };

      const response = await admin.messaging().send(message);
      this.logger.log(`Push notification sent: ${response}`);
      return response;
    } catch (error) {
      this.logger.error('Failed to send push notification', error);
      return null;
    }
  }

  /**
   * Send push notification to multiple devices
   */
  async sendToDevices(tokens: string[], notification: NotificationPayload, data?: Record<string, string>): Promise<admin.messaging.BatchResponse | null> {
    if (!this.firebaseApp || tokens.length === 0) {
      return null;
    }

    try {
      const message: admin.messaging.MulticastMessage = {
        tokens,
        notification: {
          title: notification.title,
          body: notification.body,
          imageUrl: notification.imageUrl,
        },
        data: data || {},
        android: {
          priority: 'high',
          notification: {
            channelId: notification.channelId || 'benimsehrim_default',
            sound: 'default',
          },
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: notification.title,
                body: notification.body,
              },
              badge: 1,
              sound: 'default',
            },
          },
        },
      };

      const response = await admin.messaging().sendEachForMulticast(message);
      this.logger.log(`Batch push notification sent: ${response.successCount}/${tokens.length} successful`);
      return response;
    } catch (error) {
      this.logger.error('Failed to send batch push notification', error);
      return null;
    }
  }

  /**
   * Send to topic subscribers
   */
  async sendToTopic(topic: string, notification: NotificationPayload, data?: Record<string, string>): Promise<string | null> {
    if (!this.firebaseApp) {
      return null;
    }

    try {
      const message: admin.messaging.Message = {
        topic,
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: data || {},
      };

      const response = await admin.messaging().send(message);
      this.logger.log(`Topic notification sent to ${topic}: ${response}`);
      return response;
    } catch (error) {
      this.logger.error(`Failed to send topic notification to ${topic}`, error);
      return null;
    }
  }

  /**
   * Subscribe device to topic
   */
  async subscribeToTopic(tokens: string[], topic: string): Promise<void> {
    if (!this.firebaseApp || tokens.length === 0) {
      return;
    }

    try {
      await admin.messaging().subscribeToTopic(tokens, topic);
      this.logger.log(`Subscribed ${tokens.length} devices to topic: ${topic}`);
    } catch (error) {
      this.logger.error(`Failed to subscribe to topic ${topic}`, error);
    }
  }

  /**
   * Unsubscribe device from topic
   */
  async unsubscribeFromTopic(tokens: string[], topic: string): Promise<void> {
    if (!this.firebaseApp || tokens.length === 0) {
      return;
    }

    try {
      await admin.messaging().unsubscribeFromTopic(tokens, topic);
      this.logger.log(`Unsubscribed ${tokens.length} devices from topic: ${topic}`);
    } catch (error) {
      this.logger.error(`Failed to unsubscribe from topic ${topic}`, error);
    }
  }

  /**
   * Verify Firebase ID token (for user authentication from mobile)
   */
  async verifyIdToken(idToken: string): Promise<admin.auth.DecodedIdToken | null> {
    if (!this.firebaseApp) {
      return null;
    }

    try {
      return await admin.auth().verifyIdToken(idToken);
    } catch (error) {
      this.logger.error('Failed to verify ID token', error);
      return null;
    }
  }
}

export interface NotificationPayload {
  title: string;
  body: string;
  imageUrl?: string;
  channelId?: string;
}
