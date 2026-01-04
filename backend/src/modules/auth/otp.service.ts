import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { RedisService } from '../../common/redis/redis.service';

@Injectable()
export class OtpService {
  private readonly OTP_TTL = 120; // 2 dakika
  private readonly OTP_PREFIX = 'otp:';

  constructor(
    private redis: RedisService,
    private config: ConfigService,
  ) {}

  async generateAndSend(phone: string): Promise<string> {
    // 6 haneli OTP oluştur
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    // Redis'e kaydet (2 dakika TTL)
    await this.redis.set(`${this.OTP_PREFIX}${phone}`, otp, this.OTP_TTL);

    // SMS gönder
    await this.sendSms(phone, otp);

    // Development modunda console'a yaz
    if (this.config.get('NODE_ENV') === 'development') {
      console.log(`🔐 OTP for ${phone}: ${otp}`);
    }

    return otp;
  }

  async verify(phone: string, otp: string): Promise<boolean> {
    const storedOtp = await this.redis.get(`${this.OTP_PREFIX}${phone}`);

    if (!storedOtp) {
      return false;
    }

    if (storedOtp !== otp) {
      return false;
    }

    // Kullanıldıktan sonra sil
    await this.redis.del(`${this.OTP_PREFIX}${phone}`);

    return true;
  }

  private async sendSms(phone: string, otp: string): Promise<void> {
    const provider = this.config.get('SMS_PROVIDER', 'mock');

    if (provider === 'mock' || this.config.get('NODE_ENV') === 'development') {
      console.log(`📱 [MOCK SMS] ${phone}: Doğrulama kodunuz: ${otp}`);
      return;
    }

    // Twilio integration
    if (provider === 'twilio') {
      const twilioClient = require('twilio')(
        this.config.get('TWILIO_ACCOUNT_SID'),
        this.config.get('TWILIO_AUTH_TOKEN'),
      );

      await twilioClient.messages.create({
        body: `Benim Şehrim doğrulama kodunuz: ${otp}`,
        from: this.config.get('TWILIO_PHONE_NUMBER'),
        to: phone,
      });
    }

    // NetGSM integration (Türkiye için popüler)
    if (provider === 'netgsm') {
      // NetGSM API entegrasyonu
      const axios = require('axios');
      await axios.get('https://api.netgsm.com.tr/sms/send/get', {
        params: {
          usercode: this.config.get('NETGSM_USERCODE'),
          password: this.config.get('NETGSM_PASSWORD'),
          gsmno: phone.replace('+90', ''),
          message: `Benim Sehrim dogrulama kodunuz: ${otp}`,
          msgheader: this.config.get('NETGSM_HEADER'),
        },
      });
    }
  }
}
