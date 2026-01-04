import { IsString, IsNotEmpty, Matches, Length } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class SendOtpDto {
  @ApiProperty({ example: '+905551234567', description: 'Telefon numarası' })
  @IsString()
  @IsNotEmpty()
  @Matches(/^\+90[0-9]{10}$/, { message: 'Geçerli bir Türkiye telefon numarası giriniz' })
  phone: string;
}

export class VerifyOtpDto {
  @ApiProperty({ example: '+905551234567' })
  @IsString()
  @IsNotEmpty()
  @Matches(/^\+90[0-9]{10}$/, { message: 'Geçerli bir Türkiye telefon numarası giriniz' })
  phone: string;

  @ApiProperty({ example: '123456', description: '6 haneli doğrulama kodu' })
  @IsString()
  @IsNotEmpty()
  @Length(6, 6, { message: 'OTP 6 haneli olmalıdır' })
  otp: string;
}

export class RegisterDto {
  @ApiProperty({ example: '+905551234567' })
  @IsString()
  @IsNotEmpty()
  @Matches(/^\+90[0-9]{10}$/)
  phone: string;

  @ApiProperty({ example: 'Ahmet Yılmaz' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ example: 'ahmet@email.com', required: false })
  @IsString()
  email?: string;

  @ApiProperty({ description: 'Şehir ID' })
  @IsString()
  @IsNotEmpty()
  cityId: string;

  @ApiProperty({ description: 'İlçe ID', required: false })
  @IsString()
  districtId?: string;
}

export class RefreshTokenDto {
  @ApiProperty({ description: 'Refresh token' })
  @IsString()
  @IsNotEmpty()
  refreshToken: string;
}

export { SendOtpDto as SendOtpRequest };
export { VerifyOtpDto as VerifyOtpRequest };
export { RegisterDto as RegisterRequest };
export { RefreshTokenDto as RefreshTokenRequest };
