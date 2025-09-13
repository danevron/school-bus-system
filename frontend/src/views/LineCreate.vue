<template>
  <div class="line-create-container">
    <header class="header">
      <div class="header-content">
        <h1>Create New Line</h1>
        <div class="header-actions">
          <Button 
            @click="goBack" 
            icon="pi pi-arrow-left"
            label="Back to Lines"
            severity="secondary"
            outlined
          />
          <Button 
            @click="handleSave" 
            icon="pi pi-check"
            label="Create Line"
            severity="success"
            :disabled="!isFormValid"
          />
        </div>
      </div>
    </header>

    <main class="main-content">
      <Card class="form-card">
        <template #content>
          <!-- Form Content -->
          <div class="form-content">
            <div class="form-section">
              <h2>Line Information</h2>
              <p class="section-description">
                Create a new transportation line. You can assign students and configure routes after creating the line.
              </p>

              <div class="form-group">
                <label for="lineName" class="form-label">Line Name *</label>
                <InputText
                  id="lineName"
                  v-model="formData.name"
                  placeholder="Enter line name (e.g., Downtown Elementary Route)"
                  maxlength="100"
                  :invalid="!!errors.name"
                  @blur="validateField('name')"
                  @input="clearFieldError('name')"
                />
                <div v-if="errors.name" class="error-message">{{ errors.name }}</div>
                <div class="field-hint">Choose a descriptive name for easy identification</div>
              </div>

              <div class="form-group">
                <label for="driver" class="form-label">Assigned Driver *</label>
                <Select
                  id="driver"
                  v-model="formData.driverId"
                  :options="availableDrivers"
                  optionLabel="displayName"
                  optionValue="_id"
                  placeholder="Select a driver..."
                  :invalid="!!errors.driverId"
                  :loading="loadingDrivers"
                  @change="validateField('driverId')"
                />
                <div v-if="errors.driverId" class="error-message">{{ errors.driverId }}</div>
                <div v-if="loadingDrivers" class="loading-message">Loading available drivers...</div>
                <div v-else-if="availableDrivers.length === 0" class="warning-message">
                  No available drivers found. You may need to create driver accounts first.
                </div>
              </div>

              <div class="form-group">
                <label for="vehicle" class="form-label">Assigned Vehicle *</label>
                <Select
                  id="vehicle"
                  v-model="formData.vehicleId"
                  :options="availableVehicles"
                  optionLabel="displayName"
                  optionValue="_id"
                  placeholder="Select a vehicle..."
                  :invalid="!!errors.vehicleId"
                  :loading="loadingVehicles"
                  @change="validateField('vehicleId')"
                />
                <div v-if="errors.vehicleId" class="error-message">{{ errors.vehicleId }}</div>
                <div v-if="loadingVehicles" class="loading-message">Loading available vehicles...</div>
                <div v-else-if="availableVehicles.length === 0" class="warning-message">
                  No available vehicles found. You may need to create vehicle records first.
                </div>
              </div>

              <div class="form-group">
                <label class="form-label">Schedule Period *</label>
                <p class="field-description">Set the operating period for this line</p>
                
                <div class="date-range-inputs">
                  <div class="date-input-group">
                    <label for="startDate" class="date-label">Start Date</label>
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
                    <label for="endDate" class="date-label">End Date</label>
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
                
                <div class="field-hint">
                  Duration: {{ calculateDuration() }}
                </div>
              </div>

              <div class="form-group">
                <label class="form-label">Operating Days *</label>
                <p class="field-description">Select the days of the week this line will operate</p>
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
                  Selected days: {{ formatSelectedDays() || 'None selected' }}
                </div>
                
                <!-- Quick selection buttons -->
                <div class="quick-select-buttons">
                  <Button 
                    type="button" 
                    @click="selectWeekdays" 
                    label="Weekdays Only"
                    size="small"
                    :severity="isWeekdaysSelected() ? 'primary' : 'secondary'"
                    :outlined="!isWeekdaysSelected()"
                  />
                  <Button 
                    type="button" 
                    @click="selectAllDays" 
                    label="All Days"
                    size="small"
                    :severity="isAllDaysSelected() ? 'primary' : 'secondary'"
                    :outlined="!isAllDaysSelected()"
                  />
                  <Button 
                    type="button" 
                    @click="clearSchedule" 
                    label="Clear All"
                    size="small"
                    severity="secondary"
                    outlined
                  />
                </div>
              </div>

              <div class="form-group">
                <label for="rideStartTime" class="form-label">Ride Start Time *</label>
                <p class="field-description">Set the daily departure time for this line</p>
                <InputMask
                  id="rideStartTime"
                  v-model="formData.rideStartTime"
                  mask="99:99"
                  placeholder="HH:MM"
                  :invalid="!!errors.rideStartTime"
                  @blur="validateField('rideStartTime')"
                  @input="clearFieldError('rideStartTime')"
                />
                <div v-if="errors.rideStartTime" class="error-message">{{ errors.rideStartTime }}</div>
                <div class="field-hint">
                  The time when the bus will start its route each operating day (24-hour format)
                </div>
              </div>

            </div>
          </div> 
          <!-- After Creation Info -->
          <div class="next-steps-preview">
            <h3>After Creating the Line</h3>
            <div class="step-preview">
              <div class="preview-item">
                <span class="preview-icon">🗺️</span>
                <span>Create or assign a route with pickup and dropoff stops</span>
              </div>
              <div class="preview-item">
                <span class="preview-icon">👥</span>
                <span>Assign students to the line and configure their stops</span>
              </div>
              <div class="preview-item">
                <span class="preview-icon">🚌</span>
                <span>Assign a vehicle for transportation services</span>
              </div>
            </div>
            <div class="info-note">
              <p><strong>Note:</strong> You can configure routes and assign students after creating the line through the line management interface.</p>
            </div>
          </div>
        </template>
      </Card>
    </main>
  </div>
</template>

<script>
import { ref, inject, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import apiService from '../services/api'

export default {
  name: 'LineCreate',
  setup() {
    const authStore = inject('authStore')
    const router = useRouter()
    
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
    
    const weekDays = [
      { value: 'sunday', short: 'Sun', full: 'Sunday' },
      { value: 'monday', short: 'Mon', full: 'Monday' },
      { value: 'tuesday', short: 'Tue', full: 'Tuesday' },
      { value: 'wednesday', short: 'Wed', full: 'Wednesday' },
      { value: 'thursday', short: 'Thu', full: 'Thursday' },
      { value: 'friday', short: 'Fri', full: 'Friday' },
      { value: 'saturday', short: 'Sat', full: 'Saturday' }
    ]
    
    // Computed properties for PrimeVue components
    const todayDate = computed(() => new Date())
    
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
            errors.value.name = 'Line name is required'
          } else if (formData.value.name.length < 3) {
            errors.value.name = 'Line name must be at least 3 characters'
          }
          break
        case 'driverId':
          if (!formData.value.driverId) {
            errors.value.driverId = 'Please select a driver'
          }
          break
        case 'vehicleId':
          if (!formData.value.vehicleId) {
            errors.value.vehicleId = 'Please select a vehicle'
          }
          break
        case 'startDate':
          if (!formData.value.startDate) {
            errors.value.startDate = 'Start date is required'
          } else if (new Date(formData.value.startDate) < new Date().setHours(0,0,0,0)) {
            errors.value.startDate = 'Start date cannot be in the past'
          }
          break
        case 'endDate':
          if (!formData.value.endDate) {
            errors.value.endDate = 'End date is required'
          } else if (formData.value.startDate && new Date(formData.value.endDate) < new Date(formData.value.startDate)) {
            errors.value.endDate = 'End date must be after start date'
          }
          break
        case 'scheduleDays':
          if (!formData.value.scheduleDays.length) {
            errors.value.scheduleDays = 'Please select at least one day'
          }
          break
        case 'rideStartTime':
          if (!formData.value.rideStartTime) {
            errors.value.rideStartTime = 'Ride start time is required'
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
        alert('Failed to create line. Please try again.')
      }
    }
    
    const formatSelectedDays = () => {
      if (!formData.value.scheduleDays.length) return ''
      return weekDays
        .filter(day => formData.value.scheduleDays.includes(day.value))
        .map(day => day.short)
        .join(', ')
    }
    
    const getTodayDate = () => {
      const today = new Date()
      return today.toISOString().split('T')[0]
    }
    
    const calculateDuration = () => {
      if (!formData.value.startDate || !formData.value.endDate) {
        return 'Select both dates to see duration'
      }
      
      const start = new Date(formData.value.startDate)
      const end = new Date(formData.value.endDate)
      const diffTime = Math.abs(end - start)
      const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24)) + 1 // +1 to include both start and end date
      
      if (diffDays === 1) {
        return '1 day'
      } else if (diffDays < 30) {
        return `${diffDays} days`
      } else if (diffDays < 365) {
        const weeks = Math.floor(diffDays / 7)
        const remainingDays = diffDays % 7
        return weeks > 0 ? `${weeks} week${weeks > 1 ? 's' : ''}${remainingDays > 0 ? ` ${remainingDays} day${remainingDays > 1 ? 's' : ''}` : ''}` : `${diffDays} days`
      } else {
        const years = Math.floor(diffDays / 365)
        return `${years} year${years > 1 ? 's' : ''}`
      }
    }
    
    const selectWeekdays = () => {
      formData.value.scheduleDays = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday']
      clearFieldError('scheduleDays')
    }
    
    const selectAllDays = () => {
      formData.value.scheduleDays = weekDays.map(day => day.value)
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
      formData,
      errors,
      availableDrivers,
      loadingDrivers,
      availableVehicles,
      loadingVehicles,
      weekDays,
      todayDate,
      isFormValid,
      validateField,
      clearFieldError,
      getTodayDate,
      calculateDuration,
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
.line-create-container {
  min-height: 100vh;
  background-color: var(--p-surface-ground);
}

.header {
  background-color: var(--p-primary-color);
  color: white;
  padding: 1rem 0;
  box-shadow: var(--p-card-shadow);
}

.header-content {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header h1 {
  margin: 0;
  font-size: 1.8rem;
}

.header-actions {
  display: flex;
  gap: 15px;
}

.main-content {
  max-width: 1200px;
  margin: 0 auto;
  padding: 30px 20px;
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
  .header-content {
    flex-direction: column;
    gap: 15px;
    text-align: center;
  }
  
  .header-actions {
    justify-content: center;
  }
  
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