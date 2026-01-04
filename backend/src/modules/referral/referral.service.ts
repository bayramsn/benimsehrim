import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import * as crypto from 'crypto';

export interface ReferralStats {
  referralCode: string;
  totalReferrals: number;
  successfulReferrals: number;
  pendingReferrals: number;
  totalEarnings: number;
  referrals: {
    id: string;
    name: string;
    status: 'pending' | 'completed';
    reward: number;
    createdAt: Date;
  }[];
}

@Injectable()
export class ReferralService {
  private readonly logger = new Logger(ReferralService.name);

  // Referral rewards
  private readonly REFERRER_REWARD = 20; // TL - Davet eden
  private readonly REFEREE_REWARD = 10;  // TL - Davet edilen

  constructor(
    private prisma: PrismaService,
    private notificationsService: NotificationsService,
  ) {}

  /**
   * Kullanıcı için referans kodu oluştur veya getir
   */
  async getReferralCode(userId: string): Promise<string> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { referralCode: true },
    });

    if (user?.referralCode) {
      return user.referralCode;
    }

    // Yeni kod oluştur
    const code = this.generateCode();
    await this.prisma.user.update({
      where: { id: userId },
      data: { referralCode: code },
    });

    return code;
  }

  /**
   * Referans kodu doğrula ve uygula
   */
  async applyReferralCode(userId: string, code: string): Promise<{ success: boolean; message: string }> {
    // Kodu kullanan kullanıcı
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, referredBy: true, name: true },
    });

    if (!user) {
      return { success: false, message: 'Kullanıcı bulunamadı' };
    }

    if (user.referredBy) {
      return { success: false, message: 'Zaten bir referans kodu kullandınız' };
    }

    // Kodu oluşturan kullanıcı
    const referrer = await this.prisma.user.findFirst({
      where: { referralCode: code.toUpperCase() },
    });

    if (!referrer) {
      return { success: false, message: 'Geçersiz referans kodu' };
    }

    if (referrer.id === userId) {
      return { success: false, message: 'Kendi kodunuzu kullanamazsınız' };
    }

    // Referansı kaydet
    await this.prisma.$transaction([
      // Kullanıcıyı güncelle
      this.prisma.user.update({
        where: { id: userId },
        data: { referredBy: referrer.id },
      }),
      // Referral kaydı oluştur
      this.prisma.referral.create({
        data: {
          referrerId: referrer.id,
          refereeId: userId,
          status: 'PENDING',
          referrerReward: this.REFERRER_REWARD,
          refereeReward: this.REFEREE_REWARD,
        },
      }),
    ]);

    // Davet edene bildirim gönder
    await this.notificationsService.sendPush({
      userId: referrer.id,
      title: '🎉 Yeni Davetli!',
      body: `${user.name || 'Bir kullanıcı'} kodunuzla kaydoldu! İlk siparişini verdiğinde ${this.REFERRER_REWARD}₺ kazanacaksınız.`,
      data: { type: 'REFERRAL_SIGNUP', refereeId: userId },
    });

    this.logger.log(`Referral applied: ${userId} -> ${referrer.id}`);

    return { 
      success: true, 
      message: `${this.REFEREE_REWARD}₺ hoş geldin bonusu hesabınıza eklendi!` 
    };
  }

  /**
   * İlk sipariş tamamlandığında referans ödüllerini ver
   */
  async completeReferral(userId: string): Promise<void> {
    const referral = await this.prisma.referral.findFirst({
      where: { refereeId: userId, status: 'PENDING' },
      include: { 
        referrer: { select: { id: true, name: true } },
        referee: { select: { name: true } },
      },
    });

    if (!referral) return;

    await this.prisma.$transaction([
      // Referral durumunu güncelle
      this.prisma.referral.update({
        where: { id: referral.id },
        data: { 
          status: 'COMPLETED',
          completedAt: new Date(),
        },
      }),
      // Davet edene puan ver
      this.prisma.user.update({
        where: { id: referral.referrerId },
        data: { points: { increment: referral.referrerReward * 10 } },
      }),
      // Davet edilene puan ver
      this.prisma.user.update({
        where: { id: referral.refereeId },
        data: { points: { increment: referral.refereeReward * 10 } },
      }),
    ]);

    // Bildirimleri gönder
    await this.notificationsService.sendPush({
      userId: referral.referrerId,
      title: '💰 Referans Ödülü!',
      body: `${referral.referee.name || 'Davetliniz'} ilk siparişini verdi! ${referral.referrerReward}₺ kazandınız!`,
      data: { type: 'REFERRAL_REWARD' },
    });

    this.logger.log(`Referral completed: ${referral.refereeId} -> ${referral.referrerId}`);
  }

  /**
   * Referans istatistikleri
   */
  async getReferralStats(userId: string): Promise<ReferralStats> {
    const [user, referrals] = await Promise.all([
      this.prisma.user.findUnique({
        where: { id: userId },
        select: { referralCode: true },
      }),
      this.prisma.referral.findMany({
        where: { referrerId: userId },
        include: { referee: { select: { name: true } } },
        orderBy: { createdAt: 'desc' },
      }),
    ]);

    const completed = referrals.filter(r => r.status === 'COMPLETED');
    const pending = referrals.filter(r => r.status === 'PENDING');

    return {
      referralCode: user?.referralCode || await this.getReferralCode(userId),
      totalReferrals: referrals.length,
      successfulReferrals: completed.length,
      pendingReferrals: pending.length,
      totalEarnings: completed.reduce((sum, r) => sum + r.referrerReward, 0),
      referrals: referrals.map(r => ({
        id: r.id,
        name: r.referee.name || 'Kullanıcı',
        status: r.status === 'COMPLETED' ? 'completed' : 'pending',
        reward: r.referrerReward,
        createdAt: r.createdAt,
      })),
    };
  }

  private generateCode(): string {
    // 8 karakterlik benzersiz kod
    return crypto.randomBytes(4).toString('hex').toUpperCase();
  }
}
