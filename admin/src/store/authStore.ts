import { create } from 'zustand'
import { persist } from 'zustand/middleware'

interface AuthState {
  isLoggedIn: boolean
  accessToken: string | null
  user: {
    id: string
    name: string
    role: string
  } | null
  login: (token: string, user: { id: string; name: string; role: string }) => void
  logout: () => void
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      isLoggedIn: false,
      accessToken: null,
      user: null,
      login: (token, user) => set({ isLoggedIn: true, accessToken: token, user }),
      logout: () => set({ isLoggedIn: false, accessToken: null, user: null }),
    }),
    {
      name: 'auth-storage',
    }
  )
)
