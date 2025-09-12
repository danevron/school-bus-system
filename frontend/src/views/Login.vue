<template>
  <div class="login-container">
    <div class="login-card">
      <h1>School Bus System</h1>
      
      <!-- Toggle between Login and Signup -->
      <div class="form-toggle">
        <button 
          type="button"
          @click="isSignup = false" 
          :class="['toggle-btn', { active: !isSignup }]"
        >
          Login
        </button>
        <button 
          type="button"
          @click="isSignup = true" 
          :class="['toggle-btn', { active: isSignup }]"
        >
          Sign Up
        </button>
      </div>

      <h2>{{ isSignup ? 'Create Account' : 'Login' }}</h2>
      
      <!-- Login Form -->
      <form v-if="!isSignup" @submit.prevent="handleLogin" class="login-form">
        <div class="form-group">
          <label for="email">Email:</label>
          <input 
            id="email"
            type="email" 
            v-model="email" 
            required 
            :disabled="authStore.loading"
          />
        </div>
        
        <div class="form-group">
          <label for="password">Password:</label>
          <input 
            id="password"
            type="password" 
            v-model="password" 
            required 
            :disabled="authStore.loading"
          />
        </div>
        
        <button 
          type="submit" 
          class="login-button"
          :disabled="authStore.loading"
        >
          {{ authStore.loading ? 'Logging in...' : 'Login' }}
        </button>
      </form>

      <!-- Signup Form -->
      <form v-else @submit.prevent="handleSignup" class="signup-form">
        <div class="form-row">
          <div class="form-group">
            <label for="signup-firstName">First Name:</label>
            <input 
              id="signup-firstName"
              type="text" 
              v-model="signupForm.firstName" 
              required 
              :disabled="authStore.loading"
            />
          </div>
          <div class="form-group">
            <label for="signup-lastName">Last Name:</label>
            <input 
              id="signup-lastName"
              type="text" 
              v-model="signupForm.lastName" 
              required 
              :disabled="authStore.loading"
            />
          </div>
        </div>

        <div class="form-group">
          <label for="signup-email">Email:</label>
          <input 
            id="signup-email"
            type="email" 
            v-model="signupForm.email" 
            required 
            :disabled="authStore.loading"
          />
        </div>

        <div class="form-group">
          <label for="signup-phone">Phone:</label>
          <input 
            id="signup-phone"
            type="tel" 
            v-model="signupForm.phone" 
            required 
            :disabled="authStore.loading"
            placeholder="+1234567890"
          />
        </div>


        <div class="form-group">
          <label for="signup-password">Password:</label>
          <input 
            id="signup-password"
            type="password" 
            v-model="signupForm.password" 
            required 
            :disabled="authStore.loading"
            minlength="6"
          />
        </div>

        <div class="form-group">
          <label for="signup-confirmPassword">Confirm Password:</label>
          <input 
            id="signup-confirmPassword"
            type="password" 
            v-model="signupForm.confirmPassword" 
            required 
            :disabled="authStore.loading"
            minlength="6"
          />
        </div>
        
        <button 
          type="submit" 
          class="signup-button"
          :disabled="authStore.loading || !isSignupFormValid"
        >
          {{ authStore.loading ? 'Creating Account...' : 'Create Account' }}
        </button>
      </form>
      
      <div v-if="successMessage" class="success-message">
        {{ successMessage }}
      </div>

      <div v-if="authStore.error" class="error-message">
        {{ authStore.error }}
      </div>
    </div>
  </div>
</template>

<script>
import { ref, inject, onMounted, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'

export default {
  name: 'Login',
  setup() {
    const authStore = inject('authStore')
    const router = useRouter()
    const route = useRoute()
    
    const isSignup = ref(false)
    const email = ref('')
    const password = ref('')
    const successMessage = ref('')
    
    const signupForm = ref({
      firstName: '',
      lastName: '',
      email: '',
      phone: '',
      password: '',
      confirmPassword: ''
    })
    
    const isSignupFormValid = computed(() => {
      return signupForm.value.firstName.trim() &&
             signupForm.value.lastName.trim() &&
             signupForm.value.email.trim() &&
             signupForm.value.phone.trim() &&
             signupForm.value.password.length >= 6 &&
             signupForm.value.password === signupForm.value.confirmPassword
    })
    
    const handleLogin = async () => {
      authStore.clearError()
      
      const result = await authStore.login(email.value, password.value)
      
      if (result.success) {
        router.push('/home')
      }
    }
    
    const handleSignup = async () => {
      authStore.clearError()
      
      if (!isSignupFormValid.value) {
        return
      }
      
      const userData = {
        firstName: signupForm.value.firstName.trim(),
        lastName: signupForm.value.lastName.trim(),
        email: signupForm.value.email.trim(),
        phone: signupForm.value.phone.trim(),
        password: signupForm.value.password
      }
      
      const result = await authStore.register(userData)
      
      if (result.success) {
        router.push('/home')
      }
    }
    
    
    onMounted(() => {
      if (route.query.message) {
        successMessage.value = route.query.message
      }
    })
    
    return {
      isSignup,
      email,
      password,
      signupForm,
      successMessage,
      isSignupFormValid,
      authStore,
      handleLogin,
      handleSignup
    }
  }
}
</script>

<style scoped>
.login-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  background-color: #f5f5f5;
  padding: 20px;
}

.login-card {
  background: white;
  border-radius: 8px;
  padding: 40px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  width: 100%;
  max-width: 450px;
}

.form-toggle {
  display: flex;
  background-color: #f8f9fa;
  border-radius: 6px;
  padding: 4px;
  margin-bottom: 20px;
}

.toggle-btn {
  flex: 1;
  padding: 8px 16px;
  background: none;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 500;
  transition: all 0.2s;
  color: #666;
}

.toggle-btn.active {
  background-color: #007bff;
  color: white;
}

.form-row {
  display: flex;
  gap: 15px;
}

.form-row .form-group {
  flex: 1;
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

.login-form {
  margin-bottom: 30px;
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

.login-button,
.signup-button {
  width: 100%;
  padding: 12px;
  background-color: #007bff;
  color: white;
  border: none;
  border-radius: 4px;
  font-size: 16px;
  cursor: pointer;
  transition: background-color 0.2s;
}

.login-button:hover:not(:disabled),
.signup-button:hover:not(:disabled) {
  background-color: #0056b3;
}

.login-button:disabled,
.signup-button:disabled {
  background-color: #ccc;
  cursor: not-allowed;
}

.signup-button {
  background-color: #28a745;
}

.signup-button:hover:not(:disabled) {
  background-color: #218838;
}

.success-message {
  color: #28a745;
  text-align: center;
  margin-bottom: 15px;
  padding: 10px;
  background-color: #d4edda;
  border: 1px solid #c3e6cb;
  border-radius: 4px;
}

.error-message {
  color: #dc3545;
  text-align: center;
  margin-top: 15px;
  padding: 10px;
  background-color: #f8d7da;
  border: 1px solid #f5c6cb;
  border-radius: 4px;
}
</style>