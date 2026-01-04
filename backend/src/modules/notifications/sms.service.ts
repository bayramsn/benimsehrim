import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class SmsService {
  constructor(private config: ConfigService) {}

  async send(phone: string, message: string): Promise<boolean> {
    const provider = this.config.get('SMS_PROVIDER', 'mock');

    // Development mode - mock
    if (provider === 'mock' || this.config.get('NODE_ENV') === 'development') {
      console.log(`📱 [MOCK SMS] ${phone}: ${message}`);
      return true;
    }

    try {
      // Twilio
      if (provider === 'twilio') {
        const twilio = require('twilio')(
          this.config.get('TWILIO_ACCOUNT_SID'),
          this.config.get('TWILIO_AUTH_TOKEN'),
        );

        await twilio.messages.create({
          body: message,
          from: this.config.get('TWILIO_PHONE_NUMBER'),
          to: phone,
        });

        return true;
      }

      // NetGSM (Türkiye için)
      if (provider === 'netgsm') {
        const axios = require('axios');
        const response = await axios.get('https://api.netgsm.com.tr/sms/send/get', {
          params: {
            usercode: this.config.get('NETGSM_USERCODE'),
            password: this.config.get('NETGSM_PASSWORD'),
            gsmno: phone.replace('+90', ''),
            message: message,
            msgheader: this.config.get('NETGSM_HEADER'),
          },
        });

        return response.data.startsWith('00');
      }

      return false;
    } catch (error) {
      console.error('SMS error:', error);
      return false;
    }
  }
}
