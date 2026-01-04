import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import * as crypto from 'crypto';

export interface WalletBalance {
  balance: number;
  pendingBalance: number;
  totalEarned: number;
  totalSpent: number;
}

export interface Transaction {
  id: string;
  type: 'DEPOSIT' | 'WITHDRAWAL' | 'PAYMENT' | 'REFUND' | 'CASHBACK' | 'POINTS_CONVERSION';
  amount: number;
  description: string;
  status: 'PENDING' | 'COMPLETED' | 'FAILED';
  createdAt: Date;
}

@Injectable()
export class WalletService {
  private readonly logger = new Logger(WalletService.name);

  // Points to TL conversion rate: 100 puan = 1 TL
  private readonly POINTS_RATE = 100;

  constructor(private prisma: PrismaService) {}

  /**
   * Cüzdan bakiyesini getir
   */
  async getBalance(userId: string): Promise<WalletBalance> {
    const wallet = await this.getOrCreateWallet(userId);

    const [totalEarned, totalSpent] = await Promise.all([
      this.prisma.walletTransaction.aggregate({
        where: {
          walletId: wallet.id,
          type: { in: ['DEPOSIT', 'REFUND', 'CASHBACK', 'POINTS_CONVERSION'] },
          status: 'COMPLETED',
        },
        _sum: { amount: true },
      }),
      this.prisma.walletTransaction.aggregate({
        where: {
          walletId: wallet.id,
          type: { in: ['PAYMENT', 'WITHDRAWAL'] },
          status: 'COMPLETED',
        },
        _sum: { amount: true },
      }),
    ]);

    return {
      balance: wallet.balance,
      pendingBalance: wallet.pendingBalance || 0,
      totalEarned: totalEarned._sum.amount || 0,
      totalSpent: Math.abs(totalSpent._sum.amount || 0),
    };
  }

  /**
   * Bakiye yükle
   */
  async deposit(
    userId: string,
    amount: number,
    paymentMethod: string
  ): Promise<{ success: boolean; newBalance: number; message: string }> {
    if (amount < 10) {
      throw new BadRequestException('Minimum yükleme tutarı 10₺');
    }

    if (amount > 5000) {
      throw new BadRequestException('Maksimum yükleme tutarı 5000₺');
    }

    const wallet = await this.getOrCreateWallet(userId);

    // Create transaction
    const transaction = await this.prisma.walletTransaction.create({
      data: {
        walletId: wallet.id,
        type: 'DEPOSIT',
        amount,
        description: `Bakiye yükleme (${paymentMethod})`,
        status: 'COMPLETED',
        referenceId: this.generateTransactionId(),
      },
    });

    // Update balance
    const updated = await this.prisma.wallet.update({
      where: { id: wallet.id },
      data: { balance: { increment: amount } },
    });

    this.logger.log(`Wallet deposit: ${userId}, ${amount}₺`);

    return {
      success: true,
      newBalance: updated.balance,
      message: `${amount}₺ başarıyla yüklendi!`,
    };
  }

  /**
   * Cüzdandan ödeme yap
   */
  async pay(
    userId: string,
    amount: number,
    orderId: string,
    description: string
  ): Promise<{ success: boolean; newBalance: number; message: string }> {
    const wallet = await this.getOrCreateWallet(userId);

    if (wallet.balance < amount) {
      throw new BadRequestException('Yetersiz bakiye');
    }

    // Deduct from wallet
    const updated = await this.prisma.wallet.update({
      where: { id: wallet.id },
      data: { balance: { decrement: amount } },
    });

    // Record transaction
    await this.prisma.walletTransaction.create({
      data: {
        walletId: wallet.id,
        type: 'PAYMENT',
        amount: -amount,
        description,
        status: 'COMPLETED',
        referenceId: orderId,
      },
    });

    this.logger.log(`Wallet payment: ${userId}, ${amount}₺, order: ${orderId}`);

    return {
      success: true,
      newBalance: updated.balance,
      message: `${amount}₺ ödeme başarılı!`,
    };
  }

  /**
   * İade yap
   */
  async refund(
    userId: string,
    amount: number,
    orderId: string,
    reason: string
  ): Promise<{ success: boolean; newBalance: number }> {
    const wallet = await this.getOrCreateWallet(userId);

    // Add refund
    const updated = await this.prisma.wallet.update({
      where: { id: wallet.id },
      data: { balance: { increment: amount } },
    });

    await this.prisma.walletTransaction.create({
      data: {
        walletId: wallet.id,
        type: 'REFUND',
        amount,
        description: `İade: ${reason}`,
        status: 'COMPLETED',
        referenceId: orderId,
      },
    });

    this.logger.log(`Wallet refund: ${userId}, ${amount}₺`);

    return {
      success: true,
      newBalance: updated.balance,
    };
  }

  /**
   * Cashback ekle
   */
  async addCashback(
    userId: string,
    orderAmount: number,
    percentage: number
  ): Promise<number> {
    const cashback = Math.floor(orderAmount * (percentage / 100) * 100) / 100;
    if (cashback < 0.01) return 0;

    const wallet = await this.getOrCreateWallet(userId);

    await this.prisma.$transaction([
      this.prisma.wallet.update({
        where: { id: wallet.id },
        data: { balance: { increment: cashback } },
      }),
      this.prisma.walletTransaction.create({
        data: {
          walletId: wallet.id,
          type: 'CASHBACK',
          amount: cashback,
          description: `%${percentage} Cashback`,
          status: 'COMPLETED',
          referenceId: this.generateTransactionId(),
        },
      }),
    ]);

    return cashback;
  }

  /**
   * Puanları paraya çevir
   */
  async convertPoints(userId: string, points: number): Promise<{ success: boolean; amount: number; message: string }> {
    if (points < 100) {
      throw new BadRequestException('Minimum 100 puan gerekli');
    }

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { points: true },
    });

    if (!user || user.points < points) {
      throw new BadRequestException('Yetersiz puan');
    }

    const amount = points / this.POINTS_RATE;
    const wallet = await this.getOrCreateWallet(userId);

    await this.prisma.$transaction([
      // Deduct points
      this.prisma.user.update({
        where: { id: userId },
        data: { points: { decrement: points } },
      }),
      // Add to wallet
      this.prisma.wallet.update({
        where: { id: wallet.id },
        data: { balance: { increment: amount } },
      }),
      // Record transaction
      this.prisma.walletTransaction.create({
        data: {
          walletId: wallet.id,
          type: 'POINTS_CONVERSION',
          amount,
          description: `${points} puan -> ${amount}₺`,
          status: 'COMPLETED',
          referenceId: this.generateTransactionId(),
        },
      }),
    ]);

    return {
      success: true,
      amount,
      message: `${points} puan ${amount}₺'ye çevrildi!`,
    };
  }

  /**
   * İşlem geçmişi
   */
  async getTransactions(userId: string, limit = 20): Promise<Transaction[]> {
    const wallet = await this.getOrCreateWallet(userId);

    const transactions = await this.prisma.walletTransaction.findMany({
      where: { walletId: wallet.id },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });

    return transactions.map(t => ({
      id: t.id,
      type: t.type as Transaction['type'],
      amount: t.amount,
      description: t.description,
      status: t.status as Transaction['status'],
      createdAt: t.createdAt,
    }));
  }

  private async getOrCreateWallet(userId: string) {
    let wallet = await this.prisma.wallet.findUnique({
      where: { userId },
    });

    if (!wallet) {
      wallet = await this.prisma.wallet.create({
        data: {
          userId,
          balance: 0,
          pendingBalance: 0,
        },
      });
    }

    return wallet;
  }

  private generateTransactionId(): string {
    return `TXN${Date.now()}${crypto.randomBytes(3).toString('hex').toUpperCase()}`;
  }
}
