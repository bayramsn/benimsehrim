import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import * as crypto from 'crypto';

export interface FavoriteList {
  id: string;
  name: string;
  description?: string;
  isPublic: boolean;
  shareCode?: string;
  itemCount: number;
  createdAt: Date;
}

export interface FavoriteItem {
  id: string;
  type: 'product' | 'store';
  itemId: string;
  name: string;
  image?: string;
  price?: number;
  storeName?: string;
  note?: string;
  addedAt: Date;
}

@Injectable()
export class FavoritesService {
  private readonly logger = new Logger(FavoritesService.name);

  constructor(private prisma: PrismaService) {}

  /**
   * Kullanıcının favori listelerini getir
   */
  async getUserLists(userId: string): Promise<FavoriteList[]> {
    const lists = await this.prisma.favoriteList.findMany({
      where: { userId },
      include: { _count: { select: { items: true } } },
      orderBy: { createdAt: 'desc' },
    });

    return lists.map(list => ({
      id: list.id,
      name: list.name,
      description: list.description || undefined,
      isPublic: list.isPublic,
      shareCode: list.shareCode || undefined,
      itemCount: list._count.items,
      createdAt: list.createdAt,
    }));
  }

  /**
   * Yeni liste oluştur
   */
  async createList(
    userId: string,
    name: string,
    description?: string,
    isPublic = false
  ): Promise<FavoriteList> {
    const shareCode = isPublic ? this.generateShareCode() : null;

    const list = await this.prisma.favoriteList.create({
      data: {
        userId,
        name,
        description,
        isPublic,
        shareCode,
      },
    });

    return {
      id: list.id,
      name: list.name,
      description: list.description || undefined,
      isPublic: list.isPublic,
      shareCode: list.shareCode || undefined,
      itemCount: 0,
      createdAt: list.createdAt,
    };
  }

  /**
   * Listeye öğe ekle
   */
  async addToList(
    listId: string,
    userId: string,
    type: 'product' | 'store',
    itemId: string,
    note?: string
  ): Promise<FavoriteItem> {
    // Verify list ownership
    const list = await this.prisma.favoriteList.findFirst({
      where: { id: listId, userId },
    });

    if (!list) {
      throw new Error('Liste bulunamadı');
    }

    // Check if already exists
    const existing = await this.prisma.favoriteItem.findFirst({
      where: { listId, itemType: type, itemId },
    });

    if (existing) {
      throw new Error('Bu öğe zaten listede');
    }

    // Get item details
    let itemDetails: { name: string; image?: string; price?: number; storeName?: string } = { name: '' };

    if (type === 'product') {
      const product = await this.prisma.product.findUnique({
        where: { id: itemId },
        include: { store: { select: { name: true } } },
      });
      if (product) {
        itemDetails = {
          name: product.name,
          price: product.price,
          storeName: product.store.name,
        };
      }
    } else {
      const store = await this.prisma.store.findUnique({
        where: { id: itemId },
      });
      if (store) {
        itemDetails = { name: store.name };
      }
    }

    const item = await this.prisma.favoriteItem.create({
      data: {
        listId,
        itemType: type,
        itemId,
        name: itemDetails.name,
        note,
      },
    });

    return {
      id: item.id,
      type: item.itemType as 'product' | 'store',
      itemId: item.itemId,
      name: item.name,
      image: itemDetails.image,
      price: itemDetails.price,
      storeName: itemDetails.storeName,
      note: item.note || undefined,
      addedAt: item.createdAt,
    };
  }

  /**
   * Listeden öğe çıkar
   */
  async removeFromList(listId: string, itemId: string, userId: string): Promise<boolean> {
    const result = await this.prisma.favoriteItem.deleteMany({
      where: {
        id: itemId,
        list: { id: listId, userId },
      },
    });

    return result.count > 0;
  }

  /**
   * Liste içeriğini getir
   */
  async getListItems(listId: string, userId?: string): Promise<FavoriteItem[]> {
    const list = await this.prisma.favoriteList.findFirst({
      where: {
        id: listId,
        OR: [
          { userId: userId || '' },
          { isPublic: true },
        ],
      },
      include: { items: true },
    });

    if (!list) {
      throw new Error('Liste bulunamadı veya erişim yok');
    }

    return list.items.map(item => ({
      id: item.id,
      type: item.itemType as 'product' | 'store',
      itemId: item.itemId,
      name: item.name,
      note: item.note || undefined,
      addedAt: item.createdAt,
    }));
  }

  /**
   * Listeyi paylaş
   */
  async shareList(listId: string, userId: string): Promise<string> {
    const list = await this.prisma.favoriteList.findFirst({
      where: { id: listId, userId },
    });

    if (!list) {
      throw new Error('Liste bulunamadı');
    }

    let shareCode = list.shareCode;

    if (!shareCode) {
      shareCode = this.generateShareCode();
      await this.prisma.favoriteList.update({
        where: { id: listId },
        data: { isPublic: true, shareCode },
      });
    }

    return shareCode;
  }

  /**
   * Paylaşım koduyla liste getir
   */
  async getListByShareCode(shareCode: string): Promise<FavoriteList | null> {
    const list = await this.prisma.favoriteList.findFirst({
      where: { shareCode, isPublic: true },
      include: { _count: { select: { items: true } } },
    });

    if (!list) return null;

    return {
      id: list.id,
      name: list.name,
      description: list.description || undefined,
      isPublic: true,
      shareCode: list.shareCode || undefined,
      itemCount: list._count.items,
      createdAt: list.createdAt,
    };
  }

  /**
   * Listeyi kopyala
   */
  async copyList(shareCode: string, userId: string, newName: string): Promise<FavoriteList> {
    const original = await this.prisma.favoriteList.findFirst({
      where: { shareCode, isPublic: true },
      include: { items: true },
    });

    if (!original) {
      throw new Error('Liste bulunamadı');
    }

    // Create new list with items
    const newList = await this.prisma.favoriteList.create({
      data: {
        userId,
        name: newName || `${original.name} (Kopya)`,
        description: original.description,
        isPublic: false,
        items: {
          create: original.items.map(item => ({
            itemType: item.itemType,
            itemId: item.itemId,
            name: item.name,
            note: item.note,
          })),
        },
      },
      include: { _count: { select: { items: true } } },
    });

    return {
      id: newList.id,
      name: newList.name,
      description: newList.description || undefined,
      isPublic: false,
      itemCount: newList._count.items,
      createdAt: newList.createdAt,
    };
  }

  private generateShareCode(): string {
    return crypto.randomBytes(4).toString('hex').toUpperCase();
  }
}
