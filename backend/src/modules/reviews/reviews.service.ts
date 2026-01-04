import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';

@Injectable()
export class ReviewsService {
  constructor(private prisma: PrismaService) {}

  async create(userId: string, data: { targetType: string; targetId: string; orderId?: string; rideId?: string; rating: number; comment?: string }) {
    const review = await this.prisma.review.create({
      data: { userId, ...data, isApproved: false }, // Admin onayı gerekli
    });

    // Ortalama puanı güncelle
    await this.updateAverageRating(data.targetType, data.targetId);

    return review;
  }

  async findByTarget(targetType: string, targetId: string, onlyApproved = true) {
    return this.prisma.review.findMany({
      where: { targetType, targetId, ...(onlyApproved && { isApproved: true }) },
      include: { user: { select: { name: true } } },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getAverageRating(targetType: string, targetId: string) {
    const result = await this.prisma.review.aggregate({
      where: { targetType, targetId, isApproved: true },
      _avg: { rating: true },
      _count: true,
    });

    return { averageRating: result._avg.rating || 0, totalReviews: result._count };
  }

  private async updateAverageRating(targetType: string, targetId: string) {
    const { averageRating, totalReviews } = await this.getAverageRating(targetType, targetId);

    if (targetType === 'STORE') {
      await this.prisma.store.update({ where: { id: targetId }, data: { rating: averageRating, reviewCount: totalReviews } });
    } else if (targetType === 'DRIVER') {
      await this.prisma.driver.update({ where: { id: targetId }, data: { rating: averageRating, reviewCount: totalReviews } });
    } else if (targetType === 'COURIER') {
      await this.prisma.courier.update({ where: { id: targetId }, data: { rating: averageRating, reviewCount: totalReviews } });
    }
  }

  async approve(reviewId: string) {
    const review = await this.prisma.review.update({ where: { id: reviewId }, data: { isApproved: true } });
    await this.updateAverageRating(review.targetType, review.targetId);
    return review;
  }

  async reject(reviewId: string) {
    return this.prisma.review.delete({ where: { id: reviewId } });
  }
}
