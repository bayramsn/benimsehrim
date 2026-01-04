# Benim Şehrim - Admin Panel

Modern React admin dashboard for managing the Benim Şehrim platform.

## 🚀 Quick Start

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build
```

## 📁 Project Structure

```
admin/
├── src/
│   ├── components/
│   │   └── Layout.tsx          # Main layout with sidebar
│   ├── lib/
│   │   └── api.ts              # Axios API client
│   ├── pages/
│   │   ├── LoginPage.tsx
│   │   ├── DashboardPage.tsx   # Stats & charts
│   │   ├── VendorsPage.tsx     # Vendor management
│   │   ├── DriversPage.tsx     # Driver management
│   │   ├── CouriersPage.tsx    # Courier management
│   │   ├── OrdersPage.tsx      # Orders view
│   │   ├── ReviewsPage.tsx     # Review moderation
│   │   └── TicketsPage.tsx     # Support tickets
│   ├── store/
│   │   └── authStore.ts        # Zustand auth state
│   ├── App.tsx
│   ├── main.tsx
│   └── index.css
├── tailwind.config.js
├── vite.config.ts
└── package.json
```

## ✨ Features

- **Dashboard**: Real-time stats, charts, and alerts
- **Vendor Management**: Approve/reject vendor applications
- **Driver Management**: Manage taxi drivers
- **Courier Management**: Manage delivery couriers
- **Orders**: View and track all orders
- **Reviews**: Moderate user reviews
- **Support**: Handle support tickets

## 🎨 Tech Stack

- React 18 + TypeScript
- Vite (build tool)
- TailwindCSS (styling)
- React Query (data fetching)
- Zustand (state management)
- React Router v6 (routing)
- Recharts (charts)
- Lucide React (icons)

## 🔐 Demo Login

- Phone: Any 10+ digits
- OTP: `123456`
