import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';

export interface UserPreferences {
  theme: 'light' | 'dark' | 'system';
  language: string;
  notifications: {
    orders: boolean;
    promotions: boolean;
    chat: boolean;
  };
  defaultAddress?: string;
}

@Injectable()
export class PreferencesService {
  constructor(private prisma: PrismaService) {}

  private readonly defaultPreferences: UserPreferences = {
    theme: 'system',
    language: 'tr',
    notifications: {
      orders: true,
      promotions: true,
      chat: true,
    },
  };

  async getUserPreferences(userId: string): Promise<UserPreferences> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { preferences: true },
    });

    if (!user?.preferences || typeof user.preferences !== 'object') {
      return this.defaultPreferences;
    }

    const prefs = user.preferences as Record<string, unknown>;
    
    return {
      theme: (prefs.theme as UserPreferences['theme']) || this.defaultPreferences.theme,
      language: (prefs.language as string) || this.defaultPreferences.language,
      notifications: {
        orders: prefs.notifications && typeof prefs.notifications === 'object' 
          ? (prefs.notifications as any).orders ?? true 
          : true,
        promotions: prefs.notifications && typeof prefs.notifications === 'object'
          ? (prefs.notifications as any).promotions ?? true
          : true,
        chat: prefs.notifications && typeof prefs.notifications === 'object'
          ? (prefs.notifications as any).chat ?? true
          : true,
      },
      defaultAddress: prefs.defaultAddress as string | undefined,
    };
  }

  async updatePreferences(userId: string, preferences: Partial<UserPreferences>): Promise<UserPreferences> {
    const current = await this.getUserPreferences(userId);
    const updated = { 
      ...current, 
      ...preferences,
      notifications: {
        ...current.notifications,
        ...(preferences.notifications || {}),
      },
    };

    await this.prisma.user.update({
      where: { id: userId },
      data: { preferences: updated as any },
    });

    return updated;
  }

  async setTheme(userId: string, theme: 'light' | 'dark' | 'system'): Promise<void> {
    await this.updatePreferences(userId, { theme });
  }

  async setLanguage(userId: string, language: string): Promise<void> {
    await this.updatePreferences(userId, { language });
  }

  async setNotificationPreferences(
    userId: string, 
    notifications: Partial<UserPreferences['notifications']>
  ): Promise<void> {
    const current = await this.getUserPreferences(userId);
    await this.updatePreferences(userId, {
      notifications: { ...current.notifications, ...notifications },
    });
  }
}
