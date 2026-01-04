# 🏗️ Sistem Mimarisi

## Clean Architecture Yapısı

```
┌─────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Android   │  │     iOS     │  │    Admin Panel      │  │
│  │   Compose   │  │   SwiftUI   │  │      (React)        │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      API GATEWAY LAYER                       │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              NestJS REST API + WebSocket              │   │
│  │         JWT Auth │ Rate Limiting │ Validation         │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    APPLICATION LAYER                         │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │   User   │ │  Vendor  │ │   Taxi   │ │  Courier │       │
│  │  Module  │ │  Module  │ │  Module  │ │  Module  │       │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘       │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │  Order   │ │ Campaign │ │   Chat   │ │  Review  │       │
│  │  Module  │ │  Module  │ │  Module  │ │  Module  │       │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘       │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐                    │
│  │  Admin   │ │ Location │ │  Notif.  │                    │
│  │  Module  │ │  Module  │ │  Module  │                    │
│  └──────────┘ └──────────┘ └──────────┘                    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     DOMAIN LAYER                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Entities │ Value Objects │ Domain Events │ Rules   │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  INFRASTRUCTURE LAYER                        │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │PostgreSQL│ │  Redis   │ │ Firebase │ │   S3     │       │
│  │ (Prisma) │ │ (Cache)  │ │ (Push)   │ │ (Files)  │       │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘       │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐                    │
│  │  Twilio  │ │ WhatsApp │ │  Maps    │                    │
│  │  (SMS)   │ │   API    │ │   API    │                    │
│  └──────────┘ └──────────┘ └──────────┘                    │
└─────────────────────────────────────────────────────────────┘
```

## Modül İletişim Akışları

### Sipariş Akışı

```
Kullanıcı → OrderModule → VendorModule → NotificationModule
                ↓
         CourierModule (teslimat ataması)
                ↓
         LocationModule (canlı takip)
                ↓
         ReviewModule (değerlendirme)
```

### Taksi Çağrı Akışı

```
Kullanıcı → TaxiModule → LocationModule
                ↓
         NotificationModule (push to drivers)
                ↓
         ChatModule (iletişim)
                ↓
         ReviewModule (değerlendirme)
```

## Operasyonel Otomasyon Mimarisi

### Event-Driven Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     EVENT BUS (Redis)                        │
└─────────────────────────────────────────────────────────────┘
       │              │              │              │
       ▼              ▼              ▼              ▼
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│  Order   │   │  Taxi    │   │ Courier  │   │  Alert   │
│ Timeout  │   │ Timeout  │   │ Timeout  │   │  Handler │
│ Handler  │   │ Handler  │   │ Handler  │   │          │
└──────────┘   └──────────┘   └──────────┘   └──────────┘
```

### Timeout & Escalation Rules

| Event        | 1. Adım   | 2. Adım   | 3. Adım         | Final                  |
| ------------ | --------- | --------- | --------------- | ---------------------- |
| Yeni Sipariş | Push (0s) | SMS (60s) | WhatsApp (120s) | İptal/Yönlendir (180s) |
| Taksi Çağrı  | Push (0s) | -         | -               | Başka Taksi (30s)      |
| Kurye Görevi | Push (0s) | -         | -               | Başka Kurye (20s)      |

## Ölçeklenebilirlik Stratejisi

### Horizontal Scaling

```
                    Load Balancer
                         │
         ┌───────────────┼───────────────┐
         ▼               ▼               ▼
    ┌─────────┐     ┌─────────┐     ┌─────────┐
    │ API #1  │     │ API #2  │     │ API #3  │
    └─────────┘     └─────────┘     └─────────┘
         │               │               │
         └───────────────┼───────────────┘
                         ▼
                ┌─────────────────┐
                │   PostgreSQL    │
                │   (Primary)     │
                └─────────────────┘
                         │
              ┌──────────┴──────────┐
              ▼                     ▼
      ┌──────────────┐      ┌──────────────┐
      │   Replica 1  │      │   Replica 2  │
      └──────────────┘      └──────────────┘
```

### Şehir Bazlı Deployment

```
┌─────────────────────────────────────────────────────────────┐
│                    GLOBAL SERVICES                           │
│           (Auth, Admin, Analytics, CDN)                      │
└─────────────────────────────────────────────────────────────┘
                              │
         ┌────────────────────┼────────────────────┐
         ▼                    ▼                    ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│    Kırşehir     │  │     Ankara      │  │    İstanbul     │
│    Cluster      │  │    Cluster      │  │    Cluster      │
│                 │  │                 │  │                 │
│ • Local DB      │  │ • Local DB      │  │ • Local DB      │
│ • Local Cache   │  │ • Local Cache   │  │ • Local Cache   │
│ • Local Storage │  │ • Local Storage │  │ • Local Storage │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

## Güvenlik Katmanları

```
┌─────────────────────────────────────────────────────────────┐
│ Layer 1: WAF (Web Application Firewall)                      │
├─────────────────────────────────────────────────────────────┤
│ Layer 2: Rate Limiting (Redis)                               │
├─────────────────────────────────────────────────────────────┤
│ Layer 3: JWT Validation + Role Check                         │
├─────────────────────────────────────────────────────────────┤
│ Layer 4: Request Validation (class-validator)                │
├─────────────────────────────────────────────────────────────┤
│ Layer 5: Business Logic Authorization                        │
├─────────────────────────────────────────────────────────────┤
│ Layer 6: Database Row-Level Security                         │
└─────────────────────────────────────────────────────────────┘
```

## Monitoring & Alerting

```
┌─────────────────────────────────────────────────────────────┐
│                     OBSERVABILITY STACK                      │
│                                                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │  Logs    │ │ Metrics  │ │  Traces  │ │  Alerts  │       │
│  │ (ELK)   │ │(Prometheus│ │ (Jaeger) │ │(PagerDuty│       │
│  │          │ │ Grafana) │ │          │ │          │       │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘       │
└─────────────────────────────────────────────────────────────┘
```
