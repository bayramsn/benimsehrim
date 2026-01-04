import axios from 'axios'
import { useAuthStore } from '@/store/authStore'

const api = axios.create({
  baseURL: '/api',
  headers: {
    'Content-Type': 'application/json',
  },
})

// Add auth token to requests
api.interceptors.request.use((config) => {
  const token = useAuthStore.getState().accessToken
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// Handle 401 responses
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      useAuthStore.getState().logout()
    }
    return Promise.reject(error)
  }
)

export default api

// API functions
export const adminApi = {
  // Dashboard
  getDashboard: () => api.get('/admin/dashboard'),
  
  // Vendors
  getVendors: (status?: string) => api.get('/admin/vendors', { params: { status } }),
  approveVendor: (id: string, approve: boolean) => api.put(`/admin/vendors/${id}/approve`, { approve }),
  
  // Drivers  
  getDrivers: (status?: string) => api.get('/admin/drivers', { params: { status } }),
  approveDriver: (id: string, approve: boolean) => api.put(`/admin/drivers/${id}/approve`, { approve }),
  
  // Couriers
  getCouriers: (status?: string) => api.get('/admin/couriers', { params: { status } }),
  approveCourier: (id: string, approve: boolean) => api.put(`/admin/couriers/${id}/approve`, { approve }),
  
  // Reviews
  getPendingReviews: () => api.get('/admin/reviews/pending'),
  approveReview: (id: string) => api.put(`/admin/reviews/${id}/approve`),
  rejectReview: (id: string) => api.put(`/admin/reviews/${id}/reject`),
  
  // Operations
  getOperationStats: () => api.get('/admin/operations/stats'),
}
