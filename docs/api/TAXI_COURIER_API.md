# 🚕 Taxi & 📦 Courier API

## Taxi Endpoints

### POST /taxi/estimate

Tahmini ücret hesapla

**Request:**

```json
{
  "pickup_latitude": 39.1425,
  "pickup_longitude": 34.1709,
  "drop_latitude": 39.15,
  "drop_longitude": 34.18
}
```

**Response 200:**

```json
{
  "distance": 2.5,
  "duration": 8,
  "estimated_fare": { "min": 45.0, "max": 55.0 },
  "nearby_drivers": 3
}
```

---

### POST /taxi/request

Taksi çağır

**Request:**

```json
{
  "pickup_latitude": 39.1425,
  "pickup_longitude": 34.1709,
  "pickup_address": "Atatürk Cad. No:45",
  "drop_latitude": 39.15,
  "drop_longitude": 34.18,
  "drop_address": "Terminal"
}
```

**Response 201:**

```json
{
  "id": "uuid",
  "status": "SEARCHING",
  "search_timeout": 30
}
```

---

### GET /taxi/rides/:id

Yolculuk detayı

**Response 200:**

```json
{
  "id": "uuid",
  "status": "DRIVER_ARRIVING",
  "driver": {
    "name": "Ali Şoför",
    "phone": "+905...",
    "rating": 4.8,
    "vehicle": { "plate": "40 ABC 123", "model": "Fiat Egea" },
    "latitude": 39.14,
    "longitude": 34.17,
    "eta": 3
  },
  "chat_enabled": true
}
```

---

### PUT /driver/status (Driver Only)

```json
{ "is_online": true, "latitude": 39.14, "longitude": 34.17 }
```

### PUT /driver/rides/:id/respond (Driver Only)

```json
{ "action": "ACCEPT | REJECT" }
```

---

## Courier Endpoints

### GET /courier/deliveries (Courier Only)

Görev listesi

**Response 200:**

```json
{
  "data": [
    {
      "id": "uuid",
      "order": { "order_no": "BS241228001234" },
      "pickup": { "address": "...", "latitude": 39.14 },
      "drop": { "address": "...", "note": "Sarı bina" },
      "status": "ASSIGNED",
      "deadline": "2024-01-01T12:45:00Z",
      "remaining_time": 1800
    }
  ]
}
```

---

### PUT /courier/deliveries/:id/status (Courier Only)

```json
{
  "status": "ACCEPTED | PICKED_UP | ARRIVING | DELIVERED | FAILED",
  "latitude": 39.14,
  "longitude": 34.17
}
```

### PUT /courier/location (Courier Only)

```json
{ "latitude": 39.14, "longitude": 34.17 }
```

---

## WebSocket Events

```javascript
// Konum güncelleme
socket.emit("location:update", { lat: 39.14, lng: 34.17 });

// Dinleme
socket.on("order:status", (data) => {});
socket.on("ride:status", (data) => {});
socket.on("chat:message", (data) => {});
socket.on("vendor:new_order", (data) => {});
socket.on("driver:new_ride", (data) => {});
socket.on("courier:new_delivery", (data) => {});
```
