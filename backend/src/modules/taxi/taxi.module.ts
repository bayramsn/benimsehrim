import { Module } from '@nestjs/common';
import { TaxiController } from './taxi.controller';
import { TaxiService } from './taxi.service';
import { TaxiAutomationService } from './taxi-automation.service';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [NotificationsModule],
  controllers: [TaxiController],
  providers: [TaxiService, TaxiAutomationService],
  exports: [TaxiService],
})
export class TaxiModule {}
