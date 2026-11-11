import { defineStore } from 'pinia'
import * as api from '../api/user'
import { initializeSession, resetSession } from '../utils/http'

export const useAuthStore = defineStore('auth', {
  state: () => ({ user: null, ready: false }),
  actions: {
    async hydrate() {
      if (this.ready) return
      try {
        const session = await initializeSession()
        this.user = session.authenticated ? await api.currentUser() : null
        this.ready = true
      } catch (error) {
        if (error.status === 401) { this.clear(); return }
        throw error
      }
    },
    async login(form) { const result = await api.signIn(form); this.user = result.user; this.ready = true },
    async register(form) { const result = await api.signUp(form); this.user = result.user; this.ready = true },
    async refresh() { this.user = await api.getProfile(); return this.user },
    async logout() { await api.signOut(); this.clear() },
    clear() { this.user = null; this.ready = true; resetSession() },
  },
})
