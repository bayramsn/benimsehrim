import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { adminApi } from '@/lib/api'
import { Check, X, Star } from 'lucide-react'

export default function ReviewsPage() {
  const queryClient = useQueryClient()

  const { data: reviews = [] } = useQuery({
    queryKey: ['pending-reviews'],
    queryFn: () => adminApi.getPendingReviews().then((res) => res.data),
    placeholderData: mockReviews,
  })

  const approveMutation = useMutation({
    mutationFn: (id: string) => adminApi.approveReview(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['pending-reviews'] }),
  })

  const rejectMutation = useMutation({
    mutationFn: (id: string) => adminApi.rejectReview(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['pending-reviews'] }),
  })

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold text-gray-800">Yorum Moderasyonu</h2>
        <p className="text-gray-500">Bekleyen yorumları inceleyin ve onaylayın</p>
      </div>

      <div className="grid gap-4">
        {reviews.length === 0 ? (
          <div className="bg-white rounded-xl shadow-sm p-12 text-center">
            <p className="text-gray-500">Bekleyen yorum bulunmuyor</p>
          </div>
        ) : (
          reviews.map((review: any) => (
            <div key={review.id} className="bg-white rounded-xl shadow-sm p-6">
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <div className="flex items-center gap-3 mb-2">
                    <span className="font-medium">{review.user?.name || 'Anonim'}</span>
                    <span className="text-gray-400">→</span>
                    <span className="text-gray-600">{review.targetName}</span>
                  </div>

                  <div className="flex items-center gap-1 mb-3">
                    {[1, 2, 3, 4, 5].map((star) => (
                      <Star
                        key={star}
                        size={16}
                        className={star <= review.rating ? 'text-yellow-400' : 'text-gray-200'}
                        fill={star <= review.rating ? 'currentColor' : 'none'}
                      />
                    ))}
                  </div>

                  {review.comment && (
                    <p className="text-gray-700 bg-gray-50 p-3 rounded-lg">{review.comment}</p>
                  )}

                  <p className="text-sm text-gray-400 mt-2">{review.createdAt}</p>
                </div>

                <div className="flex gap-2 ml-4">
                  <button
                    onClick={() => approveMutation.mutate(review.id)}
                    className="p-2 bg-green-100 text-green-600 rounded-lg hover:bg-green-200"
                    title="Onayla"
                  >
                    <Check size={18} />
                  </button>
                  <button
                    onClick={() => rejectMutation.mutate(review.id)}
                    className="p-2 bg-red-100 text-red-600 rounded-lg hover:bg-red-200"
                    title="Sil"
                  >
                    <X size={18} />
                  </button>
                </div>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  )
}

const mockReviews = [
  {
    id: '1',
    user: { name: 'Ahmet Yılmaz' },
    targetName: 'Merkez Kasap',
    rating: 5,
    comment: 'Çok kaliteli et, hızlı teslimat. Kesinlikle tavsiye ederim.',
    createdAt: '28.12.2024 14:30',
  },
  {
    id: '2',
    user: { name: 'Ayşe Kaya' },
    targetName: 'Şehir Fırını',
    rating: 4,
    comment: 'Ekmekler taze ve lezzetli. Sadece biraz geç geldi.',
    createdAt: '28.12.2024 13:15',
  },
]
