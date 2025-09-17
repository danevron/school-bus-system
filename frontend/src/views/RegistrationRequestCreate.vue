<template>
  <AppLayout 
    :page-title="$t('registrationRequests.create.title')" 
    :show-action-bar="true"
    :breadcrumbs="breadcrumbItems"
  >
    <template #actions>
      <div class="action-buttons">
        <Button 
          :label="$t('common.cancel')" 
          icon="pi pi-times"
          severity="secondary"
          outlined
          @click="goBack"
        />
        <Button 
          :label="$t('registrationRequests.create.submit')" 
          icon="pi pi-send"
          severity="success"
          @click="submitRequest"
          :loading="submitting"
          :disabled="!isFormValid"
        />
      </div>
    </template>

    <div v-if="loading" class="loading-state">
      <ProgressSpinner />
      <p>{{ $t('registrationRequests.create.loadingRegistration') }}</p>
    </div>

    <div v-else-if="!registration" class="error-state">
      <Message severity="error" :closable="false">
        {{ $t('registrationRequests.create.registrationNotFound') }}
      </Message>
    </div>

    <form v-else @submit.prevent="submitRequest" class="request-form">
      <!-- Registration Information -->
      <Card class="info-card">
        <template #title>
          <div class="section-header">
            <i class="pi pi-bookmark"></i>
            <span>{{ $t('registrationRequests.create.registrationInfo') }}</span>
          </div>
        </template>
        <template #content>
          <div class="registration-summary">
            <h3>{{ registration.title }}</h3>
            <p v-if="registration.description" class="registration-description">
              {{ registration.description }}
            </p>
            <div class="registration-meta">
              <Tag :value="$t(`registrations.types.${registration.type}`)" />
              <span class="stops-info">
                <i class="pi pi-map-marker"></i>
                {{ registration.stops?.length || 0 }} {{ $t('registrations.stops').toLowerCase() }}
              </span>
            </div>
          </div>
        </template>
      </Card>

      <!-- Request Form -->
      <Card class="form-section">
        <template #title>
          <div class="section-header">
            <i class="pi pi-user"></i>
            <span>{{ $t('registrationRequests.create.requestDetails') }}</span>
          </div>
        </template>
        <template #content>
          <div class="form-grid">
            <!-- Student Selection -->
            <div class="form-group">
              <label for="student" class="form-label required">{{ $t('registrationRequests.create.student') }}</label>
              <Select 
                id="student"
                v-model="request.student" 
                :options="children"
                option-label="displayName"
                option-value="_id"
                :placeholder="$t('registrationRequests.create.selectStudent')"
                :invalid="!!errors.student"
                fluid
                :loading="loadingChildren"
              >
                <template #option="{ option }">
                  <div class="student-option">
                    <Avatar 
                      :label="getStudentInitials(option)"
                      size="small"
                      :style="{ backgroundColor: getStudentColor(option._id), color: 'white' }"
                    />
                    <span>{{ option.displayName }}</span>
                  </div>
                </template>
              </Select>
              <small v-if="errors.student" class="error-message">{{ errors.student }}</small>
            </div>

            <!-- Address -->
            <div class="form-group">
              <label for="address" class="form-label required">{{ $t('registrationRequests.create.address') }}</label>
              <InputText 
                id="address"
                v-model="request.address" 
                :placeholder="$t('registrationRequests.create.addressPlaceholder')"
                :invalid="!!errors.address"
                fluid
                required
              />
              <small v-if="errors.address" class="error-message">{{ errors.address }}</small>
            </div>

            <!-- Stop Selection -->
            <div class="form-group full-width">
              <label class="form-label required">{{ $t('registrationRequests.create.selectStop') }}</label>
              <div class="stops-instruction">
                <i class="pi pi-info-circle"></i>
                <span>{{ $t('registrationRequests.create.selectStopInstruction') }}</span>
              </div>
              <div class="stops-grid">
                <div 
                  v-for="(stop, index) in registration.stops" 
                  :key="index"
                  class="stop-option"
                  :class="{ selected: request.selectedStop?.name === stop.name }"
                  @click="selectStop(stop)"
                  role="button"
                  tabindex="0"
                  @keydown.enter="selectStop(stop)"
                  @keydown.space.prevent="selectStop(stop)"
                >
                  <div class="stop-content">
                    <div class="stop-header">
                      <div class="stop-radio">
                        <RadioButton 
                          :inputId="`stop-${index}`"
                          :value="stop"
                          v-model="request.selectedStop"
                          @change="selectStop(stop)"
                        />
                      </div>
                      <div class="stop-info">
                        <label :for="`stop-${index}`" class="stop-name">
                          <i class="pi pi-map-marker stop-icon"></i>
                          {{ stop.name }}
                        </label>
                        <p v-if="stop.description" class="stop-description">{{ stop.description }}</p>
                      </div>
                    </div>
                  </div>
                  <div v-if="request.selectedStop?.name === stop.name" class="selected-indicator">
                    <i class="pi pi-check"></i>
                    <span>{{ $t('common.selected') }}</span>
                  </div>
                </div>
              </div>
              <small v-if="errors.selectedStop" class="error-message">{{ errors.selectedStop }}</small>
            </div>

            <!-- Comments -->
            <div class="form-group full-width">
              <label for="comments" class="form-label">{{ $t('registrationRequests.create.comments') }}</label>
              <Textarea 
                id="comments"
                v-model="request.comments" 
                :placeholder="$t('registrationRequests.create.commentsPlaceholder')"
                rows="4"
                fluid
                @input="handleCommentsInput"
              />
            </div>
          </div>
        </template>
      </Card>
    </form>
  </AppLayout>
</template>

<script>
import { ref, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useToast } from 'primevue/usetoast'
import { useI18n } from 'vue-i18n'
import AppLayout from '../components/AppLayout.vue'
import apiService from '../services/api.js'

export default {
  name: 'RegistrationRequestCreate',
  components: {
    AppLayout
  },
  setup() {
    const router = useRouter()
    const route = useRoute()
    const toast = useToast()
    const { t } = useI18n()
    
    // Reactive data
    const loading = ref(true)
    const submitting = ref(false)
    const loadingChildren = ref(false)
    const registration = ref(null)
    const children = ref([])
    const request = ref({
      student: '',
      address: '',
      selectedStop: null,
      comments: ''
    })
    const errors = ref({})
    
    // Computed
    const registrationId = computed(() => route.params.registrationId)
    
    const breadcrumbItems = computed(() => [
      { label: t('home.title'), path: '/home' },
      { label: t('registrationRequests.create.title') }
    ])
    
    const isFormValid = computed(() => {
      return request.value.student && 
             request.value.address?.trim() && 
             request.value.selectedStop &&
             Object.keys(errors.value).length === 0
    })
    
    // Methods
    const loadRegistration = async () => {
      try {
        const response = await apiService.get(`/registrations/${registrationId.value}/active`)
        registration.value = response.data.registration
      } catch (error) {
        console.error('Error loading registration:', error)
        toast.add({
          severity: 'error',
          summary: 'Error',
          detail: 'Failed to load registration details',
          life: 5000
        })
      }
    }
    
    const loadChildren = async () => {
      loadingChildren.value = true
      try {
        const response = await apiService.get('/auth/my-students')
        children.value = response.data.children.map(child => ({
          ...child,
          displayName: `${child.firstName} ${child.lastName}`
        }))
      } catch (error) {
        console.error('Error loading children:', error)
        toast.add({
          severity: 'error',
          summary: 'Error',
          detail: 'Failed to load children list',
          life: 5000
        })
      } finally {
        loadingChildren.value = false
      }
    }
    
    const loadData = async () => {
      loading.value = true
      try {
        await Promise.all([
          loadRegistration(),
          loadChildren()
        ])
      } finally {
        loading.value = false
      }
    }
    
    const selectStop = (stop) => {
      request.value.selectedStop = {
        name: stop.name,
        description: stop.description || ''
      }
      clearError('selectedStop')
    }
    
    const validateForm = () => {
      const newErrors = {}
      
      if (!request.value.student) {
        newErrors.student = 'Student selection is required'
      }
      
      if (!request.value.address?.trim()) {
        newErrors.address = 'Address is required'
      }
      
      if (!request.value.selectedStop) {
        newErrors.selectedStop = 'Stop selection is required'
      }
      
      errors.value = newErrors
      return Object.keys(newErrors).length === 0
    }
    
    const clearError = (field) => {
      if (errors.value[field]) {
        delete errors.value[field]
        errors.value = { ...errors.value }
      }
    }
    
    const submitRequest = async () => {
      if (!validateForm()) {
        toast.add({
          severity: 'warn',
          summary: 'Validation Error',
          detail: 'Please fill in all required fields',
          life: 5000
        })
        return
      }
      
      submitting.value = true
      try {
        await apiService.post(`/registration-requests/${registrationId.value}`, {
          student: request.value.student,
          address: request.value.address.trim(),
          selectedStop: request.value.selectedStop,
          comments: request.value.comments?.trim() || ''
        })
        
        toast.add({
          severity: 'success',
          summary: 'Success',
          detail: 'Registration request submitted successfully',
          life: 3000
        })
        
        router.push('/home')
      } catch (error) {
        console.error('Error submitting request:', error)
        toast.add({
          severity: 'error',
          summary: 'Error',
          detail: error.response?.data?.message || 'Failed to submit request',
          life: 5000
        })
      } finally {
        submitting.value = false
      }
    }
    
    const goBack = () => {
      router.push('/home')
    }
    
    // Comments input handler (for PrimeVue Textarea binding issue)
    const handleCommentsInput = (event) => {
      request.value.comments = event.target.value
    }
    
    // Utility functions
    const getStudentInitials = (student) => {
      return `${student.firstName?.charAt(0) || ''}${student.lastName?.charAt(0) || ''}`.toUpperCase()
    }
    
    const getStudentColor = (studentId) => {
      if (!studentId || typeof studentId !== 'string') {
        return '#FF6B6B'
      }
      const colors = [
        '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', 
        '#FFEAA7', '#DDA0DD', '#98D8C8', '#F7DC6F'
      ]
      const index = studentId.charCodeAt(studentId.length - 1) % colors.length
      return colors[index]
    }
    
    // Lifecycle
    onMounted(() => {
      loadData()
    })
    
    return {
      loading,
      submitting,
      loadingChildren,
      registration,
      children,
      request,
      errors,
      breadcrumbItems,
      isFormValid,
      selectStop,
      submitRequest,
      goBack,
      handleCommentsInput,
      getStudentInitials,
      getStudentColor
    }
  }
}
</script>

<style scoped>
.loading-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 4rem;
  gap: 1rem;
  text-align: center;
  color: var(--p-text-muted-color);
}

.error-state {
  padding: 2rem;
}

.request-form {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.section-header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  color: var(--p-text-color);
  font-weight: 600;
}

.section-header i {
  color: var(--p-primary-color);
}

/* Registration Summary */
.registration-summary {
  padding: 0;
}

.registration-summary h3 {
  margin: 0 0 0.5rem 0;
  color: var(--p-text-color);
  font-size: 1.25rem;
}

.registration-description {
  margin: 0 0 1rem 0;
  color: var(--p-text-muted-color);
  line-height: 1.5;
}

.registration-meta {
  display: flex;
  align-items: center;
  gap: 1rem;
  flex-wrap: wrap;
}

.stops-info {
  display: flex;
  align-items: center;
  gap: 0.25rem;
  color: var(--p-text-muted-color);
  font-size: 0.875rem;
}

.stops-info i {
  color: var(--p-primary-color);
}

/* Form styles */
.form-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 1.5rem;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.form-group.full-width {
  grid-column: 1 / -1;
}

.form-label {
  font-weight: 500;
  color: var(--p-text-color);
}

.form-label.required::after {
  content: " *";
  color: var(--p-red-500);
}

.error-message {
  color: var(--p-red-500);
  font-size: 0.875rem;
}

/* Student option */
.student-option {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

/* Stop selection instruction */
.stops-instruction {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 1rem;
  padding: 0.75rem 1rem;
  background: var(--p-primary-50);
  border: 1px solid var(--p-primary-100);
  border-radius: var(--p-border-radius);
  color: var(--p-primary-700);
  font-size: 0.875rem;
}

.stops-instruction i {
  color: var(--p-primary-500);
}

/* Stop selection */
.stops-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
  gap: 1rem;
  margin-top: 0.5rem;
}

.stop-option {
  border: 2px solid var(--p-surface-border);
  border-radius: var(--p-border-radius);
  cursor: pointer;
  transition: all 0.3s ease;
  background: var(--p-surface-card);
  position: relative;
  overflow: hidden;
}

.stop-option:hover {
  border-color: var(--p-primary-color);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  transform: translateY(-1px);
}

.stop-option:focus {
  outline: none;
  border-color: var(--p-primary-color);
  box-shadow: 0 0 0 2px var(--p-primary-100);
}

.stop-option.selected {
  border-color: var(--p-primary-color);
  background: linear-gradient(135deg, var(--p-primary-50) 0%, var(--p-primary-25) 100%);
  box-shadow: 0 4px 12px rgba(var(--p-primary-color-rgb), 0.2);
}

.stop-content {
  display: flex;
  align-items: flex-start;
  padding: 1.25rem;
  position: relative;
}

.stop-content::before {
  content: '';
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 4px;
  background: transparent;
  border-radius: 0 4px 4px 0;
  transition: all 0.3s ease;
}

.stop-option:hover .stop-content::before {
  background: var(--p-primary-color);
}

.stop-option.selected .stop-content::before {
  background: var(--p-primary-color);
}

.stop-header {
  display: flex;
  align-items: flex-start;
  gap: 1rem;
  flex: 1;
}

.stop-radio {
  margin-top: 0.125rem;
}

.stop-info {
  flex: 1;
}

.stop-name {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-weight: 600;
  color: var(--p-text-color);
  cursor: pointer;
  font-size: 1rem;
  margin-bottom: 0.5rem;
}

.stop-icon {
  color: var(--p-primary-color);
  font-size: 1.125rem;
}

.stop-description {
  margin: 0;
  color: var(--p-text-muted-color);
  font-size: 0.875rem;
  line-height: 1.5;
}


.selected-indicator {
  position: absolute;
  top: 0;
  right: 0;
  background: var(--p-primary-color);
  color: white;
  padding: 0.5rem 1rem;
  border-bottom-left-radius: var(--p-border-radius);
  display: flex;
  align-items: center;
  gap: 0.375rem;
  font-size: 0.75rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.selected-indicator i {
  font-size: 0.875rem;
}

/* Action buttons */
.action-buttons {
  display: flex;
  gap: 0.75rem;
}

/* RTL Support for Hebrew */
[dir="rtl"] .stop-content::before {
  left: auto;
  right: 0;
  border-radius: 4px 0 0 4px;
}

[dir="rtl"] .selected-indicator {
  top: 0;
  left: 0;
  right: auto;
  border-bottom-right-radius: var(--p-border-radius);
  border-bottom-left-radius: 0;
}

/* Responsive */
@media (max-width: 768px) {
  .form-grid {
    grid-template-columns: 1fr;
  }
  
  .stops-grid {
    grid-template-columns: 1fr;
  }
  
  .stop-content {
    padding: 1rem;
  }
  
  .stops-instruction {
    padding: 0.625rem 0.875rem;
    font-size: 0.8125rem;
  }
  
  .stop-name {
    font-size: 0.9375rem;
  }
  
  .selected-indicator {
    padding: 0.375rem 0.75rem;
    font-size: 0.6875rem;
  }
  
  .action-buttons {
    flex-direction: column;
  }
}
</style>