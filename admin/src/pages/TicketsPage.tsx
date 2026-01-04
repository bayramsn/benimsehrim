import { MessageCircle, Clock, CheckCircle, AlertCircle } from 'lucide-react'

export default function TicketsPage() {
  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold text-gray-800">Destek Talepleri</h2>
        <p className="text-gray-500">Müşteri destek taleplerini yönetin</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-3 gap-4">
        <div className="bg-white rounded-xl shadow-sm p-4 flex items-center gap-4">
          <div className="p-3 rounded-lg bg-yellow-100 text-yellow-600">
            <Clock size={24} />
          </div>
          <div>
            <p className="text-2xl font-bold">8</p>
            <p className="text-sm text-gray-500">Bekleyen</p>
          </div>
        </div>
        <div className="bg-white rounded-xl shadow-sm p-4 flex items-center gap-4">
          <div className="p-3 rounded-lg bg-blue-100 text-blue-600">
            <MessageCircle size={24} />
          </div>
          <div>
            <p className="text-2xl font-bold">5</p>
            <p className="text-sm text-gray-500">Yanıtlandı</p>
          </div>
        </div>
        <div className="bg-white rounded-xl shadow-sm p-4 flex items-center gap-4">
          <div className="p-3 rounded-lg bg-green-100 text-green-600">
            <CheckCircle size={24} />
          </div>
          <div>
            <p className="text-2xl font-bold">142</p>
            <p className="text-sm text-gray-500">Çözüldü</p>
          </div>
        </div>
      </div>

      {/* Tickets List */}
      <div className="bg-white rounded-xl shadow-sm overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50 border-b">
            <tr>
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Ticket No</th>
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Konu</th>
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Kullanıcı</th>
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Tür</th>
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Durum</th>
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Tarih</th>
            </tr>
          </thead>
          <tbody className="divide-y">
            {mockTickets.map((ticket) => (
              <tr key={ticket.id} className="hover:bg-gray-50 cursor-pointer">
                <td className="px-6 py-4 font-mono text-sm">{ticket.ticketNo}</td>
                <td className="px-6 py-4">
                  <div className="flex items-center gap-2">
                    {ticket.status === 'OPEN' && <AlertCircle size={16} className="text-yellow-500" />}
                    <span>{ticket.subject}</span>
                  </div>
                </td>
                <td className="px-6 py-4">{ticket.userName}</td>
                <td className="px-6 py-4">
                  <span className="px-2 py-1 bg-gray-100 rounded text-sm">{ticket.type}</span>
                </td>
                <td className="px-6 py-4">
                  <span className={`px-3 py-1 rounded-full text-sm font-medium ${getStatusColor(ticket.status)}`}>
                    {getStatusText(ticket.status)}
                  </span>
                </td>
                <td className="px-6 py-4 text-gray-500">{ticket.date}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}

function getStatusColor(status: string) {
  switch (status) {
    case 'OPEN': return 'bg-yellow-100 text-yellow-700'
    case 'IN_PROGRESS': return 'bg-blue-100 text-blue-700'
    case 'RESOLVED': return 'bg-green-100 text-green-700'
    default: return 'bg-gray-100 text-gray-700'
  }
}

function getStatusText(status: string) {
  switch (status) {
    case 'OPEN': return 'Açık'
    case 'IN_PROGRESS': return 'İşleniyor'
    case 'RESOLVED': return 'Çözüldü'
    default: return status
  }
}

const mockTickets = [
  { id: '1', ticketNo: 'TKT-2024-000001', subject: 'Siparişim teslim edilmedi', userName: 'Ahmet Yılmaz', type: 'ORDER', status: 'OPEN', date: '28.12.2024 14:30' },
  { id: '2', ticketNo: 'TKT-2024-000002', subject: 'Yanlış ürün geldi', userName: 'Mehmet Demir', type: 'ORDER', status: 'IN_PROGRESS', date: '28.12.2024 13:15' },
  { id: '3', ticketNo: 'TKT-2024-000003', subject: 'Taksi şoförü ile sorun', userName: 'Ayşe Kaya', type: 'RIDE', status: 'RESOLVED', date: '27.12.2024 18:00' },
]
