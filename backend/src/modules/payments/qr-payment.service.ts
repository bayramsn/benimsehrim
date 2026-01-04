import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import * as crypto from 'crypto';

export interface QRPaymentData {
  code: string;
  amount: number;
  storeId: string;
  storeName: string;
  expiresAt: Date;
  status: 'pending' | 'completed' | 'expired' | 'cancelled';
}

export interface QRPaymentResult {
  success: boolean;
  transactionId?: string;
  message: string;
  pointsEarned?: number;
}

@Injectable()
export class QRPaymentService {
  private readonly logger = new Logger(QRPaymentService.name);
  private readonly QR_EXPIRY_MINUTES = 15;

  constructor(private prisma: PrismaService) {}

  /**
   * Mağaza için QR ödeme kodu oluştur
   * Esnaf bu kodu ekranında gösterir, müşteri okutarak öder
   */
  async generateStoreQR(storeId: string, amount: number): Promise<{ code: string; expiresAt: Date; qrData: string }> {
    const store = await this.prisma.store.findUnique({
      where: { id: storeId },
      select: { id: true, name: true },
    });

    if (!store) {
      throw new Error('Mağaza bulunamadı');
    }

    // Benzersiz kod oluştur
    const code = this.generateCode();
    const expiresAt = new Date(Date.now() + this.QR_EXPIRY_MINUTES * 60 * 1000);

    // Veritabanına kaydet
    await this.prisma.qRPayment.create({
      data: {
        code,
        storeId,
        amount,
        expiresAt,
        status: 'PENDING',
      },
    });

    // QR içeriği (URL veya JSON)
    const qrData = JSON.stringify({
      type: 'benimsehrim_pay',
      code,
      amount,
      store: store.name,
      expires: expiresAt.toISOString(),
    });

    this.logger.log(`QR generated for store ${storeId}: ${code}, ${amount}₺`);

    return { code, expiresAt, qrData };
  }

  /**
   * Müşteri için QR ödeme kodu oluştur
   * Müşteri bu kodu gösterir, esnaf okutarak ödeme alır
   */
  async generateUserQR(userId: string, maxAmount?: number): Promise<{ code: string; expiresAt: Date; qrData: string }> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, name: true, points: true },
    });

    if (!user) {
      throw new Error('Kullanıcı bulunamadı');
    }

    const code = this.generateCode();
    const expiresAt = new Date(Date.now() + this.QR_EXPIRY_MINUTES * 60 * 1000);

    await this.prisma.qRPayment.create({
      data: {
        code,
        userId,
        maxAmount: maxAmount || 9999,
        expiresAt,
        status: 'PENDING',
        isUserQR: true,
      },
    });

    const qrData = JSON.stringify({
      type: 'benimsehrim_customer',
      code,
      maxAmount,
      expires: expiresAt.toISOString(),
    });

    return { code, expiresAt, qrData };
  }

  /**
   * QR kodu doğrula ve bilgileri getir
   */
  async validateQR(code: string): Promise<QRPaymentData | null> {
    const qr = await this.prisma.qRPayment.findUnique({
      where: { code },
      include: { store: { select: { id: true, name: true } } },
    });

    if (!qr) return null;

    // Süre kontrolü
    if (new Date() > qr.expiresAt) {
      await this.prisma.qRPayment.update({
        where: { code },
        data: { status: 'EXPIRED' },
      });
      return null;
    }

    if (qr.status !== 'PENDING') return null;

    return {
      code: qr.code,
      amount: qr.amount || 0,
      storeId: qr.storeId || '',
      storeName: qr.store?.name || '',
      expiresAt: qr.expiresAt,
      status: 'pending',
    };
  }

  /**
   * QR ile ödeme yap
   */
  async processPayment(
    code: string,
    userId: string,
    paymentMethod: 'cash' | 'card' | 'points' = 'cash',
  ): Promise<QRPaymentResult> {
    const qr = await this.prisma.qRPayment.findUnique({
      where: { code },
      include: { store: true },
    });

    if (!qr) {
      return { success: false, message: 'Geçersiz QR kod' };
    }

    if (qr.status !== 'PENDING') {
      return { success: false, message: 'Bu QR kod zaten kullanılmış' };
    }

    if (new Date() > qr.expiresAt) {
      return { success: false, message: 'QR kod süresi dolmuş' };
    }

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { points: true },
    });

    const amount = qr.amount || 0;

    // Puan ile ödeme kontrolü
    if (paymentMethod === 'points') {
      const requiredPoints = amount * 10; // 1₺ = 10 puan
      if ((user?.points || 0) < requiredPoints) {
        return { success: false, message: 'Yetersiz puan bakiyesi' };
      }
    }

    // Transaction ID oluştur
    const transactionId = `QR${Date.now()}${Math.random().toString(36).substr(2, 4).toUpperCase()}`;

    // İşlemi kaydet
    await this.prisma.$transaction([
      // QR durumunu güncelle
      this.prisma.qRPayment.update({
        where: { code },
        data: {
          status: 'COMPLETED',
          userId,
          transactionId,
          paymentMethod,
          completedAt: new Date(),
        },
      }),
      // Puan ile ödeme ise puanları düş
      ...(paymentMethod === 'points' ? [
        this.prisma.user.update({
          where: { id: userId },
          data: { points: { decrement: amount * 10 } },
        }),
      ] : []),
      // Ödeme için puan kazan
      ...(paymentMethod !== 'points' ? [
        this.prisma.user.update({
          where: { id: userId },
          data: { points: { increment: Math.floor(amount / 10) } },
        }),
      ] : []),
    ]);

    const pointsEarned = paymentMethod !== 'points' ? Math.floor(amount / 10) : 0;

    this.logger.log(`QR payment completed: ${code}, ${qr.amount}₺, user: ${userId}`);

    return {
      success: true,
      transactionId,
      message: `${amount}₺ ödeme başarılı!`,
      pointsEarned,
    };
  }

  /**
   * Mağaza QR ödemelerini listele
   */
  async getStorePayments(storeId: string, date?: Date) {
    const startOfDay = date || new Date();
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(startOfDay);
    endOfDay.setDate(endOfDay.getDate() + 1);

    const payments = await this.prisma.qRPayment.findMany({
      where: {
        storeId,
        status: 'COMPLETED',
        completedAt: { gte: startOfDay, lt: endOfDay },
      },
      include: { user: { select: { name: true } } },
      orderBy: { completedAt: 'desc' },
    });

    const total = payments.reduce((sum, p) => sum + (p.amount || 0), 0);

    return {
      payments: payments.map(p => ({
        transactionId: p.transactionId,
        amount: p.amount,
        customerName: p.user?.name || 'Müşteri',
        paymentMethod: p.paymentMethod,
        time: p.completedAt,
      })),
      total,
      count: payments.length,
    };
  }

  /**
   * QR kodunu iptal et
   */
  async cancelQR(code: string): Promise<boolean> {
    const result = await this.prisma.qRPayment.updateMany({
      where: { code, status: 'PENDING' },
      data: { status: 'CANCELLED' },
    });
    return result.count > 0;
  }

  private generateCode(): string {
    // 12 karakterlik benzersiz kod
    return crypto.randomBytes(6).toString('hex').toUpperCase();
  }
}
