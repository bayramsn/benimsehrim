import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export interface EmailPayload {
  to: string;
  subject: string;
  html: string;
  text?: string;
}

/**
 * Email Service - Multiple FREE providers
 * 
 * FREE Options:
 * - Resend: 3000 emails/month - https://resend.com
 * - SendGrid: 100 emails/day - https://sendgrid.com
 * - Mailtrap: Testing only - https://mailtrap.io
 * - SMTP: Use with any provider
 */
@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private provider: string;

  constructor(private configService: ConfigService) {
    this.provider = this.configService.get('EMAIL_PROVIDER') || 'mock';
  }

  async send(payload: EmailPayload): Promise<boolean> {
    this.logger.log(`[${this.provider}] Sending email to ${payload.to}: ${payload.subject}`);

    switch (this.provider) {
      case 'resend':
        return this.sendWithResend(payload);
      case 'sendgrid':
        return this.sendWithSendGrid(payload);
      case 'smtp':
        return this.sendWithSMTP(payload);
      default:
        // Mock - just log
        this.logger.debug(`Mock email to ${payload.to}:\n${payload.subject}\n${payload.html.substring(0, 200)}...`);
        return true;
    }
  }

  /**
   * Resend - Modern email API (FREE: 3000 emails/month)
   * https://resend.com
   */
  private async sendWithResend(payload: EmailPayload): Promise<boolean> {
    try {
      const apiKey = this.configService.get('RESEND_API_KEY');
      const from = this.configService.get('EMAIL_FROM') || 'onboarding@resend.dev';

      if (!apiKey) {
        this.logger.warn('Resend API key not configured');
        return false;
      }

      const response = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          from,
          to: payload.to,
          subject: payload.subject,
          html: payload.html,
        }),
      });

      const result = await response.json();
      
      if (!response.ok) {
        this.logger.error('Resend error:', result);
        return false;
      }

      return true;
    } catch (error) {
      this.logger.error('Resend error:', error);
      return false;
    }
  }

  /**
   * SendGrid - Popular email service (FREE: 100 emails/day)
   * https://sendgrid.com
   */
  private async sendWithSendGrid(payload: EmailPayload): Promise<boolean> {
    try {
      const apiKey = this.configService.get('SENDGRID_API_KEY');
      const from = this.configService.get('EMAIL_FROM');

      if (!apiKey) {
        this.logger.warn('SendGrid API key not configured');
        return false;
      }

      const response = await fetch('https://api.sendgrid.com/v3/mail/send', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          personalizations: [{ to: [{ email: payload.to }] }],
          from: { email: from },
          subject: payload.subject,
          content: [{ type: 'text/html', value: payload.html }],
        }),
      });

      return response.ok;
    } catch (error) {
      this.logger.error('SendGrid error:', error);
      return false;
    }
  }

  /**
   * SMTP - Requires nodemailer package
   * Install with: npm install nodemailer @types/nodemailer
   * For now, falls back to mock
   */
  private async sendWithSMTP(payload: EmailPayload): Promise<boolean> {
    this.logger.warn('SMTP requires nodemailer. Using mock mode.');
    this.logger.debug(`Mock SMTP email to ${payload.to}:\n${payload.subject}`);
    return true;
  }

  // ============================================
  // TEMPLATE METHODS
  // ============================================

  async sendWelcome(to: string, name: string): Promise<boolean> {
    return this.send({
      to,
      subject: 'Benim Şehrim\'e Hoş Geldiniz! 🎉',
      html: this.getWelcomeTemplate(name),
    });
  }

  async sendOrderConfirmation(
    to: string,
    orderNo: string,
    items: { name: string; quantity: number; price: number }[],
    total: number,
  ): Promise<boolean> {
    return this.send({
      to,
      subject: `Siparişiniz Alındı - ${orderNo}`,
      html: this.getOrderConfirmationTemplate(orderNo, items, total),
    });
  }

  async sendOrderStatusUpdate(
    to: string,
    orderNo: string,
    status: string,
    message: string,
  ): Promise<boolean> {
    return this.send({
      to,
      subject: `Sipariş Durumu Güncellendi - ${orderNo}`,
      html: this.getOrderStatusTemplate(orderNo, status, message),
    });
  }

  async sendOtp(to: string, otp: string): Promise<boolean> {
    return this.send({
      to,
      subject: `Doğrulama Kodunuz: ${otp}`,
      html: this.getOtpTemplate(otp),
    });
  }

  // ============================================
  // HTML TEMPLATES
  // ============================================

  private baseTemplate(content: string): string {
    return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 0; background-color: #f5f5f5; }
    .container { max-width: 600px; margin: 0 auto; background: white; }
    .header { background: linear-gradient(135deg, #006E24 0%, #00A63E 100%); padding: 30px; text-align: center; }
    .header h1 { color: white; margin: 0; font-size: 28px; }
    .content { padding: 30px; }
    .footer { background: #f8f9fa; padding: 20px; text-align: center; color: #666; font-size: 12px; }
    .button { display: inline-block; background: #006E24; color: white; padding: 14px 28px; text-decoration: none; border-radius: 8px; font-weight: bold; }
    .card { background: #f8f9fa; border-radius: 8px; padding: 20px; margin: 20px 0; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🏙️ Benim Şehrim</h1>
    </div>
    <div class="content">${content}</div>
    <div class="footer">
      <p>Bu email Benim Şehrim tarafından gönderilmiştir.</p>
    </div>
  </div>
</body>
</html>`;
  }

  private getWelcomeTemplate(name: string): string {
    return this.baseTemplate(`
      <h2>Merhaba ${name}! 👋</h2>
      <p>Benim Şehrim ailesine hoş geldiniz!</p>
      <div class="card">
        <h3>📱 Neler Yapabilirsiniz?</h3>
        <ul>
          <li>🛍️ Yerel mağazalardan alışveriş yapın</li>
          <li>🚕 Taksi çağırın</li>
          <li>📦 Kurye ile gönderi yapın</li>
        </ul>
      </div>
      <p style="text-align: center;">
        <a href="https://benimsehrim.com" class="button">Alışverişe Başla</a>
      </p>
    `);
  }

  private getOrderConfirmationTemplate(
    orderNo: string,
    items: { name: string; quantity: number; price: number }[],
    total: number,
  ): string {
    const itemsHtml = items.map(i => `
      <tr>
        <td style="padding: 8px; border-bottom: 1px solid #eee;">${i.name}</td>
        <td style="padding: 8px; border-bottom: 1px solid #eee; text-align: center;">${i.quantity}</td>
        <td style="padding: 8px; border-bottom: 1px solid #eee; text-align: right;">${i.price}₺</td>
      </tr>
    `).join('');

    return this.baseTemplate(`
      <h2>Siparişiniz Alındı! ✅</h2>
      <p><strong>Sipariş No:</strong> ${orderNo}</p>
      <div class="card">
        <table width="100%" style="border-collapse: collapse;">
          <thead>
            <tr>
              <th style="text-align: left; padding: 8px;">Ürün</th>
              <th style="text-align: center; padding: 8px;">Adet</th>
              <th style="text-align: right; padding: 8px;">Fiyat</th>
            </tr>
          </thead>
          <tbody>${itemsHtml}</tbody>
          <tfoot>
            <tr>
              <td colspan="2" style="padding: 12px; font-weight: bold;">Toplam</td>
              <td style="padding: 12px; text-align: right; font-weight: bold; color: #006E24; font-size: 18px;">${total}₺</td>
            </tr>
          </tfoot>
        </table>
      </div>
    `);
  }

  private getOrderStatusTemplate(orderNo: string, status: string, message: string): string {
    const statusEmoji: Record<string, string> = {
      ACCEPTED: '✅',
      PREPARING: '👨‍🍳',
      READY: '📦',
      ON_WAY: '🚚',
      DELIVERED: '🎉',
    };

    return this.baseTemplate(`
      <h2>${statusEmoji[status] || '📋'} Sipariş Durumu</h2>
      <p><strong>Sipariş No:</strong> ${orderNo}</p>
      <div class="card" style="text-align: center;">
        <p style="font-size: 48px; margin: 0;">${statusEmoji[status] || '📋'}</p>
        <h3 style="margin: 10px 0;">${message}</h3>
      </div>
    `);
  }

  private getOtpTemplate(otp: string): string {
    return this.baseTemplate(`
      <h2>Doğrulama Kodunuz</h2>
      <div class="card" style="text-align: center;">
        <p style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #006E24;">${otp}</p>
        <p style="color: #666;">Bu kod 5 dakika geçerlidir.</p>
      </div>
      <p style="color: #999; font-size: 12px;">Bu kodu kimseyle paylaşmayın.</p>
    `);
  }
}
