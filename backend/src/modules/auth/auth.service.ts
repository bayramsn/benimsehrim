import { Injectable, UnauthorizedException, BadRequestException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../../common/prisma/prisma.service';
import { OtpService } from './otp.service';
import { SendOtpDto, VerifyOtpDto, RegisterDto, RefreshTokenDto } from './dto';
import { UserRole } from '@prisma/client';

export interface JwtPayload {
  sub: string;
  phone: string;
  role: UserRole;
  cityId?: string;
}

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private otpService: OtpService,
  ) {}

  async sendOtp(dto: SendOtpDto) {
    // Check if user exists
    const user = await this.prisma.user.findUnique({
      where: { phone: dto.phone },
    });

    // Generate and send OTP
    const otp = await this.otpService.generateAndSend(dto.phone);

    return {
      success: true,
      message: 'OTP gönderildi',
      expiresIn: 120,
      isNewUser: !user,
    };
  }

  async verifyOtp(dto: VerifyOtpDto) {
    // Verify OTP
    const isValid = await this.otpService.verify(dto.phone, dto.otp);
    
    if (!isValid) {
      throw new UnauthorizedException('Geçersiz veya süresi dolmuş kod');
    }

    // Find or check user
    const user = await this.prisma.user.findUnique({
      where: { phone: dto.phone },
      include: {
        city: true,
        district: true,
      },
    });

    if (!user) {
      // Return flag that user needs to register
      return {
        success: true,
        isNewUser: true,
        phone: dto.phone,
        message: 'Kayıt tamamlanması gerekiyor',
      };
    }

    // Generate tokens
    const tokens = await this.generateTokens(user);

    return {
      ...tokens,
      user: {
        id: user.id,
        phone: user.phone,
        name: user.name,
        email: user.email,
        role: user.role,
        city: user.city,
        district: user.district,
        isNewUser: false,
      },
    };
  }

  async register(dto: RegisterDto) {
    // Check if phone already exists
    const existing = await this.prisma.user.findUnique({
      where: { phone: dto.phone },
    });

    if (existing) {
      throw new BadRequestException('Bu telefon numarası zaten kayıtlı');
    }

    // Create user
    const user = await this.prisma.user.create({
      data: {
        phone: dto.phone,
        name: dto.name,
        email: dto.email,
        cityId: dto.cityId,
        districtId: dto.districtId,
        role: UserRole.USER,
      },
      include: {
        city: true,
        district: true,
      },
    });

    // Generate tokens
    const tokens = await this.generateTokens(user);

    return {
      ...tokens,
      user: {
        id: user.id,
        phone: user.phone,
        name: user.name,
        email: user.email,
        role: user.role,
        city: user.city,
        district: user.district,
      },
    };
  }

  async refreshToken(dto: RefreshTokenDto) {
    try {
      const payload = this.jwtService.verify(dto.refreshToken);
      
      const user = await this.prisma.user.findUnique({
        where: { id: payload.sub },
      });

      if (!user) {
        throw new UnauthorizedException('Kullanıcı bulunamadı');
      }

      return this.generateTokens(user);
    } catch (error) {
      throw new UnauthorizedException('Geçersiz refresh token');
    }
  }

  private async generateTokens(user: any) {
    const payload: JwtPayload = {
      sub: user.id,
      phone: user.phone,
      role: user.role,
      cityId: user.cityId,
    };

    const accessToken = this.jwtService.sign(payload);
    const refreshToken = this.jwtService.sign(payload, { expiresIn: '30d' });

    return {
      accessToken,
      refreshToken,
    };
  }
}
