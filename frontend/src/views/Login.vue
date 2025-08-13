<template>
  <div class="login-container">
    <div class="login-card">
      <h1>School Bus System</h1>
      <h2>Login</h2>
      
      <form @submit.prevent="handleLogin" class="login-form">
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
      
      <div v-if="successMessage" class="success-message">
        {{ successMessage }}
      </div>

      <div v-if="authStore.error" class="error-message">
        {{ authStore.error }}
      </div>

      <div class="demo-accounts">
        <h3>Demo Accounts</h3>
        <div class="demo-buttons">
          <button @click="loginAsDemo('admin')" class="demo-button" :disabled="authStore.loading">
            Login as Admin
          </button>
          <button @click="loginAsDemo('driver')" class="demo-button" :disabled="authStore.loading">
            Login as Driver
          </button>
          <button @click="loginAsDemo('parent')" class="demo-button" :disabled="authStore.loading">
            Login as Parent
          </button>
          <button @click="loginAsDemo('student')" class="demo-button" :disabled="authStore.loading">
            Login as Student
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, inject, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'

export default {
  name: 'Login',
  setup() {
    const authStore = inject('authStore')
    const router = useRouter()
    const route = useRoute()
    
    const email = ref('')
    const password = ref('')
    const successMessage = ref('')
    
    const demoAccounts = {
      admin: { email: 'admin@example.com', password: 'password123' },
      driver: { email: 'driver@example.com', password: 'password123' },
      parent: { email: 'parent@example.com', password: 'password123' },
      student: { email: 'student@example.com', password: 'password123' }
    }
    
    const handleLogin = async () => {
      authStore.clearError()
      
      const result = await authStore.login(email.value, password.value)
      
      if (result.success) {
        router.push('/home')
      }
    }
    
    const loginAsDemo = async (role) => {
      const demoAccount = demoAccounts[role]
      email.value = demoAccount.email
      password.value = demoAccount.password
      await handleLogin()
    }
    
    onMounted(() => {
      if (route.query.message) {
        successMessage.value = route.query.message
      }
    })
    
    return {
      email,
      password,
      successMessage,
      authStore,
      handleLogin,
      loginAsDemo
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
  max-width: 400px;
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

.login-button {
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

.login-button:hover:not(:disabled) {
  background-color: #0056b3;
}

.login-button:disabled {
  background-color: #ccc;
  cursor: not-allowed;
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

.demo-accounts {
  border-top: 1px solid #eee;
  padding-top: 20px;
}

.demo-accounts h3 {
  text-align: center;
  color: #666;
  margin-bottom: 15px;
  font-size: 14px;
}

.demo-buttons {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
}

.demo-button {
  padding: 8px 12px;
  background-color: #6c757d;
  color: white;
  border: none;
  border-radius: 4px;
  font-size: 12px;
  cursor: pointer;
  transition: background-color 0.2s;
}

.demo-button:hover:not(:disabled) {
  background-color: #545b62;
}

.demo-button:disabled {
  background-color: #ccc;
  cursor: not-allowed;
}
</style>