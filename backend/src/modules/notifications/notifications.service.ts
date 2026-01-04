import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { PushService } from './push.service';
import { SmsService } from './sms.service';
import { WhatsAppService } from './whatsapp.service';

export interface NotificationPayload {
  userId: string;
  title: string;
  body: string;
  data?: Record<string, any>;
}

@Injectable()
export class NotificationsService {
  constructor(
    private prisma: PrismaService,
    private pushService: PushService,
    private smsService: SmsService,
    private whatsappService: WhatsAppService,
  ) {}

  /**
   * Send push notification
   */
  async sendPush(payload: NotificationPayload): Promise<boolean> {
    try {
      // Get user's push tokens
      const tokens = await this.prisma.pushToken.findMany({
        where: { userId: payload.userId, isActive: true },
      });

      if (tokens.length === 0) {
        console.log(`No push tokens for user ${payload.userId}`);
        return false;
      }

      // Send push notification
      for (const token of tokens) {
        await this.pushService.send(token.token, payload);
      }

      // Save notification record
      await this.prisma.notification.create({
        data: {
          userId: payload.userId,
          type: 'PUSH',
          title: payload.title,
          body: payload.body,
          data: payload.data,
        },
      });

      return true;
    } catch (error) {
      console.error('Push notification error:', error);
      return false;
    }
  }

  /**
   * Send SMS
   */
  async sendSms(userId: string, message: string): Promise<boolean> {
    try {
      const user = await this.prisma.user.findUnique({
        where: { id: userId },
      });

      if (!user) return false;

      await this.smsService.send(user.phone, message);

      // Save notification record
      await this.prisma.notification.create({
        data: {
          userId,
          type: 'SMS',
          title: 'SMS',
          body: message,
        },
      });

      return true;
    } catch (error) {
      console.error('SMS error:', error);
      return false;
    }
  }

  /**
   * Send WhatsApp message
   */
  async sendWhatsApp(userId: string, message: string): Promise<boolean> {
    try {
      const user = await this.prisma.user.findUnique({
        where: { id: userId },
      });

      if (!user) return false;

      await this.whatsappService.send(user.phone, message);

      // Save notification record
      await this.prisma.notification.create({
        data: {
          userId,
          type: 'WHATSAPP',
          title: 'WhatsApp',
          body: message,
        },
      });

      return true;
    } catch (error) {
      console.error('WhatsApp error:', error);
      return false;
    }
  }

  /**
   * Get user's notifications
   */
  async getUserNotifications(userId: string, page = 1, limit = 20) {
    const [notifications, total] = await Promise.all([
      this.prisma.notification.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.notification.count({ where: { userId } }),
    ]);

    return {
      data: notifications,
      meta: { total, page, limit },
    };
  }

  /**
   * Mark notification as read
   */
  async markAsRead(notificationId: string, userId: string): Promise<void> {
    await this.prisma.notification.updateMany({
      where: { id: notificationId, userId },
      data: { isRead: true },
    });
  }

  /**
   * Mark all notifications as read
   */
  async markAllAsRead(userId: string): Promise<void> {
    await this.prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true },
    });
  }

  /**
   * Get unread count
   */
  async getUnreadCount(userId: string): Promise<number> {
    return this.prisma.notification.count({
      where: { userId, isRead: false },
    });
  }

  /**
   * Register push token
   */
  async registerPushToken(
    userId: string,
    token: string,
    platform: 'android' | 'ios',
  ): Promise<void> {
    await this.prisma.pushToken.upsert({
      where: { token },
      create: { userId, token, platform },
      update: { userId, isActive: true },
    });
  }

  /**
   * Unregister push token
   */
  async unregisterPushToken(token: string): Promise<void> {
    await this.prisma.pushToken.updateMany({
      where: { token },
      data: { isActive: false },
    });
  }
}
