import axios from 'axios'

const API_BASE_URL = '/api'

class ApiService {
  constructor() {
    this.axios = axios.create({
      baseURL: API_BASE_URL,
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json'
      }
    })

    // Request interceptor to add auth token
    this.axios.interceptors.request.use(
      (config) => {
        const token = localStorage.getItem('authToken')
        if (token) {
          config.headers.Authorization = `Bearer ${token}`
        }
        return config
      },
      (error) => Promise.reject(error)
    )

    // Response interceptor to handle errors
    this.axios.interceptors.response.use(
      (response) => response,
      (error) => {
        if (error.response?.status === 401) {
          // Token expired or invalid, clear auth data
          localStorage.removeItem('authToken')
          localStorage.removeItem('user')
          window.location.href = '/login'
        }
        return Promise.reject(error)
      }
    )
  }

  // Auth endpoints
  async login(email, password) {
    const response = await this.axios.post('/auth/login', {
      email,
      password
    })
    return response.data
  }

  async register(userData) {
    const response = await this.axios.post('/auth/register', userData)
    return response.data
  }

  async getProfile() {
    const response = await this.axios.get('/auth/profile')
    return response.data
  }

  // Generic methods
  async get(endpoint) {
    const response = await this.axios.get(endpoint)
    return response.data
  }

  async post(endpoint, data) {
    const response = await this.axios.post(endpoint, data)
    return response.data
  }

  async put(endpoint, data) {
    const response = await this.axios.put(endpoint, data)
    return response.data
  }

  async delete(endpoint) {
    const response = await this.axios.delete(endpoint)
    return response.data
  }
}

export default new ApiService()