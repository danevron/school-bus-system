import { reactive } from 'vue'
import apiService from '../services/api'

const state = reactive({
  user: JSON.parse(localStorage.getItem('user') || 'null'),
  token: localStorage.getItem('authToken') || null,
  loading: false,
  error: null
})

const authStore = {
  // Getters
  get user() {
    return state.user
  },

  get token() {
    return state.token
  },

  get loading() {
    return state.loading
  },

  get error() {
    return state.error
  },

  isAuthenticated() {
    return !!state.token && !!state.user
  },

  getUserRole() {
    return state.user?.role || null
  },

  // Actions
  async login(email, password) {
    try {
      state.loading = true
      state.error = null

      const response = await apiService.login(email, password)
      
      if (response.token && response.user) {
        state.token = response.token
        state.user = response.user
        
        // Store in localStorage
        localStorage.setItem('authToken', response.token)
        localStorage.setItem('user', JSON.stringify(response.user))
        
        return { success: true }
      } else {
        throw new Error('Invalid response from server')
      }
    } catch (error) {
      state.error = error.response?.data?.message || error.message || 'Login failed'
      return { success: false, error: state.error }
    } finally {
      state.loading = false
    }
  },

  async register(userData) {
    try {
      state.loading = true
      state.error = null

      const response = await apiService.register(userData)
      
      if (response.token && response.user) {
        state.token = response.token
        state.user = response.user
        
        // Store in localStorage
        localStorage.setItem('authToken', response.token)
        localStorage.setItem('user', JSON.stringify(response.user))
        
        return { success: true }
      } else {
        throw new Error('Invalid response from server')
      }
    } catch (error) {
      state.error = error.response?.data?.message || error.message || 'Registration failed'
      return { success: false, error: state.error }
    } finally {
      state.loading = false
    }
  },

  logout() {
    state.user = null
    state.token = null
    state.error = null
    
    // Clear localStorage
    localStorage.removeItem('authToken')
    localStorage.removeItem('user')
  },

  clearError() {
    state.error = null
  },

  async fetchProfile() {
    try {
      const response = await apiService.getProfile()
      if (response.user) {
        state.user = response.user
        localStorage.setItem('user', JSON.stringify(response.user))
      }
    } catch (error) {
      console.error('Failed to fetch profile:', error)
      this.logout()
    }
  }
}

export default authStore