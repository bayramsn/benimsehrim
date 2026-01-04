import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';

export interface ReviewWithDetails {
  id: string;
  userId: string;
  userName: string;
  rating: number;
  comment: string;
  createdAt: Date;
  isApproved: boolean;
}

export interface ReviewStats {
  average: number;
  total: number;
  distribution: { rating: number; count: number; percentage: number }[];
}

@Injectable()
export class ReviewPhotosService {
  private readonly logger = new Logger(ReviewPhotosService.name);

  constructor(private prisma: PrismaService) {}

  /**
   * Yorum oluştur
   */
  async createReview(
    userId: string,
    data: {
      targetType: 'STORE' | 'DRIVER' | 'COURIER';
      targetId: string;
      orderId?: string;
      rideId?: string;
      rating: number;
      comment: string;
    }
  ): Promise<ReviewWithDetails> {
    // Check if review already exists for this order
    if (data.orderId) {
      const existing = await this.prisma.review.findFirst({
        where: { userId, orderId: data.orderId },
      });

      if (existing) {
        throw new Error('Bu sipariş için zaten yorum yaptınız');
      }
    }

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { name: true },
    });

    // Create review
    const review = await this.prisma.review.create({
      data: {
        userId,
        targetType: data.targetType,
        targetId: data.targetId,
        orderId: data.orderId,
        rideId: data.rideId,
        rating: data.rating,
        comment: data.comment,
        isApproved: true, // Auto-approve for now
      },
    });

    // Update target rating
    if (data.targetType === 'STORE') {
      await this.updateStoreRating(data.targetId);
    }

    // Award points for review
    await this.prisma.user.update({
      where: { id: userId },
      data: { points: { increment: 30 } },
    });

    this.logger.log(`Review created: ${userId} -> ${data.targetType}:${data.targetId}, ${data.rating} stars`);

    return {
      id: review.id,
      userId,
      userName: user?.name || 'Kullanıcı',
      rating: review.rating,
      comment: review.comment || '',
      createdAt: review.createdAt,
      isApproved: review.isApproved,
    };
  }

  /**
   * Mağaza yorumlarını getir
   */
  async getStoreReviews(
    storeId: string,
    options: {
      minRating?: number;
      limit?: number;
      offset?: number;
    } = {}
  ): Promise<{ reviews: ReviewWithDetails[]; stats: ReviewStats }> {
    const { minRating, limit = 10, offset = 0 } = options;

    const where: any = { 
      targetType: 'STORE',
      targetId: storeId,
      isApproved: true,
    };
    if (minRating) where.rating = { gte: minRating };

    // Get reviews
    const reviews = await this.prisma.review.findMany({
      where,
      include: { user: { select: { name: true } } },
      orderBy: { createdAt: 'desc' },
      skip: offset,
      take: limit,
    });

    // Calculate stats
    const stats = await this.getStoreReviewStats(storeId);

    return {
      reviews: reviews.map(r => ({
        id: r.id,
        userId: r.userId,
        userName: r.user?.name || 'Kullanıcı',
        rating: r.rating,
        comment: r.comment || '',
        createdAt: r.createdAt,
        isApproved: r.isApproved,
      })),
      stats,
    };
  }

  /**
   * Kullanıcının yorumlarını getir
   */
  async getUserReviews(userId: string): Promise<ReviewWithDetails[]> {
    const reviews = await this.prisma.review.findMany({
      where: { userId },
      include: { user: { select: { name: true } } },
      orderBy: { createdAt: 'desc' },
    });

    return reviews.map(r => ({
      id: r.id,
      userId: r.userId,
      userName: r.user?.name || 'Kullanıcı',
      rating: r.rating,
      comment: r.comment || '',
      createdAt: r.createdAt,
      isApproved: r.isApproved,
    }));
  }

  /**
   * Yorumu güncelle
   */
  async updateReview(
    reviewId: string,
    userId: string,
    data: { rating?: number; comment?: string }
  ): Promise<boolean> {
    const result = await this.prisma.review.updateMany({
      where: { id: reviewId, userId },
      data: {
        rating: data.rating,
        comment: data.comment,
        updatedAt: new Date(),
      },
    });

    return result.count > 0;
  }

  /**
   * Yorumu sil
   */
  async deleteReview(reviewId: string, userId: string): Promise<boolean> {
    const review = await this.prisma.review.findFirst({
      where: { id: reviewId, userId },
    });

    if (!review) return false;

    await this.prisma.review.delete({
      where: { id: reviewId },
    });

    // Update store rating
    if (review.targetType === 'STORE') {
      await this.updateStoreRating(review.targetId);
    }

    return true;
  }

  private async getStoreReviewStats(storeId: string): Promise<ReviewStats> {
    const reviews = await this.prisma.review.findMany({
      where: { targetType: 'STORE', targetId: storeId, isApproved: true },
      select: { rating: true },
    });

    const total = reviews.length;
    if (total === 0) {
      return {
        average: 0,
        total: 0,
        distribution: [5, 4, 3, 2, 1].map(r => ({ rating: r, count: 0, percentage: 0 })),
      };
    }

    const sum = reviews.reduce((acc, r) => acc + r.rating, 0);
    const average = Math.round((sum / total) * 10) / 10;

    const distribution = [5, 4, 3, 2, 1].map(rating => {
      const count = reviews.filter(r => r.rating === rating).length;
      return {
        rating,
        count,
        percentage: Math.round((count / total) * 100),
      };
    });

    return { average, total, distribution };
  }

  private async updateStoreRating(storeId: string): Promise<void> {
    const stats = await this.prisma.review.aggregate({
      where: { targetType: 'STORE', targetId: storeId, isApproved: true },
      _avg: { rating: true },
      _count: true,
    });

    await this.prisma.store.update({
      where: { id: storeId },
      data: {
        rating: stats._avg?.rating || 0,
        reviewCount: stats._count || 0,
      },
    });
  }
}
