# 🏪 Vendor & Order API

## Store Endpoints

### GET /stores

Mağazaları listele

**Query Params:**

- `category_id` - Kategori ID
- `latitude`, `longitude` - Kullanıcı konumu
- `radius` - Arama yarıçapı (metre)
- `is_open` - Sadece açık olanlar
- `sort` - distance | rating | newest
- `page`, `limit` - Sayfalama

**Response 200:**

```json
{
  "data": [
    {
      "id": "uuid",
      "name": "Kırşehir Kasabı",
      "logo_url": "https://...",
      "rating": 4.5,
      "review_count": 128,
      "is_open": true,
      "distance": 1.2,
      "delivery_time": "20-30 dk",
      "min_order": 50.0
    }
  ],
  "meta": { "total": 45, "page": 1, "limit": 20 }
}
```

---

### GET /stores/:id

Mağaza detayı

**Response 200:**

```json
{
  "id": "uuid",
  "name": "Kırşehir Kasabı",
  "description": "1985'ten beri...",
  "address": "Atatürk Cad. No:45",
  "phone": "+905551234567",
  "rating": 4.5,
  "is_open": true,
  "open_time": "08:00",
  "close_time": "22:00",
  "payment_types": ["CASH", "CARD", "IBAN"],
  "min_order": 50.00,
  "delivery_fee": 10.00,
  "products": [...],
  "campaigns": [...]
}
```

---

### POST /vendor/store (Vendor Only)

Mağaza oluştur

**Request:**

```json
{
  "name": "Kırşehir Kasabı",
  "description": "1985'ten beri...",
  "logo": "base64...",
  "address": "Atatürk Cad. No:45",
  "latitude": 39.1425,
  "longitude": 34.1709,
  "phone": "+905551234567",
  "payment_types": ["CASH", "CARD"],
  "iban": "TR123456789..."
}
```

---

### POST /vendor/products (Vendor Only)

Ürün ekle (minimum 2 fotoğraf zorunlu)

**Request:**

```json
{
  "name": "Dana Kıyma",
  "description": "Taze çekilmiş",
  "category_id": "uuid",
  "price": 280.0,
  "stock": 50,
  "unit": "kg",
  "images": ["base64...", "base64..."]
}
```

---

## Order Endpoints

### POST /orders

Sipariş oluştur

**Request:**

```json
{
  "store_id": "uuid",
  "items": [{ "product_id": "uuid", "quantity": 2 }],
  "address_id": "uuid",
  "address_note": "Kapıda bekliyorum",
  "payment_type": "CASH"
}
```

**Response 201:**

```json
{
  "id": "uuid",
  "order_no": "BS241228001234",
  "status": "PENDING",
  "total": 520.0,
  "estimated_delivery": "30-45 dk"
}
```

---

### GET /orders/:id

Sipariş detayı

**Response 200:**

```json
{
  "id": "uuid",
  "order_no": "BS241228001234",
  "status": "DELIVERING",
  "store": {...},
  "items": [...],
  "total": 520.00,
  "courier": {
    "name": "Mehmet",
    "phone": "+905...",
    "latitude": 39.14,
    "longitude": 34.17
  },
  "timeline": [
    { "status": "PENDING", "time": "12:00" },
    { "status": "ACCEPTED", "time": "12:02" }
  ],
  "chat_enabled": true
}
```

---

### PUT /vendor/orders/:id/status (Vendor Only)

Sipariş durumu güncelle

**Request:**

```json
{
  "status": "ACCEPTED | PREPARING | READY | REJECTED",
  "reject_reason": "Stok yok"
}
```

---

## Campaign Endpoints

### POST /vendor/campaigns (Vendor Only)

Kampanya oluştur

**Request:**

```json
{
  "product_id": "uuid",
  "type": "PERCENTAGE | FIXED_AMOUNT | BUY_X_GET_Y | HAPPY_HOUR",
  "value": 20,
  "start_date": "2024-01-01T00:00:00Z",
  "end_date": "2024-01-07T23:59:59Z",
  "stock_limit": 50
}
```

**Campaign Types:**

- `PERCENTAGE` - %10, %20 indirim
- `FIXED_AMOUNT` - 50 TL indirim
- `BUY_X_GET_Y` - 2 al 1 öde
- `HAPPY_HOUR` - Saat bazlı indirim
