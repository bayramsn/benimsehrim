import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';

export interface DailyTask {
  id: string;
  title: string;
  description: string;
  icon: string;
  reward: number;
  rewardType: 'points' | 'discount' | 'freeDelivery';
  target: number;
  current: number;
  completed: boolean;
  expiresAt: Date;
}

export interface DailyTasksResponse {
  tasks: DailyTask[];
  streak: number;
  totalPointsEarned: number;
  refreshesIn: number; // seconds until midnight
}

// Görev şablonları
const TASK_TEMPLATES = [
  {
    id: 'first_order',
    title: 'İlk Sipariş',
    description: 'Bugün bir sipariş ver',
    icon: '🛍️',
    reward: 50,
    rewardType: 'points' as const,
    target: 1,
    type: 'ORDER_COUNT',
  },
  {
    id: 'three_orders',
    title: 'Alışveriş Ustası',
    description: '3 farklı mağazadan sipariş ver',
    icon: '🏆',
    reward: 100,
    rewardType: 'points' as const,
    target: 3,
    type: 'UNIQUE_STORES',
  },
  {
    id: 'review',
    title: 'Yorum Yaz',
    description: 'Bir sipariş için yorum yap',
    icon: '⭐',
    reward: 30,
    rewardType: 'points' as const,
    target: 1,
    type: 'REVIEW_COUNT',
  },
  {
    id: 'spend_100',
    title: 'Büyük Alışveriş',
    description: '100₺ ve üzeri harca',
    icon: '💰',
    reward: 10,
    rewardType: 'discount' as const,
    target: 100,
    type: 'TOTAL_SPENT',
  },
  {
    id: 'share_app',
    title: 'Arkadaş Davet Et',
    description: 'Referans kodunu paylaş',
    icon: '👥',
    reward: 1,
    rewardType: 'freeDelivery' as const,
    target: 1,
    type: 'REFERRAL_SHARE',
  },
  {
    id: 'taxi_ride',
    title: 'Yolculuk Yap',
    description: 'Bir taksi yolculuğu tamamla',
    icon: '🚕',
    reward: 40,
    rewardType: 'points' as const,
    target: 1,
    type: 'TAXI_RIDE',
  },
];

@Injectable()
export class DailyTasksService {
  private readonly logger = new Logger(DailyTasksService.name);

  constructor(
    private prisma: PrismaService,
    private notificationsService: NotificationsService,
  ) {}

  /**
   * Kullanıcının günlük görevlerini getir
   */
  async getDailyTasks(userId: string): Promise<DailyTasksResponse> {
    const today = this.getToday();
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    // Kullanıcının bugünkü aktivitelerini al
    const [orders, reviews, taxiRides, userProgress] = await Promise.all([
      this.prisma.order.findMany({
        where: { userId, createdAt: { gte: today } },
        select: { storeId: true, total: true },
      }),
      this.prisma.review.count({
        where: { userId, createdAt: { gte: today } },
      }),
      this.prisma.taxiRide.count({
        where: { userId, status: 'COMPLETED', createdAt: { gte: today } },
      }),
      this.prisma.dailyTaskProgress.findUnique({
        where: { 
          id: `${userId}_${today.toISOString().split('T')[0]}`,
        },
      }),
    ]);

    // Streak hesapla
    const streak = await this.calculateStreak(userId);

    // Aktivite metrikleri
    const metrics = {
      ORDER_COUNT: orders.length,
      UNIQUE_STORES: new Set(orders.map(o => o.storeId)).size,
      REVIEW_COUNT: reviews,
      TOTAL_SPENT: orders.reduce((sum, o) => sum + (o.total || 0), 0),
      REFERRAL_SHARE: (userProgress?.referralShared ? 1 : 0),
      TAXI_RIDE: taxiRides,
    };

    // Her gün 3 rastgele görev seç
    const dailyTasks = this.selectDailyTasks(today);
    const completedTasks = (userProgress?.completedTasks as string[]) || [];

    const tasks: DailyTask[] = dailyTasks.map(template => {
      const current = metrics[template.type as keyof typeof metrics] || 0;
      const completed = completedTasks.includes(template.id) || current >= template.target;

      return {
        id: template.id,
        title: template.title,
        description: template.description,
        icon: template.icon,
        reward: template.reward,
        rewardType: template.rewardType,
        target: template.target,
        current: Math.min(current, template.target),
        completed,
        expiresAt: tomorrow,
      };
    });

    // Toplam kazanılan puanlar
    const totalPointsEarned = tasks
      .filter(t => t.completed && t.rewardType === 'points')
      .reduce((sum, t) => sum + t.reward, 0);

    // Gece yarısına kalan süre
    const refreshesIn = Math.floor((tomorrow.getTime() - Date.now()) / 1000);

    return {
      tasks,
      streak,
      totalPointsEarned,
      refreshesIn,
    };
  }

  /**
   * Görev tamamlandığında ödül ver
   */
  async completeTask(userId: string, taskId: string): Promise<{ success: boolean; reward?: number; message: string }> {
    const today = this.getToday();
    const progressId = `${userId}_${today.toISOString().split('T')[0]}`;

    // Mevcut ilerleme
    let progress = await this.prisma.dailyTaskProgress.findUnique({
      where: { id: progressId },
    });

    if (!progress) {
      progress = await this.prisma.dailyTaskProgress.create({
        data: {
          id: progressId,
          userId,
          date: today,
          completedTasks: [],
        },
      });
    }

    const completedTasks = (progress.completedTasks as string[]) || [];
    if (completedTasks.includes(taskId)) {
      return { success: false, message: 'Bu görev zaten tamamlandı' };
    }

    // Görevi bul
    const task = TASK_TEMPLATES.find(t => t.id === taskId);
    if (!task) {
      return { success: false, message: 'Görev bulunamadı' };
    }

    // Ödülü ver
    await this.prisma.$transaction([
      // İlerlemeyi güncelle
      this.prisma.dailyTaskProgress.update({
        where: { id: progressId },
        data: {
          completedTasks: [...completedTasks, taskId],
        },
      }),
      // Puan ver
      ...(task.rewardType === 'points' ? [
        this.prisma.user.update({
          where: { id: userId },
          data: { points: { increment: task.reward } },
        }),
      ] : []),
    ]);

    // Bildirim gönder
    await this.notificationsService.sendPush({
      userId,
      title: `${task.icon} Görev Tamamlandı!`,
      body: `"${task.title}" görevi için ${task.reward} ${task.rewardType === 'points' ? 'puan' : task.rewardType === 'discount' ? '₺ indirim' : 'ücretsiz teslimat'} kazandınız!`,
      data: { type: 'DAILY_TASK_COMPLETE', taskId },
    });

    this.logger.log(`Daily task completed: ${userId} -> ${taskId}`);

    return {
      success: true,
      reward: task.reward,
      message: `${task.reward} ${task.rewardType === 'points' ? 'puan' : '₺'} kazandınız!`,
    };
  }

  /**
   * Referans paylaşıldığını işaretle
   */
  async markReferralShared(userId: string): Promise<void> {
    const today = this.getToday();
    const progressId = `${userId}_${today.toISOString().split('T')[0]}`;

    await this.prisma.dailyTaskProgress.upsert({
      where: { id: progressId },
      update: { referralShared: true },
      create: {
        id: progressId,
        userId,
        date: today,
        completedTasks: [],
        referralShared: true,
      },
    });
  }

  private getToday(): Date {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    return today;
  }

  private selectDailyTasks(date: Date): typeof TASK_TEMPLATES {
    // Tarihe göre deterministik seçim (her gün aynı görevler)
    const seed = date.getDate() + date.getMonth() * 31;
    const shuffled = [...TASK_TEMPLATES].sort((a, b) => {
      const hashA = this.simpleHash(a.id + seed);
      const hashB = this.simpleHash(b.id + seed);
      return hashA - hashB;
    });
    return shuffled.slice(0, 3);
  }

  private simpleHash(str: string): number {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      hash = ((hash << 5) - hash) + str.charCodeAt(i);
      hash = hash & hash;
    }
    return Math.abs(hash);
  }

  private async calculateStreak(userId: string): Promise<number> {
    const today = this.getToday();
    let streak = 0;
    const checkDate = new Date(today);

    for (let i = 0; i < 30; i++) {
      const progressId = `${userId}_${checkDate.toISOString().split('T')[0]}`;
      const progress = await this.prisma.dailyTaskProgress.findUnique({
        where: { id: progressId },
      });

      if (!progress || !(progress.completedTasks as string[])?.length) {
        break;
      }

      streak++;
      checkDate.setDate(checkDate.getDate() - 1);
    }

    return streak;
  }
}
