<template>
  <div class="accept-invitation-container">
    <Card class="accept-card">
      <template #header>
        <div class="card-header">
          <div class="header-content">
            <i class="pi pi-users header-icon"></i>
            <div class="header-text">
              <h1>School Bus System</h1>
              <h2>Complete Your Registration</h2>
            </div>
          </div>
        </div>
      </template>
      
      <template #content>
        <div v-if="loading" class="loading-state">
          <i class="pi pi-spin pi-spinner loading-icon"></i>
          <p>Loading invitation...</p>
        </div>
        
        <div v-else-if="error" class="error-state">
          <Card class="message-card error">
            <template #content>
              <div class="message-content">
                <i class="pi pi-exclamation-triangle"></i>
                <span>{{ error }}</span>
              </div>
            </template>
          </Card>
          <div class="error-actions">
            <Button 
              label="Go to Login" 
              icon="pi pi-sign-in"
              @click="$router.push('/login')"
              outlined
              severity="secondary"
            />
          </div>
        </div>
        
        <div v-else-if="invitation" class="invitation-content">
          <Card class="invitation-info-card">
            <template #header>
              <div class="info-header">
                <i class="pi pi-envelope"></i>
                <span>Invitation Details</span>
              </div>
            </template>
            <template #content>
              <div class="invitation-details">
                <div class="detail-item">
                  <i class="pi pi-user-plus"></i>
                  <div class="detail-content">
                    <label>Role:</label>
                    <span class="role-badge" :class="`role-${invitation.role}`">
                      {{ invitation.role }}
                    </span>
                  </div>
                </div>
                
                <div class="detail-item">
                  <i class="pi pi-envelope"></i>
                  <div class="detail-content">
                    <label>Email:</label>
                    <span>{{ invitation.email }}</span>
                  </div>
                </div>
                
                <div class="detail-item">
                  <i class="pi pi-phone"></i>
                  <div class="detail-content">
                    <label>Phone:</label>
                    <span>{{ invitation.phone }}</span>
                  </div>
                </div>
                
                <div class="detail-item">
                  <i class="pi pi-user"></i>
                  <div class="detail-content">
                    <label>Invited by:</label>
                    <span>{{ invitation.invitedBy }}</span>
                  </div>
                </div>
                
                <div class="detail-item expiry">
                  <i class="pi pi-clock"></i>
                  <div class="detail-content">
                    <label>Expires:</label>
                    <span>{{ formatDate(invitation.expiresAt) }}</span>
                  </div>
                </div>
              </div>
            </template>
          </Card>
          
          <Card class="form-card">
            <template #header>
              <div class="form-header">
                <i class="pi pi-user-edit"></i>
                <span>Create Your Account</span>
              </div>
            </template>
            <template #content>
              <form @submit.prevent="handleAccept" class="accept-form">
                <div class="form-row">
                  <div class="form-group">
                    <label for="firstName">First Name</label>
                    <IconField>
                      <InputIcon class="pi pi-user" />
                      <InputText 
                        id="firstName"
                        v-model="acceptForm.firstName" 
                        placeholder="Enter first name"
                        required 
                        :disabled="submitting"
                      />
                    </IconField>
                  </div>
                  
                  <div class="form-group">
                    <label for="lastName">Last Name</label>
                    <IconField>
                      <InputIcon class="pi pi-user" />
                      <InputText 
                        id="lastName"
                        v-model="acceptForm.lastName" 
                        placeholder="Enter last name"
                        required 
                        :disabled="submitting"
                      />
                    </IconField>
                  </div>
                </div>
                
                <div class="form-group">
                  <label for="password">Password</label>
                  <IconField>
                    <InputIcon class="pi pi-lock" />
                    <Password 
                      id="password"
                      v-model="acceptForm.password" 
                      placeholder="Enter password"
                      :feedback="false"
                      toggleMask
                      required 
                      :disabled="submitting"
                    />
                  </IconField>
                  <small class="help-text">
                    <i class="pi pi-info-circle"></i>
                    Minimum 6 characters
                  </small>
                </div>
                
                <div class="form-group">
                  <label for="confirmPassword">Confirm Password</label>
                  <IconField>
                    <InputIcon class="pi pi-lock" />
                    <Password 
                      id="confirmPassword"
                      v-model="confirmPassword" 
                      placeholder="Confirm password"
                      :feedback="false"
                      toggleMask
                      required 
                      :disabled="submitting"
                    />
                  </IconField>
                  <div v-if="!passwordsMatch && confirmPassword" class="field-error">
                    <i class="pi pi-exclamation-triangle"></i>
                    Passwords do not match
                  </div>
                </div>
                
                <Button 
                  type="submit" 
                  class="submit-button"
                  :loading="submitting"
                  loadingIcon="pi pi-spin pi-spinner"
                  :label="submitting ? 'Creating Account...' : 'Create Account'"
                  icon="pi pi-check"
                  severity="success"
                  :disabled="submitting || !passwordsMatch"
                  size="large"
                />
              </form>
              
              <div v-if="acceptError" class="form-message">
                <Card class="message-card error">
                  <template #content>
                    <div class="message-content">
                      <i class="pi pi-exclamation-triangle"></i>
                      <span>{{ acceptError }}</span>
                    </div>
                  </template>
                </Card>
              </div>
            </template>
          </Card>
        </div>
      </template>
    </Card>
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
  background: linear-gradient(135deg, var(--p-primary-50) 0%, var(--p-primary-100) 100%);
  padding: 20px;
}

.accept-card {
  width: 100%;
  max-width: 600px;
  border-radius: var(--p-border-radius-lg);
  box-shadow: var(--p-shadow-lg);
}

.card-header {
  background: var(--p-primary-500);
  color: white;
  border-radius: var(--p-border-radius-lg) var(--p-border-radius-lg) 0 0;
  padding: 2rem;
}

.header-content {
  display: flex;
  align-items: center;
  gap: 1.5rem;
}

.header-icon {
  font-size: 3rem;
  opacity: 0.9;
}

.header-text h1 {
  margin: 0;
  font-size: 1.75rem;
  font-weight: 600;
}

.header-text h2 {
  margin: 0.5rem 0 0 0;
  font-size: 1rem;
  opacity: 0.9;
  font-weight: 400;
}

.loading-state {
  text-align: center;
  padding: 3rem;
  color: var(--p-text-muted-color);
}

.loading-icon {
  font-size: 2rem;
  margin-bottom: 1rem;
  color: var(--p-primary-500);
}

.loading-state p {
  margin: 0;
  font-size: 1.1rem;
}

.error-state {
  text-align: center;
  padding: 1rem;
}

.error-actions {
  margin-top: 1.5rem;
}

.message-card {
  border-radius: 6px;
  margin-bottom: 1rem;
}

.message-card.error {
  border-left: 4px solid var(--p-red-500);
  background: var(--p-red-50);
}

.message-content {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px;
}

.message-content i {
  font-size: 1.25rem;
  color: var(--p-red-500);
}

.invitation-content {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.invitation-info-card {
  border: 1px solid var(--p-surface-border);
}

.info-header,
.form-header {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 1rem 1.5rem;
  background: var(--p-surface-50);
  border-bottom: 1px solid var(--p-surface-border);
  font-weight: 600;
  color: var(--p-text-color);
}

.invitation-details {
  padding: 0.5rem;
}

.detail-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 0.75rem;
  border-radius: var(--p-border-radius);
  margin-bottom: 0.5rem;
}

.detail-item:hover {
  background: var(--p-surface-50);
}

.detail-item i {
  font-size: 1.1rem;
  color: var(--p-primary-500);
  width: 20px;
  text-align: center;
}

.detail-content {
  display: flex;
  flex-direction: column;
  gap: 4px;
  flex: 1;
}

.detail-content label {
  font-size: 0.85rem;
  color: var(--p-text-muted-color);
  font-weight: 600;
  margin: 0;
}

.detail-content span {
  color: var(--p-text-color);
  font-weight: 500;
}

.role-badge {
  padding: 4px 12px;
  border-radius: 12px;
  font-size: 0.8rem;
  font-weight: bold;
  text-transform: uppercase;
  display: inline-block;
}

.role-admin { background-color: var(--p-red-500); color: white; }
.role-driver { background-color: var(--p-green-500); color: white; }
.role-parent { background-color: var(--p-yellow-500); color: var(--p-surface-900); }
.role-student { background-color: var(--p-blue-500); color: white; }

.detail-item.expiry {
  background: var(--p-orange-50);
  border: 1px solid var(--p-orange-200);
}

.detail-item.expiry i {
  color: var(--p-orange-500);
}

.detail-item.expiry .detail-content span {
  color: var(--p-orange-600);
  font-weight: 600;
}

.form-card {
  border: 1px solid var(--p-surface-border);
}

.accept-form {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.form-group label {
  font-weight: 600;
  color: var(--p-text-color);
  font-size: 0.9rem;
}

.form-group :deep(.p-inputtext),
.form-group :deep(.p-password-input) {
  padding-left: 2.5rem;
}

.form-group :deep(.p-icon-field .p-input-icon) {
  left: 0.75rem;
  color: var(--p-text-muted-color);
}

.help-text {
  display: flex;
  align-items: center;
  gap: 6px;
  color: var(--p-text-muted-color);
  font-size: 0.85rem;
  margin-top: 0.25rem;
}

.help-text i {
  font-size: 0.8rem;
}

.field-error {
  display: flex;
  align-items: center;
  gap: 6px;
  color: var(--p-red-500);
  font-size: 0.85rem;
  margin-top: 0.5rem;
}

.field-error i {
  font-size: 0.8rem;
}

.submit-button {
  margin-top: 1rem;
}

.form-message {
  margin-top: 1rem;
}

@media (max-width: 640px) {
  .accept-invitation-container {
    padding: 10px;
  }
  
  .accept-card {
    max-width: 100%;
  }
  
  .header-content {
    flex-direction: column;
    text-align: center;
    gap: 1rem;
  }
  
  .header-icon {
    font-size: 2.5rem;
  }
  
  .form-row {
    grid-template-columns: 1fr;
  }
}
</style>