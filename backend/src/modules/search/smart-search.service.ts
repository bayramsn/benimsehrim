import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';

export interface SearchResult {
  type: 'store' | 'product' | 'category';
  id: string;
  name: string;
  description?: string;
  image?: string;
  price?: number;
  storeName?: string;
  storeId?: string;
  rating?: number;
  score: number; // Relevance score
}

export interface SearchSuggestion {
  text: string;
  type: 'recent' | 'popular' | 'correction';
}

@Injectable()
export class SmartSearchService {
  private readonly logger = new Logger(SmartSearchService.name);

  // Türkçe karakter dönüşümleri
  private readonly turkishMap: Record<string, string> = {
    'ç': 'c', 'ğ': 'g', 'ı': 'i', 'ö': 'o', 'ş': 's', 'ü': 'u',
    'Ç': 'C', 'Ğ': 'G', 'İ': 'I', 'Ö': 'O', 'Ş': 'S', 'Ü': 'U',
  };

  // Popüler aramalar cache
  private popularSearches: string[] = [];
  private lastPopularUpdate = 0;

  constructor(private prisma: PrismaService) {}

  /**
   * Akıllı Arama - Yazım hatası düzeltme, öneriler dahil
   */
  async search(
    query: string,
    options: {
      cityId?: string;
      limit?: number;
      includeProducts?: boolean;
      includeStores?: boolean;
    } = {}
  ): Promise<{ results: SearchResult[]; suggestions: string[]; didYouMean?: string }> {
    const { cityId, limit = 20, includeProducts = true, includeStores = true } = options;

    // Normalize query
    const normalizedQuery = this.normalizeText(query);
    const words = normalizedQuery.split(' ').filter(w => w.length > 1);

    if (words.length === 0) {
      return { results: [], suggestions: await this.getPopularSearches() };
    }

    const results: SearchResult[] = [];

    // Search stores
    if (includeStores) {
      const stores = await this.searchStores(words, cityId, limit);
      results.push(...stores);
    }

    // Search products
    if (includeProducts) {
      const products = await this.searchProducts(words, cityId, limit);
      results.push(...products);
    }

    // Sort by relevance score
    results.sort((a, b) => b.score - a.score);

    // Check for spelling corrections
    const didYouMean = await this.getSuggestion(query);

    // Log search for analytics
    await this.logSearch(query, results.length);

    return {
      results: results.slice(0, limit),
      suggestions: await this.getPopularSearches(),
      didYouMean: didYouMean !== normalizedQuery ? didYouMean : undefined,
    };
  }

  /**
   * Arama önerileri (autocomplete)
   */
  async getSuggestions(query: string, limit = 5): Promise<SearchSuggestion[]> {
    const normalized = this.normalizeText(query);
    const suggestions: SearchSuggestion[] = [];

    // Popular searches matching query
    const popular = await this.getPopularSearches();
    popular
      .filter(s => s.toLowerCase().includes(normalized.toLowerCase()))
      .slice(0, 3)
      .forEach(text => suggestions.push({ text, type: 'popular' }));

    // Product/Store names matching
    const [products, stores] = await Promise.all([
      this.prisma.product.findMany({
        where: { name: { contains: normalized, mode: 'insensitive' } },
        select: { name: true },
        take: 3,
      }),
      this.prisma.store.findMany({
        where: { name: { contains: normalized, mode: 'insensitive' } },
        select: { name: true },
        take: 2,
      }),
    ]);

    products.forEach(p => suggestions.push({ text: p.name, type: 'popular' }));
    stores.forEach(s => suggestions.push({ text: s.name, type: 'popular' }));

    return suggestions.slice(0, limit);
  }

  private async searchStores(words: string[], cityId?: string, limit = 10): Promise<SearchResult[]> {
    const where: any = {
      isApproved: true,
      OR: words.map(word => ({
        OR: [
          { name: { contains: word, mode: 'insensitive' } },
          { description: { contains: word, mode: 'insensitive' } },
        ],
      })),
    };

    if (cityId) {
      where.cityId = cityId;
    }

    const stores = await this.prisma.store.findMany({
      where,
      select: {
        id: true,
        name: true,
        description: true,
        rating: true,
      },
      take: limit,
    });

    return stores.map(store => ({
      type: 'store' as const,
      id: store.id,
      name: store.name,
      description: store.description || undefined,
      rating: store.rating || undefined,
      score: this.calculateScore(store.name, words, store.rating || 0),
    }));
  }

  private async searchProducts(words: string[], cityId?: string, limit = 10): Promise<SearchResult[]> {
    const where: any = {
      OR: words.map(word => ({
        OR: [
          { name: { contains: word, mode: 'insensitive' } },
          { description: { contains: word, mode: 'insensitive' } },
        ],
      })),
    };

    if (cityId) {
      where.store = { cityId };
    }

    const products = await this.prisma.product.findMany({
      where,
      select: {
        id: true,
        name: true,
        description: true,
        price: true,
        store: { select: { id: true, name: true } },
      },
      take: limit,
    });

    return products.map(product => ({
      type: 'product' as const,
      id: product.id,
      name: product.name,
      description: product.description || undefined,
      price: product.price,
      storeId: product.store.id,
      storeName: product.store.name,
      score: this.calculateScore(product.name, words, 0) + 5, // Products get slight boost
    }));
  }

  private calculateScore(text: string, words: string[], rating: number): number {
    const normalized = this.normalizeText(text);
    let score = rating * 2;

    for (const word of words) {
      if (normalized.includes(word)) {
        score += 10;
        // Exact match bonus
        if (normalized.startsWith(word)) {
          score += 5;
        }
      }
    }

    return score;
  }

  private async getSuggestion(query: string): Promise<string> {
    // Simple spelling correction using common misspellings
    const corrections: Record<string, string> = {
      'kasab': 'kasap',
      'manaw': 'manav',
      'fırın': 'fırın',
      'döner': 'döner',
      'pizza': 'pizza',
      'burger': 'burger',
      'köfte': 'köfte',
    };

    const normalized = this.normalizeText(query);
    
    for (const [wrong, correct] of Object.entries(corrections)) {
      if (normalized.includes(wrong)) {
        return normalized.replace(wrong, correct);
      }
    }

    return normalized;
  }

  private async getPopularSearches(): Promise<string[]> {
    // Cache for 1 hour
    if (Date.now() - this.lastPopularUpdate < 3600000 && this.popularSearches.length > 0) {
      return this.popularSearches;
    }

    const searches = await this.prisma.searchLog.groupBy({
      by: ['query'],
      _count: { query: true },
      orderBy: { _count: { query: 'desc' } },
      take: 10,
    });

    this.popularSearches = searches.map(s => s.query);
    this.lastPopularUpdate = Date.now();

    return this.popularSearches.length > 0 
      ? this.popularSearches 
      : ['Kasap', 'Fırın', 'Manav', 'Döner', 'Pizza'];
  }

  private async logSearch(query: string, resultCount: number): Promise<void> {
    try {
      await this.prisma.searchLog.create({
        data: {
          query: query.toLowerCase().trim(),
          resultCount,
        },
      });
    } catch (e) {
      // Ignore logging errors
    }
  }

  private normalizeText(text: string): string {
    let normalized = text.toLowerCase().trim();
    
    for (const [turkish, ascii] of Object.entries(this.turkishMap)) {
      normalized = normalized.replace(new RegExp(turkish, 'g'), ascii);
    }

    return normalized;
  }
}
