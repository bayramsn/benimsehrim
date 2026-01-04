import { Injectable } from '@nestjs/common';
import { FirebaseService, NotificationPayload } from '../../common/firebase/firebase.service';

@Injectable()
export class PushService {
  constructor(private firebaseService: FirebaseService) {}

  /**
   * Send push notification to a single device
   */
  async send(
    token: string,
    payload: {
      title: string;
      body: string;
      data?: Record<string, any>;
    },
  ): Promise<boolean> {
    const notification: NotificationPayload = {
      title: payload.title,
      body: payload.body,
    };

    // Add channel based on notification type
    if (payload.data?.type) {
      const type = payload.data.type;
      if (type === 'NEW_ORDER' || type === 'ORDER_STATUS') {
        notification.channelId = 'benimsehrim_orders';
      } else if (type === 'NEW_RIDE_CALL' || type === 'RIDE_STATUS') {
        notification.channelId = 'benimsehrim_taxi';
      } else if (type === 'CHAT_MESSAGE') {
        notification.channelId = 'benimsehrim_chat';
      }
    }

    // Convert data values to strings for FCM
    const stringData: Record<string, string> = {};
    if (payload.data) {
      Object.entries(payload.data).forEach(([key, value]) => {
        stringData[key] = String(value);
      });
    }

    const result = await this.firebaseService.sendToDevice(token, notification, stringData);
    return result !== null;
  }

  /**
   * Send push notification to multiple devices
   */
  async sendToMany(
    tokens: string[],
    payload: {
      title: string;
      body: string;
      data?: Record<string, any>;
    },
  ): Promise<number> {
    if (tokens.length === 0) return 0;

    const notification: NotificationPayload = {
      title: payload.title,
      body: payload.body,
    };

    const stringData: Record<string, string> = {};
    if (payload.data) {
      Object.entries(payload.data).forEach(([key, value]) => {
        stringData[key] = String(value);
      });
    }

    const result = await this.firebaseService.sendToDevices(tokens, notification, stringData);
    return result?.successCount || 0;
  }

  /**
   * Send push notification to topic subscribers
   */
  async sendToTopic(
    topic: string,
    payload: {
      title: string;
      body: string;
      data?: Record<string, any>;
    },
  ): Promise<boolean> {
    const notification: NotificationPayload = {
      title: payload.title,
      body: payload.body,
    };

    const stringData: Record<string, string> = {};
    if (payload.data) {
      Object.entries(payload.data).forEach(([key, value]) => {
        stringData[key] = String(value);
      });
    }

    const result = await this.firebaseService.sendToTopic(topic, notification, stringData);
    return result !== null;
  }

  /**
   * Subscribe tokens to a topic
   */
  async subscribeToTopic(tokens: string[], topic: string): Promise<void> {
    await this.firebaseService.subscribeToTopic(tokens, topic);
  }

  /**
   * Unsubscribe tokens from a topic
   */
  async unsubscribeFromTopic(tokens: string[], topic: string): Promise<void> {
    await this.firebaseService.unsubscribeFromTopic(tokens, topic);
  }
}
