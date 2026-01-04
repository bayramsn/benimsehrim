import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { ScheduleModule } from '@nestjs/schedule';

// Core Modules
import { PrismaModule } from './common/prisma/prisma.module';
import { RedisModule } from './common/redis/redis.module';
import { FirebaseModule } from './common/firebase/firebase.module';

// Feature Modules
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { CitiesModule } from './modules/cities/cities.module';
import { CategoriesModule } from './modules/categories/categories.module';
import { StoresModule } from './modules/stores/stores.module';
import { ProductsModule } from './modules/products/products.module';
import { CampaignsModule } from './modules/campaigns/campaigns.module';
import { OrdersModule } from './modules/orders/orders.module';
import { TaxiModule } from './modules/taxi/taxi.module';
import { CourierModule } from './modules/courier/courier.module';
import { ChatModule } from './modules/chat/chat.module';
import { ReviewsModule } from './modules/reviews/reviews.module';
import { SupportModule } from './modules/support/support.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { FeatureFlagsModule } from './modules/feature-flags/feature-flags.module';
import { AdminModule } from './modules/admin/admin.module';
import { RecommendationsModule } from './modules/recommendations/recommendations.module';

// Gateway
import { EventsGateway } from './gateways/events.gateway';
import { HealthController } from './health.controller';

@Module({
  imports: [
    // Configuration
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: `.env.${process.env.NODE_ENV || 'development'}`,
    }),

    // Rate Limiting
    ThrottlerModule.forRoot([
      {
        name: 'short',
        ttl: 1000,
        limit: 3,
      },
      {
        name: 'medium',
        ttl: 10000,
        limit: 20,
      },
      {
        name: 'long',
        ttl: 60000,
        limit: 100,
      },
    ]),

    // Scheduled Tasks
    ScheduleModule.forRoot(),

    // Core
    PrismaModule,
    RedisModule,
    FirebaseModule,

    // Features
    AuthModule,
    UsersModule,
    CitiesModule,
    CategoriesModule,
    StoresModule,
    ProductsModule,
    CampaignsModule,
    OrdersModule,
    TaxiModule,
    CourierModule,
    ChatModule,
    ReviewsModule,
    SupportModule,
    NotificationsModule,
    FeatureFlagsModule,
    AdminModule,
    RecommendationsModule,
  ],
  controllers: [HealthController],
  providers: [EventsGateway],
})
export class AppModule {}
