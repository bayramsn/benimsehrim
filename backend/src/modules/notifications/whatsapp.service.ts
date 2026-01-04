import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class WhatsAppService {
  constructor(private config: ConfigService) {}

  async send(phone: string, message: string): Promise<boolean> {
    const provider = this.config.get('WHATSAPP_PROVIDER', 'mock');

    // Development mode - mock
    if (provider === 'mock' || this.config.get('NODE_ENV') === 'development') {
      console.log(`📱 [MOCK WHATSAPP] ${phone}: ${message}`);
      return true;
    }

    try {
      // Twilio WhatsApp
      if (provider === 'twilio') {
        const twilio = require('twilio')(
          this.config.get('TWILIO_ACCOUNT_SID'),
          this.config.get('TWILIO_AUTH_TOKEN'),
        );

        await twilio.messages.create({
          body: message,
          from: `whatsapp:${this.config.get('TWILIO_WHATSAPP_NUMBER')}`,
          to: `whatsapp:${phone}`,
        });

        return true;
      }

      // WhatsApp Business API (Meta)
      if (provider === 'meta') {
        const axios = require('axios');
        
        await axios.post(
          `https://graph.facebook.com/v18.0/${this.config.get('WHATSAPP_PHONE_ID')}/messages`,
          {
            messaging_product: 'whatsapp',
            to: phone.replace('+', ''),
            type: 'text',
            text: { body: message },
          },
          {
            headers: {
              Authorization: `Bearer ${this.config.get('WHATSAPP_ACCESS_TOKEN')}`,
              'Content-Type': 'application/json',
            },
          },
        );

        return true;
      }

      return false;
    } catch (error) {
      console.error('WhatsApp error:', error);
      return false;
    }
  }

  async sendTemplate(
    phone: string,
    templateName: string,
    parameters: string[],
  ): Promise<boolean> {
    if (this.config.get('NODE_ENV') === 'development') {
      console.log(`📱 [MOCK WHATSAPP TEMPLATE] ${phone}: ${templateName}`, parameters);
      return true;
    }

    try {
      const axios = require('axios');
      
      await axios.post(
        `https://graph.facebook.com/v18.0/${this.config.get('WHATSAPP_PHONE_ID')}/messages`,
        {
          messaging_product: 'whatsapp',
          to: phone.replace('+', ''),
          type: 'template',
          template: {
            name: templateName,
            language: { code: 'tr' },
            components: [
              {
                type: 'body',
                parameters: parameters.map((p) => ({ type: 'text', text: p })),
              },
            ],
          },
        },
        {
          headers: {
            Authorization: `Bearer ${this.config.get('WHATSAPP_ACCESS_TOKEN')}`,
            'Content-Type': 'application/json',
          },
        },
      );

      return true;
    } catch (error) {
      console.error('WhatsApp template error:', error);
      return false;
    }
  }
}
