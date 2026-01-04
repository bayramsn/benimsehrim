import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { adminApi } from '@/lib/api'
import { Check, X, Car, Star } from 'lucide-react'

export default function DriversPage() {
  const [filter, setFilter] = useState<'all' | 'pending' | 'approved'>('all')
  const queryClient = useQueryClient()

  const { data: drivers = [] } = useQuery({
    queryKey: ['drivers', filter],
    queryFn: () =>
      adminApi.getDrivers(filter === 'all' ? undefined : filter).then((res) => res.data),
    placeholderData: mockDrivers,
  })

  const approveMutation = useMutation({
    mutationFn: ({ id, approve }: { id: string; approve: boolean }) =>
      adminApi.approveDriver(id, approve),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['drivers'] })
    },
  })

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-gray-800">Şoför Yönetimi</h2>
          <p className="text-gray-500">Şoför başvurularını inceleyin ve onaylayın</p>
        </div>

        <div className="flex gap-2">
          {(['all', 'pending', 'approved'] as const).map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`px-4 py-2 rounded-lg font-medium transition-colors ${
                filter === f
                  ? 'bg-primary-500 text-white'
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
              }`}
            >
              {f === 'all' ? 'Tümü' : f === 'pending' ? 'Bekleyen' : 'Onaylı'}
            </button>
          ))}
        </div>
      </div>

      <div className="bg-white rounded-xl shadow-sm overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50 border-b">
            <tr>
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Şoför</th>
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Araç</th>
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Telefon</th>
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Puan</th>
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Durum</th>
              <th className="px-6 py-4 text-right text-sm font-semibold text-gray-600">İşlemler</th>
            </tr>
          </thead>
          <tbody className="divide-y">
            {drivers.map((driver: any) => (
              <tr key={driver.id} className="hover:bg-gray-50">
                <td className="px-6 py-4">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
                      <Car className="text-green-500" size={20} />
                    </div>
                    <p className="font-medium text-gray-800">{driver.user?.name}</p>
                  </div>
                </td>
                <td className="px-6 py-4 text-gray-600">
                  {driver.vehiclePlate} - {driver.vehicleModel}
                </td>
                <td className="px-6 py-4 text-gray-600">{driver.user?.phone}</td>
                <td className="px-6 py-4">
                  <div className="flex items-center gap-1">
                    <Star className="text-yellow-400" size={16} fill="currentColor" />
                    <span className="font-medium">{driver.rating?.toFixed(1) || '0.0'}</span>
                  </div>
                </td>
                <td className="px-6 py-4">
                  <span
                    className={`px-3 py-1 rounded-full text-sm font-medium ${
                      driver.isApproved
                        ? 'bg-green-100 text-green-700'
                        : 'bg-yellow-100 text-yellow-700'
                    }`}
                  >
                    {driver.isApproved ? 'Onaylı' : 'Bekliyor'}
                  </span>
                </td>
                <td className="px-6 py-4">
                  <div className="flex items-center justify-end gap-2">
                    {!driver.isApproved && (
                      <>
                        <button
                          onClick={() => approveMutation.mutate({ id: driver.id, approve: true })}
                          className="p-2 bg-green-100 text-green-600 rounded-lg hover:bg-green-200"
                        >
                          <Check size={18} />
                        </button>
                        <button
                          onClick={() => approveMutation.mutate({ id: driver.id, approve: false })}
                          className="p-2 bg-red-100 text-red-600 rounded-lg hover:bg-red-200"
                        >
                          <X size={18} />
                        </button>
                      </>
                    )}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}

const mockDrivers = [
  {
    id: '1',
    user: { name: 'Ali Şoför', phone: '+905001234569' },
    vehiclePlate: '40 ABC 123',
    vehicleModel: 'Toyota Corolla',
    rating: 4.7,
    isApproved: false,
  },
  {
    id: '2',
    user: { name: 'Veli Şoför', phone: '+905001234570' },
    vehiclePlate: '40 DEF 456',
    vehicleModel: 'Fiat Egea',
    rating: 4.9,
    isApproved: true,
  },
]
