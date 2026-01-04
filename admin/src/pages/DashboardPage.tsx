import { useQuery } from '@tanstack/react-query'
import { adminApi } from '@/lib/api'
import {
  ShoppingBag,
  Car,
  Users,
  TrendingUp,
  AlertTriangle,
  Clock,
  Star,
} from 'lucide-react'
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts'

// Mock data for chart
const chartData = [
  { name: 'Pzt', orders: 40, revenue: 2400 },
  { name: 'Sal', orders: 30, revenue: 1398 },
  { name: 'Çar', orders: 45, revenue: 3800 },
  { name: 'Per', orders: 50, revenue: 4300 },
  { name: 'Cum', orders: 65, revenue: 6200 },
  { name: 'Cmt', orders: 80, revenue: 8100 },
  { name: 'Paz', orders: 70, revenue: 7200 },
]

export default function DashboardPage() {
  const { data: dashboard } = useQuery({
    queryKey: ['dashboard'],
    queryFn: () => adminApi.getDashboard().then((res) => res.data),
    // Use mock data if API fails
    placeholderData: {
      today: { orders: 45, rides: 23, revenue: 8500, newUsers: 12 },
      alerts: { pendingApprovals: 5, lowRatedVendors: 2, highCancelDrivers: 1 },
    },
  })

  return (
    <div className="space-y-6">
      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard
          title="Bugünkü Siparişler"
          value={dashboard?.today?.orders || 0}
          icon={ShoppingBag}
          color="bg-blue-500"
          change="+12%"
        />
        <StatCard
          title="Bugünkü Yolculuklar"
          value={dashboard?.today?.rides || 0}
          icon={Car}
          color="bg-green-500"
          change="+8%"
        />
        <StatCard
          title="Bugünkü Gelir"
          value={`${(dashboard?.today?.revenue || 0).toLocaleString()}₺`}
          icon={TrendingUp}
          color="bg-purple-500"
          change="+15%"
        />
        <StatCard
          title="Yeni Kullanıcılar"
          value={dashboard?.today?.newUsers || 0}
          icon={Users}
          color="bg-orange-500"
          change="+5%"
        />
      </div>

      {/* Charts & Alerts */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Chart */}
        <div className="lg:col-span-2 bg-white rounded-xl shadow-sm p-6">
          <h3 className="text-lg font-semibold mb-4">Haftalık Özet</h3>
          <ResponsiveContainer width="100%" height={300}>
            <AreaChart data={chartData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="name" />
              <YAxis />
              <Tooltip />
              <Area
                type="monotone"
                dataKey="orders"
                stackId="1"
                stroke="#006E24"
                fill="#006E24"
                fillOpacity={0.6}
              />
              <Area
                type="monotone"
                dataKey="revenue"
                stackId="2"
                stroke="#8C4E00"
                fill="#FFB74D"
                fillOpacity={0.6}
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        {/* Alerts */}
        <div className="bg-white rounded-xl shadow-sm p-6">
          <h3 className="text-lg font-semibold mb-4">⚠️ Dikkat Edilmesi Gerekenler</h3>
          <div className="space-y-4">
            <AlertItem
              icon={Clock}
              title="Bekleyen Onaylar"
              value={dashboard?.alerts?.pendingApprovals || 0}
              color="text-yellow-500"
            />
            <AlertItem
              icon={Star}
              title="Düşük Puanlı Esnaflar"
              value={dashboard?.alerts?.lowRatedVendors || 0}
              color="text-red-500"
            />
            <AlertItem
              icon={AlertTriangle}
              title="Yüksek İptal Oranı"
              value={dashboard?.alerts?.highCancelDrivers || 0}
              color="text-orange-500"
            />
          </div>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="bg-white rounded-xl shadow-sm p-6">
        <h3 className="text-lg font-semibold mb-4">Hızlı İşlemler</h3>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <QuickAction label="Esnaf Onayla" href="/vendors" color="bg-blue-100 text-blue-700" />
          <QuickAction label="Şoför Onayla" href="/drivers" color="bg-green-100 text-green-700" />
          <QuickAction label="Yorumları İncele" href="/reviews" color="bg-yellow-100 text-yellow-700" />
          <QuickAction label="Destek Talepleri" href="/tickets" color="bg-purple-100 text-purple-700" />
        </div>
      </div>
    </div>
  )
}

function StatCard({
  title,
  value,
  icon: Icon,
  color,
  change,
}: {
  title: string
  value: string | number
  icon: any
  color: string
  change: string
}) {
  return (
    <div className="bg-white rounded-xl shadow-sm p-6">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm text-gray-500">{title}</p>
          <p className="text-2xl font-bold mt-1">{value}</p>
          <span className="text-sm text-green-500">{change}</span>
        </div>
        <div className={`${color} p-3 rounded-lg`}>
          <Icon className="text-white" size={24} />
        </div>
      </div>
    </div>
  )
}

function AlertItem({
  icon: Icon,
  title,
  value,
  color,
}: {
  icon: any
  title: string
  value: number
  color: string
}) {
  return (
    <div className="flex items-center gap-3 p-3 bg-gray-50 rounded-lg">
      <Icon className={color} size={20} />
      <div className="flex-1">
        <p className="text-sm font-medium">{title}</p>
      </div>
      <span className="text-lg font-bold">{value}</span>
    </div>
  )
}

function QuickAction({
  label,
  href,
  color,
}: {
  label: string
  href: string
  color: string
}) {
  return (
    <a
      href={href}
      className={`${color} p-4 rounded-lg text-center font-medium hover:opacity-80 transition-opacity`}
    >
      {label}
    </a>
  )
}
