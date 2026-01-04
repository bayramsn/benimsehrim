import { Injectable, Logger, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { PremiumService } from '../premium/premium.service';

export interface ChatMessage {
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
}

export interface ChatResponse {
  message: string;
  suggestions?: string[];
  actions?: ChatAction[];
}

export interface ChatAction {
  type: 'navigate' | 'order' | 'call_support';
  label: string;
  data?: any;
}

// Intent patterns for simple NLU
const INTENT_PATTERNS = {
  ORDER_STATUS: [
    /sipari[şs]\s*(nerede|durumu|takip)/i,
    /sipari[şs]im\s*(ne\s*zaman|ne\s*durumda)/i,
  ],
  FIND_STORE: [
    /(kasap|fırın|manav|market|eczane|restoran)/i,
    /nerede\s*(kasap|fırın|manav)/i,
    /yakın(ım)?da(ki)?\s*(kasap|fırın)/i,
  ],
  SUPPORT: [
    /(yardım|destek|şikayet|problem|sorun)/i,
    /müşteri\s*hizmetleri/i,
  ],
  REFUND: [
    /(iade|iptal|geri\s*ödeme|para\s*iade)/i,
  ],
  GREETING: [
    /(merhaba|selam|hey|günaydın|iyi\s*akşamlar)/i,
  ],
  THANKS: [
    /(teşekkür|sağol|eyvallah)/i,
  ],
  RECOMMENDATION: [
    /(öneri|tavsiye|ne\s*yesem|ne\s*alsam)/i,
  ],
};

@Injectable()
export class ChatbotService {
  private readonly logger = new Logger(ChatbotService.name);

  constructor(
    private prisma: PrismaService,
    private premiumService: PremiumService,
  ) {}

  /**
   * Chatbot ile konuşma (sadece premium kullanıcılar)
   */
  async chat(userId: string, message: string): Promise<ChatResponse> {
    // Check premium access
    const hasChatbot = await this.premiumService.hasFeature(userId, 'chatbot_access');
    if (!hasChatbot) {
      throw new ForbiddenException(
        'AI Chatbot sadece ŞehrimPLUS üyelere özeldir. Hemen üye ol!'
      );
    }

    // Detect intent
    const intent = this.detectIntent(message);
    
    // Generate response based on intent
    return this.generateResponse(userId, message, intent);
  }

  private detectIntent(message: string): string {
    for (const [intent, patterns] of Object.entries(INTENT_PATTERNS)) {
      for (const pattern of patterns) {
        if (pattern.test(message)) {
          return intent;
        }
      }
    }
    return 'GENERAL';
  }

  private async generateResponse(
    userId: string,
    message: string,
    intent: string
  ): Promise<ChatResponse> {
    switch (intent) {
      case 'GREETING':
        return {
          message: 'Merhaba! 👋 Ben ŞehrimBot, size nasıl yardımcı olabilirim?',
          suggestions: [
            'Siparişim nerede?',
            'Yakınımdaki kasaplar',
            'Ne yesem bugün?',
          ],
        };

      case 'THANKS':
        return {
          message: 'Rica ederim! 😊 Başka bir konuda yardımcı olabilir miyim?',
        };

      case 'ORDER_STATUS':
        return this.handleOrderStatus(userId);

      case 'FIND_STORE':
        return this.handleFindStore(message);

      case 'SUPPORT':
        return {
          message: 'Destek ekibimize ulaşmak için yardımcı olayım. Sorununuzu kısaca açıklayabilir misiniz?',
          actions: [
            {
              type: 'call_support',
              label: 'Müşteri Hizmetlerini Ara',
              data: { phone: '08502221234' },
            },
          ],
        };

      case 'REFUND':
        return {
          message: 'İade ve iptal işlemleri için siparişinizi seçmeniz gerekiyor.',
          actions: [
            {
              type: 'navigate',
              label: 'Siparişlerime Git',
              data: { screen: 'orders' },
            },
          ],
        };

      case 'RECOMMENDATION':
        return this.handleRecommendation(userId);

      default:
        return {
          message: 'Anladım! Size yardımcı olmak istiyorum. Şu konularda yardımcı olabilirim:',
          suggestions: [
            '📦 Sipariş takibi',
            '🔍 Mağaza arama',
            '🍕 Yemek önerisi',
            '💬 Müşteri desteği',
          ],
        };
    }
  }

  private async handleOrderStatus(userId: string): Promise<ChatResponse> {
    const lastOrder = await this.prisma.order.findFirst({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      include: { store: { select: { name: true } } },
    });

    if (!lastOrder) {
      return {
        message: 'Henüz bir siparişiniz bulunmuyor. Hemen sipariş vermek ister misiniz?',
        actions: [
          { type: 'navigate', label: 'Mağazalara Git', data: { screen: 'stores' } },
        ],
      };
    }

    const statusMessages: Record<string, string> = {
      PENDING: '⏳ Siparişiniz onay bekliyor',
      ACCEPTED: '✅ Siparişiniz onaylandı, hazırlanıyor',
      PREPARING: '👨‍🍳 Siparişiniz hazırlanıyor',
      READY: '📦 Siparişiniz hazır, kurye bekliyor',
      ON_THE_WAY: '🚴 Kurye yolda! Yakında kapınızda',
      DELIVERED: '✅ Siparişiniz teslim edildi',
      CANCELLED: '❌ Sipariş iptal edildi',
    };

    return {
      message: `Son siparişiniz (${lastOrder.orderNo}) - ${lastOrder.store.name}\n\n${statusMessages[lastOrder.status] || lastOrder.status}`,
      actions: [
        {
          type: 'navigate',
          label: 'Siparişi Görüntüle',
          data: { screen: 'order_detail', orderId: lastOrder.id },
        },
      ],
    };
  }

  private handleFindStore(message: string): ChatResponse {
    // Extract store type from message
    const storeTypes: Record<string, string> = {
      kasap: 'KASAP',
      fırın: 'FIRIN',
      manav: 'MANAV',
      market: 'MARKET',
      eczane: 'ECZANE',
      restoran: 'RESTAURANT',
    };

    let category = 'RESTAURANT';
    for (const [keyword, cat] of Object.entries(storeTypes)) {
      if (message.toLowerCase().includes(keyword)) {
        category = cat;
        break;
      }
    }

    return {
      message: `Size yakın ${category.toLowerCase()} mağazalarını buluyorum...`,
      actions: [
        {
          type: 'navigate',
          label: 'Mağazaları Gör',
          data: { screen: 'stores', category },
        },
      ],
    };
  }

  private async handleRecommendation(userId: string): Promise<ChatResponse> {
    // Get time-based suggestion
    const hour = new Date().getHours();
    let suggestion: string;
    let emoji: string;

    if (hour < 11) {
      suggestion = 'Kahvaltı için taze simit ve poğaça nasıl olur?';
      emoji = '🥐';
    } else if (hour < 14) {
      suggestion = 'Öğle yemeği vakti! Bugün döner veya pide öneriyorum.';
      emoji = '🥙';
    } else if (hour < 17) {
      suggestion = 'Tatlı iyi gider! Künefe veya baklava?';
      emoji = '🍰';
    } else if (hour < 21) {
      suggestion = 'Akşam yemeği için pizza veya burger çok tercih ediliyor!';
      emoji = '🍕';
    } else {
      suggestion = 'Gece atıştırmalığı olarak hamburger veya döner dürum nasıl?';
      emoji = '🌯';
    }

    return {
      message: `${emoji} ${suggestion}`,
      suggestions: [
        'Yakınımdaki dönerciler',
        'En iyi pizzacılar',
        'Tatlı siparişi',
      ],
    };
  }

  /**
   * Konuşma geçmişini kaydet
   */
  async saveChatHistory(userId: string, messages: ChatMessage[]): Promise<void> {
    await this.prisma.chatHistory.create({
      data: {
        userId,
        messages: messages as any,
      },
    });
  }
}
