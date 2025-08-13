<template>
  <div class="accept-invitation-container">
    <div class="accept-card">
      <h1>School Bus System</h1>
      <h2>Complete Your Registration</h2>
      
      <div v-if="loading" class="loading">
        Loading invitation...
      </div>
      
      <div v-else-if="error" class="error-state">
        <div class="error-message">{{ error }}</div>
        <router-link to="/login" class="back-link">Go to Login</router-link>
      </div>
      
      <div v-else-if="invitation" class="invitation-content">
        <div class="invitation-info">
          <p><strong>You have been invited to join as:</strong> {{ invitation.role }}</p>
          <p><strong>Email:</strong> {{ invitation.email }}</p>
          <p><strong>Phone:</strong> {{ invitation.phone }}</p>
          <p><strong>Invited by:</strong> {{ invitation.invitedBy }}</p>
          <p class="expiry"><strong>Invitation expires:</strong> {{ formatDate(invitation.expiresAt) }}</p>
        </div>
        
        <form @submit.prevent="handleAccept" class="accept-form">
          <div class="form-group">
            <label for="firstName">First Name:</label>
            <input 
              id="firstName"
              type="text" 
              v-model="acceptForm.firstName" 
              required 
              :disabled="submitting"
            />
          </div>
          
          <div class="form-group">
            <label for="lastName">Last Name:</label>
            <input 
              id="lastName"
              type="text" 
              v-model="acceptForm.lastName" 
              required 
              :disabled="submitting"
            />
          </div>
          
          <div class="form-group">
            <label for="password">Password:</label>
            <input 
              id="password"
              type="password" 
              v-model="acceptForm.password" 
              required 
              minlength="6"
              :disabled="submitting"
            />
            <small class="help-text">Minimum 6 characters</small>
          </div>
          
          <div class="form-group">
            <label for="confirmPassword">Confirm Password:</label>
            <input 
              id="confirmPassword"
              type="password" 
              v-model="confirmPassword" 
              required 
              :disabled="submitting"
            />
          </div>
          
          <button 
            type="submit" 
            class="accept-button"
            :disabled="submitting || !passwordsMatch"
          >
            {{ submitting ? 'Creating Account...' : 'Create Account' }}
          </button>
        </form>
        
        <div v-if="acceptError" class="error-message">
          {{ acceptError }}
        </div>
        
        <div v-if="!passwordsMatch && confirmPassword" class="error-message">
          Passwords do not match
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import apiService from '../services/api'

export default {
  name: 'AcceptInvitation',
  setup() {
    const route = useRoute()
    const router = useRouter()
    
    const loading = ref(true)
    const submitting = ref(false)
    const error = ref('')
    const acceptError = ref('')
    const invitation = ref(null)
    
    const acceptForm = ref({
      firstName: '',
      lastName: '',
      password: ''
    })
    
    const confirmPassword = ref('')
    
    const passwordsMatch = computed(() => {
      return acceptForm.value.password === confirmPassword.value
    })
    
    const fetchInvitation = async () => {
      try {
        loading.value = true
        error.value = ''
        
        const token = route.query.token
        if (!token) {
          error.value = 'Invalid invitation link'
          return
        }
        
        const response = await apiService.get(`/invitations/token/${token}`)
        invitation.value = response.invitation
        
      } catch (err) {
        error.value = err.response?.data?.message || 'Failed to load invitation'
      } finally {
        loading.value = false
      }
    }
    
    const handleAccept = async () => {
      if (!passwordsMatch.value) {
        acceptError.value = 'Passwords do not match'
        return
      }
      
      try {
        submitting.value = true
        acceptError.value = ''
        
        const token = route.query.token
        await apiService.post(`/invitations/accept/${token}`, acceptForm.value)
        
        // Redirect to login with success message
        router.push({
          path: '/login',
          query: { message: 'Account created successfully! Please login.' }
        })
        
      } catch (err) {
        acceptError.value = err.response?.data?.message || 'Failed to create account'
      } finally {
        submitting.value = false
      }
    }
    
    const formatDate = (dateString) => {
      return new Date(dateString).toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      })
    }
    
    onMounted(() => {
      fetchInvitation()
    })
    
    return {
      loading,
      submitting,
      error,
      acceptError,
      invitation,
      acceptForm,
      confirmPassword,
      passwordsMatch,
      handleAccept,
      formatDate
    }
  }
}
</script>

<style scoped>
.accept-invitation-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  background-color: #f5f5f5;
  padding: 20px;
}

.accept-card {
  background: white;
  border-radius: 8px;
  padding: 40px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  width: 100%;
  max-width: 500px;
}

h1 {
  text-align: center;
  color: #333;
  margin-bottom: 10px;
}

h2 {
  text-align: center;
  color: #666;
  margin-bottom: 30px;
}

.loading {
  text-align: center;
  color: #666;
  padding: 40px;
}

.error-state {
  text-align: center;
}

.error-message {
  color: #dc3545;
  text-align: center;
  margin: 15px 0;
  padding: 10px;
  background-color: #f8d7da;
  border: 1px solid #f5c6cb;
  border-radius: 4px;
}

.back-link {
  display: inline-block;
  color: #007bff;
  text-decoration: none;
  margin-top: 20px;
  padding: 10px 20px;
  border: 1px solid #007bff;
  border-radius: 4px;
  transition: all 0.2s;
}

.back-link:hover {
  background-color: #007bff;
  color: white;
}

.invitation-info {
  background-color: #f8f9fa;
  border: 1px solid #dee2e6;
  border-radius: 4px;
  padding: 20px;
  margin-bottom: 30px;
}

.invitation-info p {
  margin: 8px 0;
  color: #333;
}

.expiry {
  color: #e83e8c;
  font-weight: bold;
}

.accept-form {
  margin-bottom: 20px;
}

.form-group {
  margin-bottom: 20px;
}

label {
  display: block;
  margin-bottom: 5px;
  color: #333;
  font-weight: bold;
}

input {
  width: 100%;
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 16px;
}

input:focus {
  outline: none;
  border-color: #007bff;
}

input:disabled {
  background-color: #f5f5f5;
  cursor: not-allowed;
}

.help-text {
  display: block;
  color: #666;
  font-size: 12px;
  margin-top: 5px;
}

.accept-button {
  width: 100%;
  padding: 12px;
  background-color: #28a745;
  color: white;
  border: none;
  border-radius: 4px;
  font-size: 16px;
  cursor: pointer;
  transition: background-color 0.2s;
}

.accept-button:hover:not(:disabled) {
  background-color: #218838;
}

.accept-button:disabled {
  background-color: #ccc;
  cursor: not-allowed;
}
</style>