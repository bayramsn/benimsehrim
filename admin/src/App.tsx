import { Routes, Route, Navigate } from 'react-router-dom'
import { useAuthStore } from '@/store/authStore'
import Layout from '@/components/Layout'
import LoginPage from '@/pages/LoginPage'
import DashboardPage from '@/pages/DashboardPage'
import VendorsPage from '@/pages/VendorsPage'
import DriversPage from '@/pages/DriversPage'
import CouriersPage from '@/pages/CouriersPage'
import OrdersPage from '@/pages/OrdersPage'
import ReviewsPage from '@/pages/ReviewsPage'
import TicketsPage from '@/pages/TicketsPage'

function App() {
  const { isLoggedIn } = useAuthStore()

  if (!isLoggedIn) {
    return (
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="*" element={<Navigate to="/login" replace />} />
      </Routes>
    )
  }

  return (
    <Layout>
      <Routes>
        <Route path="/" element={<DashboardPage />} />
        <Route path="/vendors" element={<VendorsPage />} />
        <Route path="/drivers" element={<DriversPage />} />
        <Route path="/couriers" element={<CouriersPage />} />
        <Route path="/orders" element={<OrdersPage />} />
        <Route path="/reviews" element={<ReviewsPage />} />
        <Route path="/tickets" element={<TicketsPage />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </Layout>
  )
}

export default App
