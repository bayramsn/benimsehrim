# 🗄️ Database Şeması

## Entity Relationship Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              CORE ENTITIES                                   │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│    users     │      │    cities    │      │   districts  │
├──────────────┤      ├──────────────┤      ├──────────────┤
│ id           │      │ id           │      │ id           │
│ phone        │◄────►│ name         │◄────►│ city_id      │
│ email        │      │ code         │      │ name         │
│ password     │      │ is_active    │      │ is_active    │
│ role         │      │ coordinates  │      │ coordinates  │
│ city_id      │      └──────────────┘      └──────────────┘
│ district_id  │
│ created_at   │
└──────────────┘
       │
       │ role = VENDOR
       ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                           VENDOR MODULE                                       │
└──────────────────────────────────────────────────────────────────────────────┘

┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│    stores    │      │   products   │      │  categories  │
├──────────────┤      ├──────────────┤      ├──────────────┤
│ id           │      │ id           │      │ id           │
│ user_id      │◄────►│ store_id     │◄────►│ name         │
│ name         │      │ category_id  │      │ parent_id    │
│ description  │      │ name         │      │ icon         │
│ logo_url     │      │ description  │      │ sort_order   │
│ banner_url   │      │ price        │      └──────────────┘
│ address      │      │ stock        │
│ latitude     │      │ images[]     │      ┌──────────────┐
│ longitude    │      │ is_active    │      │  campaigns   │
│ phone        │      │ min_images=2 │      ├──────────────┤
│ is_open      │      │ created_at   │      │ id           │
│ open_time    │      │ updated_at   │      │ store_id     │
│ close_time   │      │ last_sold_at │      │ product_id   │
│ is_approved  │      └──────────────┘      │ type         │
│ payment_types│                            │ value        │
│ iban         │                            │ start_date   │
│ rating       │                            │ end_date     │
│ created_at   │                            │ stock_limit  │
└──────────────┘                            │ is_active    │
       │                                    │ created_at   │
       │                                    └──────────────┘
       ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                            ORDER MODULE                                       │
└──────────────────────────────────────────────────────────────────────────────┘

┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│    orders    │      │ order_items  │      │order_timeline│
├──────────────┤      ├──────────────┤      ├──────────────┤
│ id           │      │ id           │      │ id           │
│ order_no     │◄────►│ order_id     │      │ order_id     │
│ user_id      │      │ product_id   │      │ status       │
│ store_id     │      │ quantity     │      │ note         │
│ courier_id   │      │ unit_price   │      │ created_at   │
│ status       │      │ total_price  │      │ created_by   │
│ total_amount │      │ campaign_id  │      └──────────────┘
│ delivery_fee │      └──────────────┘
│ address      │                            ┌──────────────┐
│ latitude     │                            │order_notif.  │
│ longitude    │                            ├──────────────┤
│ address_note │                            │ id           │
│ payment_type │                            │ order_id     │
│ payment_stat │                            │ type         │
│ notif_count  │                            │ sent_at      │
│ created_at   │                            │ response_at  │
│ accepted_at  │                            └──────────────┘
│ delivered_at │
└──────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│                            TAXI MODULE                                        │
└──────────────────────────────────────────────────────────────────────────────┘

┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│    drivers   │      │  taxi_rides  │      │ ride_timeline│
├──────────────┤      ├──────────────┤      ├──────────────┤
│ id           │      │ id           │      │ id           │
│ user_id      │◄────►│ user_id      │      │ ride_id      │
│ vehicle_plate│      │ driver_id    │      │ status       │
│ vehicle_model│      │ status       │      │ latitude     │
│ license_no   │      │ pickup_lat   │      │ longitude    │
│ is_online    │      │ pickup_lng   │      │ created_at   │
│ is_approved  │      │ pickup_addr  │      └──────────────┘
│ latitude     │      │ drop_lat     │
│ longitude    │      │ drop_lng     │      ┌──────────────┐
│ last_location│      │ drop_addr    │      │  ride_calls  │
│ rating       │      │ est_distance │      ├──────────────┤
│ daily_cancel │      │ est_duration │      │ id           │
│ total_rides  │      │ est_fare     │      │ ride_id      │
│ created_at   │      │ actual_fare  │      │ driver_id    │
└──────────────┘      │ created_at   │      │ status       │
                      │ started_at   │      │ sent_at      │
                      │ completed_at │      │ responded_at │
                      └──────────────┘      └──────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│                           COURIER MODULE                                      │
└──────────────────────────────────────────────────────────────────────────────┘

┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│   couriers   │      │  deliveries  │      │deliv_timeline│
├──────────────┤      ├──────────────┤      ├──────────────┤
│ id           │      │ id           │      │ id           │
│ user_id      │◄────►│ order_id     │      │ delivery_id  │
│ vehicle_type │      │ courier_id   │      │ status       │
│ is_online    │      │ status       │      │ latitude     │
│ is_approved  │      │ pickup_addr  │      │ longitude    │
│ latitude     │      │ pickup_lat   │      │ created_at   │
│ longitude    │      │ pickup_lng   │      └──────────────┘
│ last_location│      │ drop_addr    │
│ rating       │      │ drop_lat     │      ┌──────────────┐
│ daily_count  │      │ drop_lng     │      │deliv_assigns │
│ daily_reject │      │ est_duration │      ├──────────────┤
│ max_daily    │      │ picked_at    │      │ id           │
│ created_at   │      │ arrived_at   │      │ delivery_id  │
└──────────────┘      │ delivered_at │      │ courier_id   │
                      │ created_at   │      │ status       │
                      └──────────────┘      │ sent_at      │
                                            │ responded_at │
                                            └──────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│                            CHAT MODULE                                        │
└──────────────────────────────────────────────────────────────────────────────┘

┌──────────────┐      ┌──────────────┐
│    chats     │      │   messages   │
├──────────────┤      ├──────────────┤
│ id           │      │ id           │
│ type         │◄────►│ chat_id      │
│ order_id     │      │ sender_id    │
│ ride_id      │      │ content      │
│ user_id      │      │ is_read      │
│ partner_id   │      │ created_at   │
│ is_active    │      └──────────────┘
│ closed_at    │
│ created_at   │
└──────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│                           REVIEW MODULE                                       │
└──────────────────────────────────────────────────────────────────────────────┘

┌──────────────┐      ┌──────────────┐
│   reviews    │      │review_reports│
├──────────────┤      ├──────────────┤
│ id           │      │ id           │
│ user_id      │◄────►│ review_id    │
│ target_type  │      │ reporter_id  │
│ target_id    │      │ reason       │
│ order_id     │      │ created_at   │
│ ride_id      │      └──────────────┘
│ rating       │
│ comment      │
│ is_approved  │
│ created_at   │
└──────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│                           SUPPORT MODULE                                      │
└──────────────────────────────────────────────────────────────────────────────┘

┌──────────────┐      ┌──────────────┐
│   tickets    │      │ticket_replies│
├──────────────┤      ├──────────────┤
│ id           │      │ id           │
│ user_id      │◄────►│ ticket_id    │
│ type         │      │ user_id      │
│ order_id     │      │ content      │
│ ride_id      │      │ is_admin     │
│ delivery_id  │      │ created_at   │
│ subject      │      └──────────────┘
│ status       │
│ priority     │
│ assigned_to  │
│ created_at   │
│ resolved_at  │
└──────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│                         NOTIFICATION MODULE                                   │
└──────────────────────────────────────────────────────────────────────────────┘

┌──────────────┐      ┌──────────────┐
│notifications │      │  push_tokens │
├──────────────┤      ├──────────────┤
│ id           │      │ id           │
│ user_id      │◄────►│ user_id      │
│ type         │      │ token        │
│ title        │      │ platform     │
│ body         │      │ is_active    │
│ data         │      │ created_at   │
│ is_read      │      └──────────────┘
│ created_at   │
└──────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│                            ADMIN MODULE                                       │
└──────────────────────────────────────────────────────────────────────────────┘

┌──────────────┐      ┌──────────────┐
│  admin_logs  │      │   settings   │
├──────────────┤      ├──────────────┤
│ id           │      │ id           │
│ admin_id     │      │ key          │
│ action       │      │ value        │
│ target_type  │      │ city_id      │
│ target_id    │      │ updated_at   │
│ details      │      └──────────────┘
│ created_at   │
└──────────────┘
```

## Enum Tanımları

### User Roles

```sql
CREATE TYPE user_role AS ENUM (
  'USER',
  'VENDOR',
  'TAXI_DRIVER',
  'COURIER',
  'ADMIN',
  'SUPER_ADMIN'
);
```

### Order Status

```sql
CREATE TYPE order_status AS ENUM (
  'PENDING',           -- Beklemede
  'ACCEPTED',          -- Esnaf kabul etti
  'PREPARING',         -- Hazırlanıyor
  'READY',            -- Hazır
  'COURIER_ASSIGNED',  -- Kurye atandı
  'PICKED_UP',        -- Kurye aldı
  'DELIVERING',       -- Yolda
  'DELIVERED',        -- Teslim edildi
  'CANCELLED',        -- İptal
  'REJECTED'          -- Reddedildi
);
```

### Taxi Ride Status

```sql
CREATE TYPE ride_status AS ENUM (
  'SEARCHING',        -- Şoför aranıyor
  'DRIVER_ACCEPTED',  -- Şoför kabul etti
  'DRIVER_ARRIVING',  -- Şoför yolda
  'DRIVER_ARRIVED',   -- Şoför geldi
  'IN_PROGRESS',      -- Yolculuk başladı
  'COMPLETED',        -- Tamamlandı
  'CANCELLED',        -- İptal
  'NO_DRIVER'         -- Şoför bulunamadı
);
```

### Delivery Status

```sql
CREATE TYPE delivery_status AS ENUM (
  'PENDING',          -- Beklemede
  'ASSIGNED',         -- Kurye atandı
  'ACCEPTED',         -- Kurye kabul etti
  'PICKED_UP',        -- Teslim alındı
  'ARRIVING',         -- Binaya yaklaştı
  'DELIVERED',        -- Teslim edildi
  'FAILED',           -- Başarısız
  'CANCELLED'         -- İptal
);
```

### Campaign Types

```sql
CREATE TYPE campaign_type AS ENUM (
  'PERCENTAGE',       -- Yüzde indirim
  'FIXED_AMOUNT',     -- Sabit tutar
  'BUY_X_GET_Y',     -- X al Y öde
  'HAPPY_HOUR',      -- Saat bazlı
  'DAILY',           -- Günlük
  'WEEKLY'           -- Haftalık
);
```

### Payment Types

```sql
CREATE TYPE payment_type AS ENUM (
  'CASH',            -- Kapıda nakit
  'CARD',            -- Kapıda kart
  'IBAN',            -- Havale/EFT
  'ONLINE'           -- Online ödeme
);
```

### Ticket Types

```sql
CREATE TYPE ticket_type AS ENUM (
  'VENDOR_ISSUE',    -- Esnaf problemi
  'TAXI_ISSUE',      -- Taksi problemi
  'COURIER_ISSUE',   -- Kurye problemi
  'ORDER_ISSUE',     -- Sipariş problemi
  'PAYMENT_ISSUE',   -- Ödeme problemi
  'OTHER'            -- Diğer
);
```

## İndeksler

```sql
-- Users
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_city ON users(city_id);

-- Stores
CREATE INDEX idx_stores_user ON stores(user_id);
CREATE INDEX idx_stores_city ON stores(city_id);
CREATE INDEX idx_stores_location ON stores USING GIST (
  ll_to_earth(latitude, longitude)
);

-- Products
CREATE INDEX idx_products_store ON products(store_id);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_active ON products(is_active);

-- Orders
CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_store ON orders(store_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created ON orders(created_at DESC);

-- Drivers
CREATE INDEX idx_drivers_online ON drivers(is_online);
CREATE INDEX idx_drivers_location ON drivers USING GIST (
  ll_to_earth(latitude, longitude)
);

-- Taxi Rides
CREATE INDEX idx_rides_user ON taxi_rides(user_id);
CREATE INDEX idx_rides_driver ON taxi_rides(driver_id);
CREATE INDEX idx_rides_status ON taxi_rides(status);

-- Couriers
CREATE INDEX idx_couriers_online ON couriers(is_online);
CREATE INDEX idx_couriers_location ON couriers USING GIST (
  ll_to_earth(latitude, longitude)
);

-- Deliveries
CREATE INDEX idx_deliveries_order ON deliveries(order_id);
CREATE INDEX idx_deliveries_courier ON deliveries(courier_id);
CREATE INDEX idx_deliveries_status ON deliveries(status);
```

## Kritik Kurallar

### Stok Kontrolü (Trigger)

```sql
CREATE OR REPLACE FUNCTION check_stock_and_deactivate()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.stock = 0 THEN
    NEW.is_active = FALSE;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER product_stock_check
BEFORE UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION check_stock_and_deactivate();
```

### Sipariş Numarası (Sequence)

```sql
CREATE SEQUENCE order_number_seq START 1000;

CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TRIGGER AS $$
BEGIN
  NEW.order_no = 'BS' || TO_CHAR(NOW(), 'YYMMDD') ||
                 LPAD(nextval('order_number_seq')::TEXT, 6, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_order_number
BEFORE INSERT ON orders
FOR EACH ROW
EXECUTE FUNCTION generate_order_number();
```
