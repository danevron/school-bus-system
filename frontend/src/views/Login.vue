<template>
  <div class="login-container">
    <Card class="login-card">
      <template #content>
        <!-- Logo and Header Section -->
        <div class="login-header">
          <div class="logo-container">
            <i class="pi pi-car" style="font-size: 3rem; color: var(--p-primary-color);"></i>
          </div>
          <h1>Welcome to PrimeLand!</h1>
          <p class="login-subtitle">Sign in to continue</p>
        </div>
        <!-- Toggle between Login and Signup -->
        <div class="form-toggle">
          <SelectButton 
            v-model="selectedMode" 
            :options="modeOptions"
            optionLabel="label"
            optionValue="value"
          />
        </div>

        <h2>{{ isSignup ? 'Create Account' : 'Login' }}</h2>
      
      <!-- Login Form -->
      <form v-if="!isSignup" @submit.prevent="handleLogin" class="login-form">
        <div class="form-group">
          <label for="email">Email:</label>
          <IconField>
            <InputIcon>
              <i class="pi pi-envelope" />
            </InputIcon>
            <InputText 
              id="email"
              type="email" 
              v-model="email" 
              required 
              :disabled="authStore.loading"
              fluid
              placeholder="Enter your email"
            />
          </IconField>
        </div>
        
        <div class="form-group">
          <label for="password">Password:</label>
          <Password 
            id="password"
            v-model="password" 
            required 
            :disabled="authStore.loading"
            fluid
            placeholder="Enter your password"
            :feedback="false"
            toggleMask
          />
        </div>
        
        <Button 
          type="submit" 
          class="w-full"
          :disabled="authStore.loading"
          :loading="authStore.loading"
        >
          {{ authStore.loading ? 'Logging in...' : 'Login' }}
        </Button>
      </form>

      <!-- Signup Form -->
      <form v-else @submit.prevent="handleSignup" class="signup-form">
        <div class="form-row">
          <div class="form-group">
            <label for="signup-firstName">First Name:</label>
            <IconField>
              <InputIcon>
                  <i class="pi pi-user" />
              </InputIcon>
              <InputText 
                id="signup-firstName"
                v-model="signupForm.firstName" 
                required 
                :disabled="authStore.loading"
                fluid
                placeholder="First name"
              />
            </IconField>
          </div>
          <div class="form-group">
            <label for="signup-lastName">Last Name:</label>
            <IconField>
              <InputIcon>
                  <i class="pi pi-user" />
              </InputIcon>
              <InputText 
                id="signup-lastName"
                v-model="signupForm.lastName" 
                required 
                :disabled="authStore.loading"
                fluid
                placeholder="Last name"
              />
            </IconField>
          </div>
        </div>

        <div class="form-group">
          <label for="signup-email">Email:</label>
          <IconField>
            <InputIcon>
              <i class="pi pi-envelope" />
            </InputIcon>
            <InputText 
              id="signup-email"
              type="email" 
              v-model="signupForm.email" 
              required 
              :disabled="authStore.loading"
              fluid
              placeholder="Enter your email"
            />
          </IconField>
        </div>

        <div class="form-group">
          <label for="signup-phone">Phone:</label>

          <IconField>
            <InputIcon>
              <i class="pi pi-phone" />
            </InputIcon>
            <InputText 
              id="signup-phone"
              type="tel" 
              v-model="signupForm.phone" 
              required 
              :disabled="authStore.loading"
              fluid
              placeholder="+1234567890"
            />
          </IconField>
        </div>


        <div class="form-group">
          <label for="signup-password">Password:</label>
          <Password 
            id="signup-password"
            v-model="signupForm.password" 
            required 
            :disabled="authStore.loading"
            fluid
            placeholder="Enter password (min 6 characters)"
            :feedback="true"
            toggleMask
          />
        </div>

        <div class="form-group">
          <label for="signup-confirmPassword">Confirm Password:</label>
          <Password 
            id="signup-confirmPassword"
            v-model="signupForm.confirmPassword" 
            required 
            :disabled="authStore.loading"
            fluid
            placeholder="Confirm your password"
            :feedback="false"
            toggleMask
          />
        </div>
        
        <Button 
          type="submit" 
          class="w-full"
          :disabled="authStore.loading || !isSignupFormValid"
          :loading="authStore.loading"
          severity="success"
        >
          {{ authStore.loading ? 'Creating Account...' : 'Create Account' }}
        </Button>
      </form>
      
        <div v-if="successMessage" class="success-message">
          {{ successMessage }}
        </div>

        <div v-if="authStore.error" class="error-message">
          {{ authStore.error }}
        </div>
      </template>
    </Card>
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
    
    const selectedMode = ref('login')
    const modeOptions = ref([
      { label: 'Login', value: 'login' },
      { label: 'Sign Up', value: 'signup' }
    ])
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
    
    const isSignup = computed(() => {
      return selectedMode.value === 'signup'
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
      selectedMode,
      modeOptions,
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
  background-color: var(--p-surface-ground);
  padding: 20px;
}

.login-card {
  width: 100%;
  max-width: 450px;
  box-shadow: var(--p-card-shadow);
}

.form-toggle {
  display: flex;
  justify-content: center;
  margin-bottom: 2rem;
}

.form-row {
  display: flex;
  gap: 1rem;
}

.form-row .form-group {
  flex: 1;
}

.login-header {
  text-align: center;
  margin-bottom: 2rem;
}

.logo-container {
  margin-bottom: 1rem;
}

.login-header h1 {
  color: var(--p-text-color);
  font-size: 2rem;
  font-weight: 600;
  margin: 0 0 0.5rem 0;
}

.login-subtitle {
  color: var(--p-text-muted-color);
  font-size: 1rem;
  margin: 0 0 2rem 0;
}

h2 {
  text-align: center;
  color: var(--p-text-muted-color);
  margin-bottom: 2rem;
  font-weight: 500;
}

.login-form,
.signup-form {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

label {
  font-weight: 600;
  color: var(--p-text-color);
}

.success-message {
  color: var(--p-green-600);
  text-align: center;
  margin-top: 1rem;
  padding: 0.75rem;
  background-color: var(--p-green-50);
  border: 1px solid var(--p-green-200);
  border-radius: var(--p-border-radius);
}

.error-message {
  color: var(--p-red-600);
  text-align: center;
  margin-top: 1rem;
  padding: 0.75rem;
  background-color: var(--p-red-50);
  border: 1px solid var(--p-red-200);
  border-radius: var(--p-border-radius);
}
</style>