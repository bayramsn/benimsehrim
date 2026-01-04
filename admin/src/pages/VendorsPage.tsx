import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { adminApi } from '@/lib/api'
import { Check, X, Store, Star } from 'lucide-react'

export default function VendorsPage() {
  const [filter, setFilter] = useState<'all' | 'pending' | 'approved'>('all')
  const queryClient = useQueryClient()

  const { data: vendors = [], isLoading } = useQuery({
    queryKey: ['vendors', filter],
    queryFn: () =>
      adminApi.getVendors(filter === 'all' ? undefined : filter).then((res) => res.data),
    placeholderData: mockVendors,
  })

  const approveMutation = useMutation({
    mutationFn: ({ id, approve }: { id: string; approve: boolean }) =>
      adminApi.approveVendor(id, approve),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['vendors'] })
    },
  })

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-gray-800">Esnaf Yönetimi</h2>
          <p className="text-gray-500">Esnaf başvurularını inceleyin ve onaylayın</p>
        </div>

        {/* Filter */}
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

      {/* Table */}
      <div className="bg-white rounded-xl shadow-sm overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50 border-b">
            <tr>
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Mağaza</th>
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Sahibi</th>
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Telefon</th>
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Puan</th>
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Durum</th>
              <th className="px-6 py-4 text-right text-sm font-semibold text-gray-600">İşlemler</th>
            </tr>
          </thead>
          <tbody className="divide-y">
            {isLoading ? (
              <tr>
                <td colSpan={6} className="px-6 py-8 text-center text-gray-500">
                  Yükleniyor...
                </td>
              </tr>
            ) : vendors.length === 0 ? (
              <tr>
                <td colSpan={6} className="px-6 py-8 text-center text-gray-500">
                  Esnaf bulunamadı
                </td>
              </tr>
            ) : (
              vendors.map((vendor: any) => (
                <tr key={vendor.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 bg-primary-100 rounded-lg flex items-center justify-center">
                        <Store className="text-primary-500" size={20} />
                      </div>
                      <div>
                        <p className="font-medium text-gray-800">{vendor.name}</p>
                        <p className="text-sm text-gray-500">{vendor.address}</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 text-gray-600">{vendor.user?.name || '-'}</td>
                  <td className="px-6 py-4 text-gray-600">{vendor.user?.phone || '-'}</td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-1">
                      <Star className="text-yellow-400" size={16} fill="currentColor" />
                      <span className="font-medium">{vendor.rating?.toFixed(1) || '0.0'}</span>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <span
                      className={`px-3 py-1 rounded-full text-sm font-medium ${
                        vendor.isApproved
                          ? 'bg-green-100 text-green-700'
                          : 'bg-yellow-100 text-yellow-700'
                      }`}
                    >
                      {vendor.isApproved ? 'Onaylı' : 'Bekliyor'}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center justify-end gap-2">
                      {!vendor.isApproved && (
                        <>
                          <button
                            onClick={() => approveMutation.mutate({ id: vendor.id, approve: true })}
                            className="p-2 bg-green-100 text-green-600 rounded-lg hover:bg-green-200"
                            title="Onayla"
                          >
                            <Check size={18} />
                          </button>
                          <button
                            onClick={() => approveMutation.mutate({ id: vendor.id, approve: false })}
                            className="p-2 bg-red-100 text-red-600 rounded-lg hover:bg-red-200"
                            title="Reddet"
                          >
                            <X size={18} />
                          </button>
                        </>
                      )}
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}

// Mock data
const mockVendors = [
  {
    id: '1',
    name: 'Merkez Kasap',
    address: 'Kırşehir Merkez',
    user: { name: 'Ahmet Yılmaz', phone: '+905001234567' },
    rating: 4.5,
    isApproved: false,
  },
  {
    id: '2',
    name: 'Şehir Fırını',
    address: 'Kırşehir Merkez',
    user: { name: 'Mehmet Demir', phone: '+905001234568' },
    rating: 4.8,
    isApproved: true,
  },
]
