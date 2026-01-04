import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayInit,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Logger } from '@nestjs/common';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { RedisService } from '../common/redis/redis.service';

interface AuthenticatedSocket extends Socket {
  userId: string;
  role: string;
}

@WebSocketGateway({
  cors: {
    origin: '*',
    credentials: true,
  },
  namespace: '/ws',
})
export class EventsGateway implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(EventsGateway.name);
  private userSockets = new Map<string, string[]>(); // userId -> socketIds

  constructor(
    private jwtService: JwtService,
    private redis: RedisService,
  ) {}

  afterInit(server: Server) {
    this.logger.log('WebSocket Gateway initialized');
  }

  async handleConnection(client: Socket) {
    try {
      const token = client.handshake.auth?.token || client.handshake.headers?.authorization?.replace('Bearer ', '');
      
      if (!token) {
        client.disconnect();
        return;
      }

      const payload = this.jwtService.verify(token);
      (client as AuthenticatedSocket).userId = payload.sub;
      (client as AuthenticatedSocket).role = payload.role;

      // Socket'i kullanıcıya bağla
      const userId = payload.sub;
      if (!this.userSockets.has(userId)) {
        this.userSockets.set(userId, []);
      }
      this.userSockets.get(userId)!.push(client.id);

      // Role bazlı room'a ekle
      client.join(`role:${payload.role}`);
      client.join(`user:${userId}`);

      this.logger.log(`Client connected: ${client.id} (User: ${userId})`);
    } catch (error) {
      this.logger.error(`Connection error: ${error.message}`);
      client.disconnect();
    }
  }

  handleDisconnect(client: Socket) {
    const authClient = client as AuthenticatedSocket;
    
    if (authClient.userId) {
      const sockets = this.userSockets.get(authClient.userId) || [];
      const index = sockets.indexOf(client.id);
      if (index > -1) {
        sockets.splice(index, 1);
      }
      if (sockets.length === 0) {
        this.userSockets.delete(authClient.userId);
      }
    }

    this.logger.log(`Client disconnected: ${client.id}`);
  }

  /**
   * Konum güncelleme (Taksi/Kurye için)
   */
  @SubscribeMessage('location:update')
  async handleLocationUpdate(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: { lat: number; lng: number },
  ) {
    const userId = client.userId;
    const role = client.role;

    if (role === 'TAXI_DRIVER') {
      // Redis GEO'ya kaydet
      await this.redis.geoAdd('drivers:locations', data.lng, data.lat, userId);
      
      // Aktif yolculuk varsa kullanıcıya bildir
      // Bu event'i taksi servisi dinler ve ilgili kullanıcılara yayınlar
      this.server.emit('driver:location', { driverId: userId, ...data });
    }

    if (role === 'COURIER') {
      await this.redis.geoAdd('couriers:locations', data.lng, data.lat, userId);
      this.server.emit('courier:location', { courierId: userId, ...data });
    }

    return { success: true };
  }

  /**
   * Sipariş durumu değişikliği bildirimi
   */
  emitOrderStatus(userId: string, data: { orderId: string; status: string; courierLocation?: any }) {
    this.server.to(`user:${userId}`).emit('order:status', data);
  }

  /**
   * Yolculuk durumu değişikliği bildirimi
   */
  emitRideStatus(userId: string, data: { rideId: string; status: string; driverLocation?: any; eta?: number }) {
    this.server.to(`user:${userId}`).emit('ride:status', data);
  }

  /**
   * Esnafa yeni sipariş bildirimi
   */
  emitNewOrderToVendor(vendorUserId: string, data: { orderId: string; items: any[]; total: number }) {
    this.server.to(`user:${vendorUserId}`).emit('vendor:new_order', data);
  }

  /**
   * Şoföre yeni çağrı bildirimi
   */
  emitNewRideToDriver(driverUserId: string, data: any) {
    this.server.to(`user:${driverUserId}`).emit('driver:new_ride', data);
  }

  /**
   * Kuryeye yeni görev bildirimi
   */
  emitNewDeliveryToCourier(courierUserId: string, data: any) {
    this.server.to(`user:${courierUserId}`).emit('courier:new_delivery', data);
  }

  /**
   * Chat mesajı
   */
  @SubscribeMessage('chat:send')
  async handleChatMessage(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: { chatId: string; content: string },
  ) {
    // Mesajı veritabanına kaydet ve karşı tarafa gönder
    // Bu işlem chat servisi tarafından yapılır
    this.server.emit('chat:message:new', {
      chatId: data.chatId,
      senderId: client.userId,
      content: data.content,
      createdAt: new Date(),
    });

    return { success: true };
  }

  /**
   * Chat mesajı bildirimi
   */
  emitChatMessage(userId: string, data: { chatId: string; message: any }) {
    this.server.to(`user:${userId}`).emit('chat:message', data);
  }

  /**
   * Şoför online/offline durumu
   */
  @SubscribeMessage('driver:status')
  async handleDriverStatus(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: { isOnline: boolean; lat?: number; lng?: number },
  ) {
    if (client.role !== 'TAXI_DRIVER') {
      return { success: false, message: 'Unauthorized' };
    }

    if (data.isOnline && data.lat && data.lng) {
      await this.redis.geoAdd('drivers:locations', data.lng, data.lat, client.userId);
    } else {
      await this.redis.geoRemove('drivers:locations', client.userId);
    }

    return { success: true };
  }

  /**
   * Kurye online/offline durumu
   */
  @SubscribeMessage('courier:status')
  async handleCourierStatus(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: { isOnline: boolean; lat?: number; lng?: number },
  ) {
    if (client.role !== 'COURIER') {
      return { success: false, message: 'Unauthorized' };
    }

    if (data.isOnline && data.lat && data.lng) {
      await this.redis.geoAdd('couriers:locations', data.lng, data.lat, client.userId);
    } else {
      await this.redis.geoRemove('couriers:locations', client.userId);
    }

    return { success: true };
  }
}
