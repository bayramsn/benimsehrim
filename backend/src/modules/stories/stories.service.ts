import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';

export interface Story {
  id: string;
  storeId: string;
  storeName: string;
  storeLogo?: string;
  mediaUrl: string;
  mediaType: 'image' | 'video';
  caption?: string;
  linkType?: 'product' | 'campaign' | 'store';
  linkId?: string;
  viewCount: number;
  expiresAt: Date;
  createdAt: Date;
  viewed: boolean;
}

export interface StoryGroup {
  storeId: string;
  storeName: string;
  storeLogo?: string;
  stories: Story[];
  hasUnviewed: boolean;
}

@Injectable()
export class StoriesService {
  private readonly logger = new Logger(StoriesService.name);

  // Stories expire after 24 hours
  private readonly STORY_DURATION_HOURS = 24;

  constructor(private prisma: PrismaService) {}

  /**
   * Aktif hikayeleri getir
   */
  async getActiveStories(userId?: string): Promise<StoryGroup[]> {
    const now = new Date();

    const stories = await this.prisma.story.findMany({
      where: {
        expiresAt: { gt: now },
        isActive: true,
      },
      include: {
        store: { select: { id: true, name: true } },
        views: userId ? { where: { userId }, select: { id: true } } : false,
      },
      orderBy: { createdAt: 'desc' },
    });

    // Group by store
    const groups = new Map<string, StoryGroup>();

    for (const story of stories) {
      const viewed = userId ? story.views && story.views.length > 0 : false;

      if (!groups.has(story.storeId)) {
        groups.set(story.storeId, {
          storeId: story.storeId,
          storeName: story.store.name,
          stories: [],
          hasUnviewed: false,
        });
      }

      const group = groups.get(story.storeId)!;
      group.stories.push({
        id: story.id,
        storeId: story.storeId,
        storeName: story.store.name,
        mediaUrl: story.mediaUrl,
        mediaType: story.mediaType as 'image' | 'video',
        caption: story.caption || undefined,
        linkType: story.linkType as Story['linkType'],
        linkId: story.linkId || undefined,
        viewCount: story.viewCount,
        expiresAt: story.expiresAt,
        createdAt: story.createdAt,
        viewed: viewed as boolean,
      });

      if (!viewed) {
        group.hasUnviewed = true;
      }
    }

    // Sort: unviewed first
    return Array.from(groups.values()).sort((a, b) => {
      if (a.hasUnviewed && !b.hasUnviewed) return -1;
      if (!a.hasUnviewed && b.hasUnviewed) return 1;
      return 0;
    });
  }

  /**
   * Mağaza için hikaye oluştur
   */
  async createStory(
    storeId: string,
    data: {
      mediaUrl: string;
      mediaType: 'image' | 'video';
      caption?: string;
      linkType?: 'product' | 'campaign' | 'store';
      linkId?: string;
    }
  ): Promise<Story> {
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + this.STORY_DURATION_HOURS);

    const story = await this.prisma.story.create({
      data: {
        storeId,
        mediaUrl: data.mediaUrl,
        mediaType: data.mediaType,
        caption: data.caption,
        linkType: data.linkType,
        linkId: data.linkId,
        expiresAt,
        isActive: true,
      },
      include: { store: { select: { name: true } } },
    });

    this.logger.log(`Story created: ${storeId}`);

    return {
      id: story.id,
      storeId: story.storeId,
      storeName: story.store.name,
      mediaUrl: story.mediaUrl,
      mediaType: story.mediaType as 'image' | 'video',
      caption: story.caption || undefined,
      linkType: story.linkType as Story['linkType'],
      linkId: story.linkId || undefined,
      viewCount: 0,
      expiresAt: story.expiresAt,
      createdAt: story.createdAt,
      viewed: false,
    };
  }

  /**
   * Hikayeyi görüntüle
   */
  async viewStory(storyId: string, userId: string): Promise<void> {
    // Check if already viewed
    const existing = await this.prisma.storyView.findFirst({
      where: { storyId, userId },
    });

    if (existing) return;

    await this.prisma.$transaction([
      // Create view record
      this.prisma.storyView.create({
        data: { storyId, userId },
      }),
      // Increment view count
      this.prisma.story.update({
        where: { id: storyId },
        data: { viewCount: { increment: 1 } },
      }),
    ]);
  }

  /**
   * Mağazanın hikayelerini getir
   */
  async getStoreStories(storeId: string): Promise<Story[]> {
    const stories = await this.prisma.story.findMany({
      where: {
        storeId,
        expiresAt: { gt: new Date() },
        isActive: true,
      },
      include: { store: { select: { name: true } } },
      orderBy: { createdAt: 'desc' },
    });

    return stories.map(story => ({
      id: story.id,
      storeId: story.storeId,
      storeName: story.store.name,
      mediaUrl: story.mediaUrl,
      mediaType: story.mediaType as 'image' | 'video',
      caption: story.caption || undefined,
      linkType: story.linkType as Story['linkType'],
      linkId: story.linkId || undefined,
      viewCount: story.viewCount,
      expiresAt: story.expiresAt,
      createdAt: story.createdAt,
      viewed: false,
    }));
  }

  /**
   * Hikaye sil
   */
  async deleteStory(storyId: string, storeId: string): Promise<boolean> {
    const result = await this.prisma.story.updateMany({
      where: { id: storyId, storeId },
      data: { isActive: false },
    });

    return result.count > 0;
  }

  /**
   * Hikaye istatistikleri
   */
  async getStoryStats(storyId: string): Promise<{
    viewCount: number;
    uniqueViews: number;
    clickCount: number;
  }> {
    const [story, uniqueViews] = await Promise.all([
      this.prisma.story.findUnique({
        where: { id: storyId },
        select: { viewCount: true, clickCount: true },
      }),
      this.prisma.storyView.count({
        where: { storyId },
      }),
    ]);

    return {
      viewCount: story?.viewCount || 0,
      uniqueViews,
      clickCount: story?.clickCount || 0,
    };
  }
}
