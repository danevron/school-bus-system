<template>
  <AppLayout 
    :page-title="$t('lineCreate.title')"
    :breadcrumbs="breadcrumbs"
  >
    <template #actions>
      <Button 
        @click="goBack" 
        icon="pi pi-arrow-left"
        :label="$t('lines.backToLines')"
        severity="secondary"
        outlined
      />
      <Button 
        @click="handleSave" 
        icon="pi pi-check"
        :label="$t('lineCreate.createLine')"
        severity="success"
        :disabled="!isFormValid"
      />
    </template>

    <div class="content-wrapper">
      <Card class="form-card">
        <template #content>
          <!-- Form Content -->
          <div class="form-content">
            <div class="form-section">
              <h2>{{ $t('lineCreate.lineInformation') }}</h2>
              <p class="section-description">
                {{ $t('lineCreate.lineInformationDescription') }}
              </p>

              <div class="form-group">
                <label for="lineName" class="form-label">{{ $t('lineCreate.lineName') }} *</label>
                <InputText
                  id="lineName"
                  v-model="formData.name"
                  :placeholder="$t('lineCreate.lineNamePlaceholder')"
                  maxlength="100"
                  :invalid="!!errors.name"
                  @blur="validateField('name')"
                  @input="clearFieldError('name')"
                />
                <div v-if="errors.name" class="error-message">{{ errors.name }}</div>
                <div class="field-hint">{{ $t('lineCreate.lineNameHint') }}</div>
              </div>

              <div class="form-group">
                <label for="driver" class="form-label">{{ $t('lineCreate.assignedDriver') }} *</label>
                <Select
                  id="driver"
                  v-model="formData.driverId"
                  :options="availableDrivers"
                  optionLabel="displayName"
                  optionValue="_id"
                  :placeholder="$t('lineCreate.selectDriver')"
                  :invalid="!!errors.driverId"
                  :loading="loadingDrivers"
                  @change="validateField('driverId')"
                />
                <div v-if="errors.driverId" class="error-message">{{ errors.driverId }}</div>
                <div v-if="loadingDrivers" class="loading-message">{{ $t('lineCreate.loadingDrivers') }}</div>
                <div v-else-if="availableDrivers.length === 0" class="warning-message">
                  {{ $t('lineCreate.noAvailableDrivers') }}
                </div>
              </div>

              <div class="form-group">
                <label for="vehicle" class="form-label">{{ $t('lineCreate.assignedVehicle') }} *</label>
                <Select
                  id="vehicle"
                  v-model="formData.vehicleId"
                  :options="availableVehicles"
                  optionLabel="displayName"
                  optionValue="_id"
                  :placeholder="$t('lineCreate.selectVehicle')"
                  :invalid="!!errors.vehicleId"
                  :loading="loadingVehicles"
                  @change="validateField('vehicleId')"
                />
                <div v-if="errors.vehicleId" class="error-message">{{ errors.vehicleId }}</div>
                <div v-if="loadingVehicles" class="loading-message">{{ $t('lineCreate.loadingVehicles') }}</div>
                <div v-else-if="availableVehicles.length === 0" class="warning-message">
                  {{ $t('lineCreate.noAvailableVehicles') }}
                </div>
              </div>

              <div class="form-group">
                <label class="form-label">{{ $t('lineCreate.schedulePeriod') }} *</label>
                <p class="field-description">{{ $t('lineCreate.schedulePeriodDescription') }}</p>
                
                <div class="date-range-inputs">
                  <div class="date-input-group">
                    <label for="startDate" class="date-label">{{ $t('lineCreate.startDate') }}</label>
                    <Calendar
                      id="startDate"
                      v-model="formData.startDateObj"
                      dateFormat="yy-mm-dd"
                      :minDate="todayDate"
                      :invalid="!!errors.startDate"
                      @date-select="handleStartDateChange"
                    />
                    <div v-if="errors.startDate" class="error-message">{{ errors.startDate }}</div>
                  </div>
                  
                  <div class="date-input-group">
                    <label for="endDate" class="date-label">{{ $t('lineCreate.endDate') }}</label>
                    <Calendar
                      id="endDate"
                      v-model="formData.endDateObj"
                      dateFormat="yy-mm-dd"
                      :minDate="formData.startDateObj || todayDate"
                      :invalid="!!errors.endDate"
                      @date-select="handleEndDateChange"
                    />
                    <div v-if="errors.endDate" class="error-message">{{ errors.endDate }}</div>
                  </div>
                </div>
              </div>

              <div class="form-group">
                <label class="form-label">{{ $t('lineCreate.operatingDays') }} *</label>
                <p class="field-description">{{ $t('lineCreate.operatingDaysDescription') }}</p>
                <div class="days-selector">
                  <label 
                    v-for="day in weekDays" 
                    :key="day.value"
                    class="day-option"
                    :class="{ 'selected': formData.scheduleDays.includes(day.value) }"
                  >
                    <input
                      type="checkbox"
                      :value="day.value"
                      v-model="formData.scheduleDays"
                      @change="validateField('scheduleDays')"
                    />
                    <span class="day-short">{{ day.short }}</span>
                    <span class="day-full">{{ day.full }}</span>
                  </label>
                </div>
                <div v-if="errors.scheduleDays" class="error-message">{{ errors.scheduleDays }}</div>
                <div class="field-hint">
                  {{ $t('lineCreate.selectedDays') }}: {{ formatSelectedDays() || $t('lineCreate.noneSelected') }}
                </div>
                
                <!-- Quick selection buttons -->
                <div class="quick-select-buttons">
                  <Button 
                    type="button" 
                    @click="selectWeekdays" 
                    :label="$t('lineCreate.weekdaysOnly')"
                    size="small"
                    :severity="isWeekdaysSelected() ? 'primary' : 'secondary'"
                    :outlined="!isWeekdaysSelected()"
                  />
                  <Button 
                    type="button" 
                    @click="selectAllDays" 
                    :label="$t('lineCreate.allDays')"
                    size="small"
                    :severity="isAllDaysSelected() ? 'primary' : 'secondary'"
                    :outlined="!isAllDaysSelected()"
                  />
                  <Button 
                    type="button" 
                    @click="clearSchedule" 
                    :label="$t('lineCreate.clearAll')"
                    size="small"
                    severity="secondary"
                    outlined
                  />
                </div>
              </div>

              <div class="form-group">
                <label for="rideStartTime" class="form-label">{{ $t('lineCreate.rideStartTime') }} *</label>
                <p class="field-description">{{ $t('lineCreate.rideStartTimeDescription') }}</p>
                <InputMask
                  id="rideStartTime"
                  v-model="formData.rideStartTime"
                  mask="99:99"
                  :placeholder="$t('lineCreate.timeFormat')"
                  :invalid="!!errors.rideStartTime"
                  @blur="validateField('rideStartTime')"
                  @input="clearFieldError('rideStartTime')"
                />
                <div v-if="errors.rideStartTime" class="error-message">{{ errors.rideStartTime }}</div>
                <div class="field-hint">
                  {{ $t('lineCreate.rideStartTimeHint') }}
                </div>
              </div>

            </div>
          </div> 
          <!-- After Creation Info -->
          <div class="next-steps-preview">
            <h3>{{ $t('lineCreate.afterCreatingLine') }}</h3>
            <div class="step-preview">
              <div class="preview-item">
                <span class="preview-icon">🗺️</span>
                <span>{{ $t('lineCreate.createRouteStep') }}</span>
              </div>
              <div class="preview-item">
                <span class="preview-icon">👥</span>
                <span>{{ $t('lineCreate.assignStudentsStep') }}</span>
              </div>
              <div class="preview-item">
                <span class="preview-icon">🚌</span>
                <span>{{ $t('lineCreate.assignVehicleStep') }}</span>
              </div>
            </div>
            <div class="info-note">
              <p><strong>{{ $t('lineCreate.note') }}:</strong> {{ $t('lineCreate.noteText') }}</p>
            </div>
          </div>
        </template>
      </Card>
    </div>
  </AppLayout>
</template>

<script>
import { ref, inject, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import apiService from '../services/api'
import AppLayout from '../components/AppLayout.vue'

export default {
  name: 'LineCreate',
  components: {
    AppLayout
  },
  setup() {
    const authStore = inject('authStore')
    const router = useRouter()
    const { t } = useI18n()
    
    const formData = ref({
      name: '',
      driverId: '',
      vehicleId: '',
      startDate: '',
      endDate: '',
      startDateObj: null,
      endDateObj: null,
      scheduleDays: [],
      rideStartTime: ''
    })
    
    const errors = ref({})
    const availableDrivers = ref([])
    const loadingDrivers = ref(false)
    const availableVehicles = ref([])
    const loadingVehicles = ref(false)
    
    const weekDays = computed(() => [
      { value: 'sunday', short: t('lineView.sun'), full: t('common.days.sunday') },
      { value: 'monday', short: t('lineView.mon'), full: t('common.days.monday') },
      { value: 'tuesday', short: t('lineView.tue'), full: t('common.days.tuesday') },
      { value: 'wednesday', short: t('lineView.wed'), full: t('common.days.wednesday') },
      { value: 'thursday', short: t('lineView.thu'), full: t('common.days.thursday') },
      { value: 'friday', short: t('lineView.fri'), full: t('common.days.friday') },
      { value: 'saturday', short: t('lineView.sat'), full: t('common.days.saturday') }
    ])
    
    // Computed properties for PrimeVue components
    const todayDate = computed(() => new Date())

    const breadcrumbs = computed(() => [
      { label: t('navigation.dashboard'), path: '/home' },
      { label: t('lines.title'), path: '/lines' },
      { label: t('lineCreate.title') }
    ])
    
    const fetchAvailableDrivers = async () => {
      try {
        loadingDrivers.value = true
        const response = await apiService.get('/auth/users?role=driver&isActive=true')
        const drivers = response.users || response.data || []
        // Add displayName for PrimeVue Select
        availableDrivers.value = drivers.map(driver => ({
          ...driver,
          displayName: `${driver.firstName} ${driver.lastName}${driver.email ? ` (${driver.email})` : ''}`
        }))
      } catch (error) {
        console.error('Failed to fetch drivers:', error)
      } finally {
        loadingDrivers.value = false
      }
    }
    
    const fetchAvailableVehicles = async () => {
      try {
        loadingVehicles.value = true
        const response = await apiService.get('/vehicles?isActive=true')
        const vehicles = response.vehicles || response.data || []
        // Add displayName for PrimeVue Select
        availableVehicles.value = vehicles.map(vehicle => ({
          ...vehicle,
          displayName: `${vehicle.licensePlate}${vehicle.model ? ` - ${vehicle.model}` : ''}${vehicle.capacity ? ` (${vehicle.capacity} seats)` : ''}`
        }))
      } catch (error) {
        console.error('Failed to fetch vehicles:', error)
      } finally {
        loadingVehicles.value = false
      }
    }
    
    // Date handling methods for PrimeVue Calendar
    const handleStartDateChange = (event) => {
      const date = event
      formData.value.startDateObj = date
      formData.value.startDate = formatDateToString(date)
      validateField('startDate')
    }
    
    const handleEndDateChange = (event) => {
      const date = event
      formData.value.endDateObj = date
      formData.value.endDate = formatDateToString(date)
      validateField('endDate')
    }
    
    const formatDateToString = (date) => {
      if (!date) return ''
      const year = date.getFullYear()
      const month = String(date.getMonth() + 1).padStart(2, '0')
      const day = String(date.getDate()).padStart(2, '0')
      return `${year}-${month}-${day}`
    }
    
    const validateField = (field) => {
      switch (field) {
        case 'name':
          if (!formData.value.name.trim()) {
            errors.value.name = t('lineCreate.validation.nameRequired')
          } else if (formData.value.name.length < 3) {
            errors.value.name = t('lineCreate.validation.nameMinLength')
          }
          break
        case 'driverId':
          if (!formData.value.driverId) {
            errors.value.driverId = t('lineCreate.validation.driverRequired')
          }
          break
        case 'vehicleId':
          if (!formData.value.vehicleId) {
            errors.value.vehicleId = t('lineCreate.validation.vehicleRequired')
          }
          break
        case 'startDate':
          if (!formData.value.startDate) {
            errors.value.startDate = t('lineCreate.validation.startDateRequired')
          } else if (new Date(formData.value.startDate) < new Date().setHours(0,0,0,0)) {
            errors.value.startDate = t('lineCreate.validation.startDatePast')
          }
          break
        case 'endDate':
          if (!formData.value.endDate) {
            errors.value.endDate = t('lineCreate.validation.endDateRequired')
          } else if (formData.value.startDate && new Date(formData.value.endDate) < new Date(formData.value.startDate)) {
            errors.value.endDate = t('lineCreate.validation.endDateAfterStart')
          }
          break
        case 'scheduleDays':
          if (!formData.value.scheduleDays.length) {
            errors.value.scheduleDays = t('lineCreate.validation.scheduleDaysRequired')
          }
          break
        case 'rideStartTime':
          if (!formData.value.rideStartTime) {
            errors.value.rideStartTime = t('lineCreate.validation.rideStartTimeRequired')
          }
          break
      }
    }
    
    const clearFieldError = (field) => {
      if (errors.value[field]) {
        delete errors.value[field]
      }
    }
    
    const validateForm = () => {
      errors.value = {}
      validateField('name')
      validateField('driverId')
      validateField('vehicleId')
      validateField('startDate')
      validateField('endDate')
      validateField('scheduleDays')
      validateField('rideStartTime')
      return Object.keys(errors.value).length === 0
    }
    
    const isFormValid = computed(() => {
      return formData.value.name.trim().length >= 3 && 
             formData.value.driverId && 
             formData.value.vehicleId &&
             formData.value.startDate &&
             formData.value.endDate &&
             formData.value.scheduleDays.length > 0 &&
             formData.value.rideStartTime &&
             Object.keys(errors.value).length === 0
    })
    
    const handleSave = async () => {
      if (!validateForm()) {
        return
      }
      
      try {
        console.log('Creating line with data:', formData.value)
        
        // Convert day names to numbers (0=Sunday, 1=Monday, etc.)
        const dayNameToNumber = {
          'sunday': 0,
          'monday': 1,
          'tuesday': 2,
          'wednesday': 3,
          'thursday': 4,
          'friday': 5,
          'saturday': 6
        }
        
        const daysOfWeek = formData.value.scheduleDays.map(day => dayNameToNumber[day])
        
        const response = await apiService.post('/lines', {
          name: formData.value.name,
          driver: formData.value.driverId,
          vehicle: formData.value.vehicleId,
          rideStartTime: formData.value.rideStartTime,
          schedule: {
            type: 'custom',
            daysOfWeek: daysOfWeek,
            startDate: formData.value.startDate,
            endDate: formData.value.endDate
          }
        })
        
        const lineId = response.line?._id || response.data?._id
        if (lineId) {
          router.push(`/lines/${lineId}`)
        } else {
          router.push('/lines')
        }
      } catch (error) {
        console.error('Failed to create line:', error)
        // TODO: Add proper error handling UI
        alert(t('lineCreate.failedToCreateLine'))
      }
    }
    
    const formatSelectedDays = () => {
      if (!formData.value.scheduleDays.length) return ''
      return weekDays.value
        .filter(day => formData.value.scheduleDays.includes(day.value))
        .map(day => day.short)
        .join(', ')
    }
    
    const getTodayDate = () => {
      const today = new Date()
      return today.toISOString().split('T')[0]
    }
    
    const selectWeekdays = () => {
      formData.value.scheduleDays = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday']
      clearFieldError('scheduleDays')
    }
    
    const selectAllDays = () => {
      formData.value.scheduleDays = weekDays.value.map(day => day.value)
      clearFieldError('scheduleDays')
    }
    
    const clearSchedule = () => {
      formData.value.scheduleDays = []
    }
    
    const isWeekdaysSelected = () => {
      const weekdays = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday']
      return weekdays.every(day => formData.value.scheduleDays.includes(day)) &&
             formData.value.scheduleDays.length === 5
    }
    
    const isAllDaysSelected = () => {
      return formData.value.scheduleDays.length === 7
    }
    
    const goBack = () => {
      router.push('/lines')
    }
    
    onMounted(async () => {
      await Promise.all([
        fetchAvailableDrivers(),
        fetchAvailableVehicles()
      ])
    })
    
    return {
      t,
      formData,
      errors,
      availableDrivers,
      loadingDrivers,
      availableVehicles,
      loadingVehicles,
      weekDays,
      todayDate,
      breadcrumbs,
      isFormValid,
      validateField,
      clearFieldError,
      getTodayDate,
      formatSelectedDays,
      selectWeekdays,
      selectAllDays,
      clearSchedule,
      isWeekdaysSelected,
      isAllDaysSelected,
      handleSave,
      goBack,
      handleStartDateChange,
      handleEndDateChange,
      formatDateToString
    }
  }
}
</script>

<style scoped>
/* Content wrapper for AppLayout */
.content-wrapper {
  display: flex;
  flex-direction: column;
  gap: 20px;
}


.form-content {
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: 40px;
}

.form-section h2 {
  color: var(--p-text-color);
  margin-bottom: 10px;
  font-size: 1.5rem;
}

.section-description {
  color: var(--p-text-muted-color);
  margin-bottom: 30px;
  line-height: 1.5;
}

.form-group {
  margin-bottom: 24px;
}

.form-label {
  display: block;
  font-weight: 500;
  color: var(--p-text-color);
  margin-bottom: 8px;
}

.radio-group {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.radio-option {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  padding: 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.2s;
}

.radio-option:hover {
  background-color: #f8f9fa;
}

.radio-option input[type="radio"] {
  margin-top: 2px;
}

.radio-label {
  font-weight: 500;
  color: #333;
}

.radio-description {
  font-size: 0.9rem;
  color: #666;
  margin-left: auto;
}

.error-message {
  color: var(--p-red-500);
  font-size: 0.875rem;
  margin-top: 4px;
}

.field-hint {
  color: var(--p-text-muted-color);
  font-size: 0.875rem;
  margin-top: 4px;
}

.field-description {
  color: var(--p-text-muted-color);
  font-size: 0.9rem;
  margin-bottom: 12px;
  margin-top: -4px;
}

.date-range-inputs {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
  margin-bottom: 12px;
}

.date-input-group {
  display: flex;
  flex-direction: column;
}

.date-label {
  font-weight: 500;
  color: var(--p-text-color);
  margin-bottom: 6px;
  font-size: 0.9rem;
}

.days-selector {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 8px;
  margin-bottom: 12px;
}

.day-option {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 12px 8px;
  border: 2px solid #ddd;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s;
  background: white;
  position: relative;
}

.day-option:hover {
  border-color: var(--p-primary-color);
  background-color: var(--p-surface-hover);
}

.day-option.selected {
  border-color: var(--p-primary-color);
  background-color: var(--p-primary-color);
  color: white;
}

.day-option input[type="checkbox"] {
  position: absolute;
  opacity: 0;
  cursor: pointer;
}

.day-short {
  font-weight: bold;
  font-size: 0.9rem;
  margin-bottom: 2px;
}

.day-full {
  font-size: 0.75rem;
  opacity: 0.8;
}

.quick-select-buttons {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
  margin-top: 12px;
}

.loading-message {
  color: var(--p-primary-color);
  font-size: 0.875rem;
  margin-top: 4px;
}

.warning-message {
  color: var(--p-yellow-600);
  font-size: 0.875rem;
  margin-top: 4px;
  padding: 8px;
  background-color: var(--p-yellow-50);
  border-radius: var(--p-border-radius);
  border: 1px solid var(--p-yellow-200);
}

.next-steps-preview {
  background-color: var(--p-surface-50);
  border-radius: var(--p-border-radius);
  padding: 20px;
  height: fit-content;
}

.next-steps-preview h3 {
  color: var(--p-text-color);
  margin-bottom: 16px;
  font-size: 1.1rem;
}

.step-preview {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.preview-item {
  display: flex;
  align-items: center;
  gap: 12px;
  color: var(--p-text-muted-color);
  font-size: 0.9rem;
}

.preview-icon {
  font-size: 1.2rem;
}

.info-note {
  margin-top: 20px;
  padding: 15px;
  background-color: var(--p-blue-50);
  border: 1px solid var(--p-blue-200);
  border-radius: var(--p-border-radius);
}

.info-note p {
  margin: 0;
  color: var(--p-blue-600);
  font-size: 0.9rem;
  line-height: 1.4;
}

@media (max-width: 768px) {
  .form-content {
    grid-template-columns: 1fr;
    gap: 20px;
  }
  
  
  .radio-option {
    flex-direction: column;
    align-items: flex-start;
    gap: 4px;
  }
  
  .radio-description {
    margin-left: 0;
  }
  
  .days-selector {
    grid-template-columns: repeat(4, 1fr);
    gap: 6px;
  }
  
  .day-option {
    padding: 8px 4px;
  }
  
  .day-short {
    font-size: 0.8rem;
  }
  
  .day-full {
    font-size: 0.7rem;
  }
  
  .quick-select-buttons {
    justify-content: center;
  }
  
  .date-range-inputs {
    grid-template-columns: 1fr;
    gap: 15px;
  }
}
</style>