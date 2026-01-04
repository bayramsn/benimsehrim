import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export interface SmsPayload {
  to: string;
  message: string;
}

@Injectable()
export class SmsService {
  private readonly logger = new Logger(SmsService.name);
  private provider: string;

  constructor(private configService: ConfigService) {
    this.provider = this.configService.get('SMS_PROVIDER') || 'mock';
  }

  async send(payload: SmsPayload): Promise<boolean> {
    this.logger.log(`[${this.provider}] Sending SMS to ${payload.to}`);

    switch (this.provider) {
      case 'netgsm':
        return this.sendWithNetGSM(payload);
      case 'twilio':
        return this.sendWithTwilio(payload);
      case 'textbelt':
        return this.sendWithTextbelt(payload);
      default:
        // Mock - just log
        this.logger.debug(`Mock SMS -> ${payload.to}: ${payload.message}`);
        return true;
    }
  }

  /**
   * NetGSM - Turkish SMS Provider
   * Free trial available: https://www.netgsm.com.tr
   */
  private async sendWithNetGSM(payload: SmsPayload): Promise<boolean> {
    try {
      const usercode = this.configService.get('NETGSM_USERCODE');
      const password = this.configService.get('NETGSM_PASSWORD');
      const header = this.configService.get('NETGSM_HEADER');

      if (!usercode || !password) {
        this.logger.warn('NetGSM credentials not configured');
        return false;
      }

      const params = new URLSearchParams({
        usercode,
        password,
        gsmno: payload.to.replace('+90', ''),
        message: payload.message,
        msgheader: header || 'BENIMSEHRIM',
        filter: '0',
      });

      const response = await fetch(
        `https://api.netgsm.com.tr/sms/send/get?${params}`,
      );
      const result = await response.text();

      // NetGSM returns numbers starting with 00 for success
      const success = result.startsWith('00') || result.startsWith('01');
      
      if (!success) {
        this.logger.error(`NetGSM error: ${result}`);
      }

      return success;
    } catch (error) {
      this.logger.error('NetGSM error:', error);
      return false;
    }
  }

  /**
   * Twilio - International SMS
   * Free trial: $15 credit - https://www.twilio.com
   */
  private async sendWithTwilio(payload: SmsPayload): Promise<boolean> {
    try {
      const accountSid = this.configService.get('TWILIO_ACCOUNT_SID');
      const authToken = this.configService.get('TWILIO_AUTH_TOKEN');
      const from = this.configService.get('TWILIO_PHONE_NUMBER');

      if (!accountSid || !authToken) {
        this.logger.warn('Twilio credentials not configured');
        return false;
      }

      const response = await fetch(
        `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`,
        {
          method: 'POST',
          headers: {
            'Authorization': 'Basic ' + Buffer.from(`${accountSid}:${authToken}`).toString('base64'),
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: new URLSearchParams({
            To: payload.to,
            From: from,
            Body: payload.message,
          }),
        },
      );

      const result = await response.json();
      return result.status === 'queued' || result.status === 'sent';
    } catch (error) {
      this.logger.error('Twilio error:', error);
      return false;
    }
  }

  /**
   * Textbelt - FREE 1 SMS/day for testing
   * https://textbelt.com
   */
  private async sendWithTextbelt(payload: SmsPayload): Promise<boolean> {
    try {
      const response = await fetch('https://textbelt.com/text', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          phone: payload.to,
          message: payload.message,
          key: 'textbelt', // Free key - 1 SMS/day
        }),
      });

      const result = await response.json();
      return result.success === true;
    } catch (error) {
      this.logger.error('Textbelt error:', error);
      return false;
    }
  }

  /**
   * Send OTP message
   */
  async sendOtp(phone: string, otp: string): Promise<boolean> {
    return this.send({
      to: phone,
      message: `Benim Şehrim doğrulama kodunuz: ${otp}. Bu kodu kimseyle paylaşmayın.`,
    });
  }

  /**
   * Send order notification
   */
  async sendOrderNotification(phone: string, orderNo: string, status: string): Promise<boolean> {
    const messages: Record<string, string> = {
      ACCEPTED: `Siparişiniz (${orderNo}) onaylandı ve hazırlanıyor!`,
      READY: `Siparişiniz (${orderNo}) hazır! Kurye yolda.`,
      ON_WAY: `Siparişiniz (${orderNo}) yola çıktı! Az kaldı...`,
      DELIVERED: `Siparişiniz (${orderNo}) teslim edildi. Afiyet olsun! 🎉`,
    };

    const message = messages[status];
    if (!message) return false;

    return this.send({ to: phone, message });
  }
}
