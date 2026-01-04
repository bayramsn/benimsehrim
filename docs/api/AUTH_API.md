# 🔐 Auth API

## Base URL

```
Production: https://api.benimsehrim.com/v1
Development: http://localhost:3000/v1
```

## Endpoints

### POST /auth/send-otp

SMS ile OTP gönder

**Request:**

```json
{
  "phone": "+905551234567"
}
```

**Response 200:**

```json
{
  "success": true,
  "message": "OTP sent successfully",
  "expires_in": 120
}
```

---

### POST /auth/verify-otp

OTP doğrula ve giriş yap

**Request:**

```json
{
  "phone": "+905551234567",
  "otp": "123456"
}
```

**Response 200:**

```json
{
  "access_token": "jwt_token",
  "refresh_token": "refresh_token",
  "user": {
    "id": "uuid",
    "phone": "+905551234567",
    "name": "Ahmet Yılmaz",
    "role": "USER",
    "city_id": "city_uuid",
    "is_new_user": false
  }
}
```

---

### POST /auth/register

Yeni kullanıcı kaydı

**Request:**

```json
{
  "phone": "+905551234567",
  "name": "Ahmet Yılmaz",
  "email": "ahmet@email.com",
  "city_id": "city_uuid",
  "district_id": "district_uuid"
}
```

**Response 201:**

```json
{
  "access_token": "jwt_token",
  "user": {
    "id": "uuid",
    "phone": "+905551234567",
    "name": "Ahmet Yılmaz"
  }
}
```

---

### POST /auth/refresh

Token yenile

**Request:**

```json
{
  "refresh_token": "refresh_token"
}
```

**Response 200:**

```json
{
  "access_token": "new_jwt_token",
  "refresh_token": "new_refresh_token"
}
```

---

## JWT Payload Structure

```json
{
  "sub": "user_id",
  "phone": "+905551234567",
  "role": "USER | VENDOR | TAXI_DRIVER | COURIER | ADMIN",
  "city_id": "city_uuid",
  "iat": 1234567890,
  "exp": 1234657890
}
```

## Required Headers

```
Authorization: Bearer <jwt_token>
Content-Type: application/json
X-City-Id: <city_id>
```
