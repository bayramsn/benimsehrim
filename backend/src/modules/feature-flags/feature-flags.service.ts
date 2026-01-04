import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { RedisService } from '../../common/redis/redis.service';

@Injectable()
export class FeatureFlagService {
  private readonly CACHE_TTL = 300; // 5 dakika
  private readonly CACHE_PREFIX = 'feature:';

  constructor(
    private prisma: PrismaService,
    private redis: RedisService,
  ) {}

  /**
   * Check if a feature is enabled for a specific user
   */
  async isEnabled(userId: string, flagKey: string): Promise<boolean> {
    // 1. Cache kontrolü
    const cacheKey = `${this.CACHE_PREFIX}${userId}:${flagKey}`;
    const cached = await this.redis.get(cacheKey);
    if (cached !== null) {
      return cached === 'true';
    }

    // 2. Kullanıcıya özel flag kontrolü
    const userFeature = await this.prisma.userFeature.findUnique({
      where: {
        userId_flagKey: { userId, flagKey },
      },
    });

    if (userFeature) {
      // Süre kontrolü
      if (userFeature.expiresAt && userFeature.expiresAt < new Date()) {
        await this.redis.set(cacheKey, 'false', this.CACHE_TTL);
        return false;
      }
      await this.redis.set(cacheKey, String(userFeature.enabled), this.CACHE_TTL);
      return userFeature.enabled;
    }

    // 3. Global flag kontrolü
    const flag = await this.prisma.featureFlag.findUnique({
      where: { key: flagKey },
    });

    const result = flag?.defaultValue ?? false;
    await this.redis.set(cacheKey, String(result), this.CACHE_TTL);
    return result;
  }

  /**
   * Get all features for a user
   */
  async getUserFeatures(userId: string): Promise<Record<string, boolean>> {
    const allFlags = await this.prisma.featureFlag.findMany();
    const userFeatures = await this.prisma.userFeature.findMany({
      where: { userId },
    });

    const result: Record<string, boolean> = {};

    for (const flag of allFlags) {
      const userFeature = userFeatures.find((f) => f.flagKey === flag.key);
      
      if (userFeature) {
        // Süre kontrolü
        if (userFeature.expiresAt && userFeature.expiresAt < new Date()) {
          result[flag.key] = false;
        } else {
          result[flag.key] = userFeature.enabled;
        }
      } else {
        result[flag.key] = flag.defaultValue;
      }
    }

    return result;
  }

  /**
   * Enable a feature for a user
   */
  async enableFeature(
    userId: string,
    flagKey: string,
    expiresAt?: Date,
  ): Promise<void> {
    await this.prisma.userFeature.upsert({
      where: {
        userId_flagKey: { userId, flagKey },
      },
      create: {
        userId,
        flagKey,
        enabled: true,
        expiresAt,
      },
      update: {
        enabled: true,
        expiresAt,
      },
    });

    // Cache invalidate
    await this.redis.del(`${this.CACHE_PREFIX}${userId}:${flagKey}`);
  }

  /**
   * Disable a feature for a user
   */
  async disableFeature(userId: string, flagKey: string): Promise<void> {
    await this.prisma.userFeature.upsert({
      where: {
        userId_flagKey: { userId, flagKey },
      },
      create: {
        userId,
        flagKey,
        enabled: false,
      },
      update: {
        enabled: false,
      },
    });

    // Cache invalidate
    await this.redis.del(`${this.CACHE_PREFIX}${userId}:${flagKey}`);
  }

  /**
   * Check premium feature access
   */
  async checkPremiumAccess(userId: string, flagKey: string): Promise<{
    hasAccess: boolean;
    isPremium: boolean;
    message?: string;
  }> {
    const flag = await this.prisma.featureFlag.findUnique({
      where: { key: flagKey },
    });

    if (!flag) {
      return { hasAccess: false, isPremium: false, message: 'Feature not found' };
    }

    const hasAccess = await this.isEnabled(userId, flagKey);

    return {
      hasAccess,
      isPremium: flag.isPremium,
      message: !hasAccess && flag.isPremium
        ? 'Bu özellik premium pakette mevcut'
        : undefined,
    };
  }
}
