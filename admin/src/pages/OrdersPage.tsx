import { ShoppingBag, Clock, Truck, CheckCircle } from 'lucide-react'

export default function OrdersPage() {
  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold text-gray-800">Siparişler</h2>
        <p className="text-gray-500">Tüm siparişleri görüntüleyin ve yönetin</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-4 gap-4">
        <StatCard icon={Clock} label="Bekleyen" value={12} color="yellow" />
        <StatCard icon={ShoppingBag} label="Hazırlanıyor" value={8} color="blue" />
        <StatCard icon={Truck} label="Yolda" value={15} color="orange" />
        <StatCard icon={CheckCircle} label="Tamamlanan" value={156} color="green" />
      </div>

      {/* Orders Table */}
      <div className="bg-white rounded-xl shadow-sm overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50 border-b">
            <tr>
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Sipariş No</th>
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Mağaza</th>
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Müşteri</th>
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Tutar</th>
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Durum</th>
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Tarih</th>
            </tr>
          </thead>
          <tbody className="divide-y">
            {mockOrders.map((order) => (
              <tr key={order.id} className="hover:bg-gray-50">
                <td className="px-6 py-4 font-mono text-sm">{order.orderNo}</td>
                <td className="px-6 py-4">{order.storeName}</td>
                <td className="px-6 py-4">{order.customerName}</td>
                <td className="px-6 py-4 font-semibold">{order.total}₺</td>
                <td className="px-6 py-4">
                  <span className={`px-3 py-1 rounded-full text-sm font-medium ${getStatusColor(order.status)}`}>
                    {getStatusText(order.status)}
                  </span>
                </td>
                <td className="px-6 py-4 text-gray-500">{order.date}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}

function StatCard({
  icon: Icon,
  label,
  value,
  color,
}: {
  icon: any
  label: string
  value: number
  color: string
}) {
  const colors = {
    yellow: 'bg-yellow-100 text-yellow-600',
    blue: 'bg-blue-100 text-blue-600',
    orange: 'bg-orange-100 text-orange-600',
    green: 'bg-green-100 text-green-600',
  }

  return (
    <div className="bg-white rounded-xl shadow-sm p-4 flex items-center gap-4">
      <div className={`p-3 rounded-lg ${colors[color as keyof typeof colors]}`}>
        <Icon size={24} />
      </div>
      <div>
        <p className="text-2xl font-bold">{value}</p>
        <p className="text-sm text-gray-500">{label}</p>
      </div>
    </div>
  )
}

function getStatusColor(status: string) {
  switch (status) {
    case 'PENDING': return 'bg-yellow-100 text-yellow-700'
    case 'PREPARING': return 'bg-blue-100 text-blue-700'
    case 'ON_WAY': return 'bg-orange-100 text-orange-700'
    case 'DELIVERED': return 'bg-green-100 text-green-700'
    default: return 'bg-gray-100 text-gray-700'
  }
}

function getStatusText(status: string) {
  switch (status) {
    case 'PENDING': return 'Bekliyor'
    case 'PREPARING': return 'Hazırlanıyor'
    case 'ON_WAY': return 'Yolda'
    case 'DELIVERED': return 'Teslim Edildi'
    default: return status
  }
}

const mockOrders = [
  { id: '1', orderNo: 'ORD-2024-000001', storeName: 'Merkez Kasap', customerName: 'Ahmet Yılmaz', total: 245, status: 'PENDING', date: '28.12.2024 14:30' },
  { id: '2', orderNo: 'ORD-2024-000002', storeName: 'Şehir Fırını', customerName: 'Mehmet Demir', total: 85, status: 'PREPARING', date: '28.12.2024 14:15' },
  { id: '3', orderNo: 'ORD-2024-000003', storeName: 'Merkez Market', customerName: 'Ayşe Kaya', total: 320, status: 'ON_WAY', date: '28.12.2024 14:00' },
  { id: '4', orderNo: 'ORD-2024-000004', storeName: 'Lezzet Cafe', customerName: 'Fatma Şahin', total: 75, status: 'DELIVERED', date: '28.12.2024 13:30' },
]
