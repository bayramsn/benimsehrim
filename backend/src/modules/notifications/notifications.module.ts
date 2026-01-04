import { Module } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { NotificationsController } from './notifications.controller';
import { PushService } from './push.service';
import { SmsService } from './sms.service';
import { WhatsAppService } from './whatsapp.service';

@Module({
  controllers: [NotificationsController],
  providers: [NotificationsService, PushService, SmsService, WhatsAppService],
  exports: [NotificationsService, PushService, SmsService, WhatsAppService],
})
export class NotificationsModule {}
