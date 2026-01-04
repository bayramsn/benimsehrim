import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

@Injectable()
export class RedisService {
  private client: Redis | null = null;
  private readonly logger = new Logger(RedisService.name);

  constructor(private configService: ConfigService) {
    const redisHost = this.configService.get('REDIS_HOST');
    
    // Only connect to Redis if REDIS_HOST is configured
    if (redisHost) {
      try {
        this.client = new Redis({
          host: redisHost,
          port: this.configService.get('REDIS_PORT', 6379),
          password: this.configService.get('REDIS_PASSWORD'),
          maxRetriesPerRequest: 3,
          retryStrategy: (times) => {
            if (times > 3) {
              this.logger.warn('Redis connection failed, running without Redis');
              return null; // Stop retrying
            }
            return Math.min(times * 100, 3000);
          },
        });

        this.client.on('error', (err) => {
          this.logger.warn(`Redis error: ${err.message}. Running without cache.`);
        });

        this.client.on('connect', () => {
          this.logger.log('Redis connected successfully');
        });
      } catch (error) {
        this.logger.warn('Redis initialization failed, running without cache');
        this.client = null;
      }
    } else {
      this.logger.warn('REDIS_HOST not configured, running without Redis');
    }
  }

  getClient(): Redis | null {
    return this.client;
  }

  async get(key: string): Promise<string | null> {
    if (!this.client) return null;
    try {
      return await this.client.get(key);
    } catch {
      return null;
    }
  }

  async set(key: string, value: string, ttl?: number): Promise<void> {
    if (!this.client) return;
    try {
      if (ttl) {
        await this.client.setex(key, ttl, value);
      } else {
        await this.client.set(key, value);
      }
    } catch { }
  }

  async del(key: string): Promise<void> {
    if (!this.client) return;
    try {
      await this.client.del(key);
    } catch { }
  }

  async setJson<T>(key: string, value: T, ttl?: number): Promise<void> {
    await this.set(key, JSON.stringify(value), ttl);
  }

  async getJson<T>(key: string): Promise<T | null> {
    const value = await this.get(key);
    return value ? JSON.parse(value) : null;
  }

  // Pub/Sub for real-time events
  async publish(channel: string, message: any): Promise<void> {
    if (!this.client) return;
    try {
      await this.client.publish(channel, JSON.stringify(message));
    } catch { }
  }

  subscribe(channel: string, callback: (message: string) => void): void {
    if (!this.client) return;
    try {
      const subscriber = this.client.duplicate();
      subscriber.subscribe(channel);
      subscriber.on('message', (ch, message) => {
        if (ch === channel) {
          callback(message);
        }
      });
    } catch { }
  }

  // Location-based queries (for taxi/courier)
  async geoAdd(key: string, longitude: number, latitude: number, member: string): Promise<void> {
    if (!this.client) return;
    try {
      await this.client.geoadd(key, longitude, latitude, member);
    } catch { }
  }

  async geoRadius(
    key: string, 
    longitude: number, 
    latitude: number, 
    radius: number, 
    unit: 'km' | 'm' = 'km'
  ): Promise<string[]> {
    if (!this.client) return [];
    try {
      const result = await this.client.georadius(key, longitude, latitude, radius, unit);
      return result as string[];
    } catch {
      return [];
    }
  }

  async geoRemove(key: string, member: string): Promise<void> {
    if (!this.client) return;
    try {
      await this.client.zrem(key, member);
    } catch { }
  }
}

