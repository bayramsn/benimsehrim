import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { adminApi } from '@/lib/api'
import { Check, X, Bike, Star } from 'lucide-react'

export default function CouriersPage() {
  const [filter, setFilter] = useState<'all' | 'pending' | 'approved'>('all')
  const queryClient = useQueryClient()

  const { data: couriers = [] } = useQuery({
    queryKey: ['couriers', filter],
    queryFn: () =>
      adminApi.getCouriers(filter === 'all' ? undefined : filter).then((res) => res.data),
    placeholderData: mockCouriers,
  })

  const approveMutation = useMutation({
    mutationFn: ({ id, approve }: { id: string; approve: boolean }) =>
      adminApi.approveCourier(id, approve),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['couriers'] })
    },
  })

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-gray-800">Kurye Yönetimi</h2>
          <p className="text-gray-500">Kurye başvurularını inceleyin ve onaylayın</p>
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
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Kurye</th>
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Araç Tipi</th>
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Telefon</th>
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Puan</th>
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Durum</th>
              <th className="px-6 py-4 text-right text-sm font-semibold text-gray-600">İşlemler</th>
            </tr>
          </thead>
          <tbody className="divide-y">
            {couriers.map((courier: any) => (
              <tr key={courier.id} className="hover:bg-gray-50">
                <td className="px-6 py-4">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-orange-100 rounded-lg flex items-center justify-center">
                      <Bike className="text-orange-500" size={20} />
                    </div>
                    <p className="font-medium text-gray-800">{courier.user?.name}</p>
                  </div>
                </td>
                <td className="px-6 py-4 text-gray-600">{courier.vehicleType}</td>
                <td className="px-6 py-4 text-gray-600">{courier.user?.phone}</td>
                <td className="px-6 py-4">
                  <div className="flex items-center gap-1">
                    <Star className="text-yellow-400" size={16} fill="currentColor" />
                    <span className="font-medium">{courier.rating?.toFixed(1) || '0.0'}</span>
                  </div>
                </td>
                <td className="px-6 py-4">
                  <span
                    className={`px-3 py-1 rounded-full text-sm font-medium ${
                      courier.isApproved
                        ? 'bg-green-100 text-green-700'
                        : 'bg-yellow-100 text-yellow-700'
                    }`}
                  >
                    {courier.isApproved ? 'Onaylı' : 'Bekliyor'}
                  </span>
                </td>
                <td className="px-6 py-4">
                  <div className="flex items-center justify-end gap-2">
                    {!courier.isApproved && (
                      <>
                        <button
                          onClick={() => approveMutation.mutate({ id: courier.id, approve: true })}
                          className="p-2 bg-green-100 text-green-600 rounded-lg hover:bg-green-200"
                        >
                          <Check size={18} />
                        </button>
                        <button
                          onClick={() => approveMutation.mutate({ id: courier.id, approve: false })}
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

const mockCouriers = [
  {
    id: '1',
    user: { name: 'Kurye Ali', phone: '+905001234571' },
    vehicleType: 'Motosiklet',
    rating: 4.6,
    isApproved: false,
  },
  {
    id: '2',
    user: { name: 'Kurye Veli', phone: '+905001234572' },
    vehicleType: 'Bisiklet',
    rating: 4.8,
    isApproved: true,
  },
]
