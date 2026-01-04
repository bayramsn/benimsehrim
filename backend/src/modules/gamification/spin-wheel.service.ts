import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';

export interface WheelPrize {
  id: string;
  name: string;
  type: 'points' | 'discount' | 'free_delivery' | 'cashback' | 'nothing';
  value: number;
  probability: number; // 0-100
  color: string;
  icon: string;
}

export interface SpinResult {
  prize: WheelPrize;
  message: string;
  nextSpinAvailable: Date;
}

// Çark ödülleri
const WHEEL_PRIZES: WheelPrize[] = [
  { id: 'points_50', name: '50 Puan', type: 'points', value: 50, probability: 25, color: '#4CAF50', icon: '⭐' },
  { id: 'points_100', name: '100 Puan', type: 'points', value: 100, probability: 15, color: '#8BC34A', icon: '🌟' },
  { id: 'points_200', name: '200 Puan', type: 'points', value: 200, probability: 5, color: '#CDDC39', icon: '💫' },
  { id: 'discount_5', name: '%5 İndirim', type: 'discount', value: 5, probability: 20, color: '#FF9800', icon: '🏷️' },
  { id: 'discount_10', name: '%10 İndirim', type: 'discount', value: 10, probability: 10, color: '#FF5722', icon: '🔥' },
  { id: 'free_delivery', name: 'Ücretsiz Teslimat', type: 'free_delivery', value: 1, probability: 10, color: '#2196F3', icon: '🚚' },
  { id: 'cashback_5', name: '%5 Cashback', type: 'cashback', value: 5, probability: 5, color: '#9C27B0', icon: '💰' },
  { id: 'nothing', name: 'Tekrar Dene', type: 'nothing', value: 0, probability: 10, color: '#9E9E9E', icon: '😢' },
];

@Injectable()
export class SpinWheelService {
  private readonly logger = new Logger(SpinWheelService.name);

  // Spin cooldown in hours
  private readonly SPIN_COOLDOWN_HOURS = 24;

  constructor(
    private prisma: PrismaService,
    private notificationsService: NotificationsService,
  ) {}

  /**
   * Çark durumunu kontrol et
   */
  async getWheelStatus(userId: string): Promise<{
    canSpin: boolean;
    nextSpinAt?: Date;
    prizes: WheelPrize[];
    totalSpins: number;
    totalWon: number;
  }> {
    const lastSpin = await this.prisma.spinHistory.findFirst({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });

    const canSpin = this.canUserSpin(lastSpin?.createdAt);
    const nextSpinAt = lastSpin
      ? new Date(lastSpin.createdAt.getTime() + this.SPIN_COOLDOWN_HOURS * 60 * 60 * 1000)
      : undefined;

    const stats = await this.prisma.spinHistory.aggregate({
      where: { userId },
      _count: true,
      _sum: { prizeValue: true },
    });

    return {
      canSpin,
      nextSpinAt: canSpin ? undefined : nextSpinAt,
      prizes: WHEEL_PRIZES,
      totalSpins: stats._count || 0,
      totalWon: stats._sum.prizeValue || 0,
    };
  }

  /**
   * Çarkı çevir
   */
  async spin(userId: string): Promise<SpinResult> {
    // Check cooldown
    const lastSpin = await this.prisma.spinHistory.findFirst({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });

    if (!this.canUserSpin(lastSpin?.createdAt)) {
      const nextSpinAt = new Date(
        lastSpin!.createdAt.getTime() + this.SPIN_COOLDOWN_HOURS * 60 * 60 * 1000
      );
      throw new BadRequestException(
        `Sonraki çevirme hakkınız: ${nextSpinAt.toLocaleString('tr-TR')}`
      );
    }

    // Select prize based on probability
    const prize = this.selectPrize();

    // Record spin
    await this.prisma.spinHistory.create({
      data: {
        userId,
        prizeId: prize.id,
        prizeName: prize.name,
        prizeType: prize.type,
        prizeValue: prize.value,
      },
    });

    // Apply prize
    await this.applyPrize(userId, prize);

    const nextSpinAvailable = new Date(
      Date.now() + this.SPIN_COOLDOWN_HOURS * 60 * 60 * 1000
    );

    this.logger.log(`Spin wheel: ${userId} won ${prize.name}`);

    return {
      prize,
      message: this.getPrizeMessage(prize),
      nextSpinAvailable,
    };
  }

  private canUserSpin(lastSpinAt?: Date): boolean {
    if (!lastSpinAt) return true;
    
    const cooldownMs = this.SPIN_COOLDOWN_HOURS * 60 * 60 * 1000;
    return Date.now() - lastSpinAt.getTime() > cooldownMs;
  }

  private selectPrize(): WheelPrize {
    const random = Math.random() * 100;
    let cumulative = 0;

    for (const prize of WHEEL_PRIZES) {
      cumulative += prize.probability;
      if (random <= cumulative) {
        return prize;
      }
    }

    return WHEEL_PRIZES[WHEEL_PRIZES.length - 1]; // Fallback
  }

  private async applyPrize(userId: string, prize: WheelPrize): Promise<void> {
    switch (prize.type) {
      case 'points':
        await this.prisma.user.update({
          where: { id: userId },
          data: { points: { increment: prize.value } },
        });
        break;

      case 'discount':
      case 'free_delivery':
      case 'cashback':
        // Create coupon for user
        const expiresAt = new Date();
        expiresAt.setDate(expiresAt.getDate() + 7); // 7 days validity

        await this.prisma.userCoupon.create({
          data: {
            userId,
            code: `SPIN${Date.now().toString(36).toUpperCase()}`,
            type: prize.type === 'free_delivery' ? 'FREE_DELIVERY' : 'PERCENTAGE',
            value: prize.value,
            expiresAt,
            source: 'SPIN_WHEEL',
          },
        });
        break;

      case 'nothing':
        // No prize
        break;
    }

    // Send notification
    if (prize.type !== 'nothing') {
      await this.notificationsService.sendPush({
        userId,
        title: `${prize.icon} Tebrikler!`,
        body: this.getPrizeMessage(prize),
        data: { type: 'SPIN_PRIZE', prizeId: prize.id },
      });
    }
  }

  private getPrizeMessage(prize: WheelPrize): string {
    switch (prize.type) {
      case 'points':
        return `${prize.value} puan kazandınız! Puanlarınız hesabınıza eklendi.`;
      case 'discount':
        return `%${prize.value} indirim kuponu kazandınız! 7 gün geçerli.`;
      case 'free_delivery':
        return `Ücretsiz teslimat hakkı kazandınız! Sonraki siparişinizde kullanın.`;
      case 'cashback':
        return `%${prize.value} cashback kazandınız! Sonraki siparişinizde geçerli.`;
      case 'nothing':
        return `Bu sefer şanssızdınız. Yarın tekrar deneyin!`;
      default:
        return 'Tebrikler!';
    }
  }

  /**
   * Çark istatistikleri (admin için)
   */
  async getStats(): Promise<{
    totalSpins: number;
    todaySpins: number;
    prizeDistribution: { prize: string; count: number }[];
  }> {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const [totalSpins, todaySpins, distribution] = await Promise.all([
      this.prisma.spinHistory.count(),
      this.prisma.spinHistory.count({
        where: { createdAt: { gte: today } },
      }),
      this.prisma.spinHistory.groupBy({
        by: ['prizeName'],
        _count: true,
      }),
    ]);

    return {
      totalSpins,
      todaySpins,
      prizeDistribution: distribution.map(d => ({
        prize: d.prizeName,
        count: d._count,
      })),
    };
  }
}
