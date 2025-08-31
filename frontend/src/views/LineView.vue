<template>
  <div class="line-view-container">
    <header class="header">
      <div class="header-content">
        <div class="header-info">
          <h1 v-if="line">{{ line.name }}</h1>
          <h1 v-else>Line Details</h1>
          <div class="status-badge" v-if="line" :class="line.isActive ? 'active' : 'inactive'">
            {{ line.isActive ? 'Active' : 'Inactive' }}
          </div>
        </div>
        <div class="header-actions">
          <button @click="goBack" class="back-button">← Back to Lines</button>
          <button @click="handleEdit" class="edit-button" :disabled="!line">
            Edit Line
          </button>
        </div>
      </div>
    </header>

    <main class="main-content">
      <div v-if="loading" class="loading-container">
        <div class="loading">Loading line details...</div>
      </div>

      <div v-else-if="error" class="error-container">
        <div class="error-message">
          <h3>Error Loading Line</h3>
          <p>{{ error }}</p>
          <button @click="fetchLine" class="retry-button">Try Again</button>
        </div>
      </div>

      <div v-else-if="line" class="content-grid">
        <!-- Active Line Notice -->
        <div v-if="line.isActive" class="notice-section">
          <div class="notice active-notice">
            <div class="notice-icon">⚠️</div>
            <div class="notice-content">
              <h3>Active Line Notice</h3>
              <p>
                This line is currently <strong>active</strong> and rides are being generated from it. 
                Changes to this line should only be made for adding/removing students or modifying the route. 
                Other modifications may affect existing rides and schedules.
              </p>
            </div>
          </div>
        </div>

        <!-- Basic Information Section -->
        <div class="info-section">
          <h2>Line Information</h2>
          <div class="info-grid">
            <div class="info-item">
              <label>Line Name</label>
              <span>{{ line.name }}</span>
            </div>
            <div class="info-item">
              <label>Status</label>
              <span class="status" :class="line.isActive ? 'active' : 'inactive'">
                {{ line.isActive ? 'Active' : 'Inactive' }}
              </span>
            </div>
            <div class="info-item">
              <label>Created</label>
              <span>{{ formatDate(line.createdAt) }}</span>
            </div>
            <div class="info-item">
              <label>Last Updated</label>
              <span>{{ formatDate(line.updatedAt) }}</span>
            </div>
          </div>
        </div>

        <!-- Assignment Details Section -->
        <div class="assignment-section">
          <h2>Assignments</h2>
          <div class="assignment-grid">
            <div class="assignment-item">
              <div class="assignment-header">
                <span class="assignment-icon">👨‍✈️</span>
                <span class="assignment-label">Driver</span>
              </div>
              <div class="assignment-value">
                {{ getDriverName(line.driver) }}
              </div>
            </div>
            
            <div class="assignment-item">
              <div class="assignment-header">
                <span class="assignment-icon">🚌</span>
                <span class="assignment-label">Vehicle</span>
              </div>
              <div class="assignment-value">
                {{ getVehicleName(line.vehicle) }}
              </div>
            </div>
            
            <div class="assignment-item">
              <div class="assignment-header">
                <span class="assignment-icon">👥</span>
                <span class="assignment-label">Students</span>
              </div>
              <div class="assignment-value">
                {{ line.students?.length || 0 }} assigned
                <span v-if="line.maxCapacity" class="capacity">
                  ({{ line.students?.length || 0 }}/{{ line.maxCapacity }})
                </span>
              </div>
            </div>
          </div>
        </div>

        <!-- Schedule Section -->
        <div class="schedule-section">
          <h2>Schedule</h2>
          <div class="schedule-details">
            <div class="schedule-item">
              <label>Duration</label>
              <span>{{ formatScheduleDuration(line.schedule) }}</span>
            </div>
            <div class="schedule-item">
              <label>Operating Days</label>
              <span class="operating-days">{{ formatScheduleDays(line.schedule) }}</span>
            </div>
            <div class="schedule-item">
              <label>Schedule Type</label>
              <span class="schedule-type">{{ formatScheduleType(line.schedule?.type) }}</span>
            </div>
          </div>
        </div>

        <!-- Route Management Section - Placeholder -->
        <div class="route-section placeholder-section">
          <div class="section-header">
            <h2>Route Management</h2>
            <button class="section-action-btn" disabled>
              {{ line.route ? 'Edit Route' : 'Assign Route' }}
            </button>
          </div>
          <div class="placeholder-content">
            <div class="placeholder-icon">🗺️</div>
            <div class="placeholder-text">
              <h3>{{ line.route ? 'Route Configuration' : 'No Route Assigned' }}</h3>
              <p v-if="line.route">
                Route management features will be available here. You'll be able to view stops, 
                modify the route, and manage pickup/dropoff locations.
              </p>
              <p v-else>
                This line doesn't have a route assigned yet. Route assignment and management 
                features will be available here.
              </p>
            </div>
          </div>
        </div>

        <!-- Student Assignment Section - Placeholder -->
        <div class="students-section placeholder-section">
          <div class="section-header">
            <h2>Student Assignment</h2>
            <button class="section-action-btn" disabled>
              Manage Students
            </button>
          </div>
          <div class="placeholder-content">
            <div class="placeholder-icon">👥</div>
            <div class="placeholder-text">
              <h3>Student Management</h3>
              <p>
                Student assignment features will be available here. You'll be able to:
              </p>
              <ul class="feature-list">
                <li>Assign students to this line</li>
                <li>Set pickup and dropoff stops for each student</li>
                <li>Manage student capacity and seating</li>
                <li>View student contact information</li>
              </ul>
            </div>
          </div>
        </div>
      </div>

      <div v-else class="not-found-container">
        <div class="not-found">
          <h3>Line Not Found</h3>
          <p>The requested line could not be found.</p>
          <button @click="goBack" class="back-button">Back to Lines</button>
        </div>
      </div>
    </main>
  </div>
</template>

<script>
import { ref, inject, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import apiService from '../services/api'

export default {
  name: 'LineView',
  setup() {
    const authStore = inject('authStore')
    const router = useRouter()
    const route = useRoute()
    
    const line = ref(null)
    const loading = ref(false)
    const error = ref(null)
    
    const fetchLine = async () => {
      const lineId = route.params.id
      if (!lineId) {
        error.value = 'No line ID provided'
        return
      }
      
      try {
        loading.value = true
        error.value = null
        const response = await apiService.get(`/lines/${lineId}`)
        line.value = response.line || response.data
      } catch (err) {
        console.error('Failed to fetch line:', err)
        error.value = err.response?.data?.message || 'Failed to load line details'
      } finally {
        loading.value = false
      }
    }
    
    const formatDate = (dateString) => {
      return new Date(dateString).toLocaleDateString()
    }
    
    const formatScheduleDuration = (schedule) => {
      if (!schedule || !schedule.startDate) {
        return 'No schedule set'
      }
      
      const start = new Date(schedule.startDate)
      const end = schedule.endDate ? new Date(schedule.endDate) : null
      
      if (!end) {
        return `From ${start.toLocaleDateString()}`
      }
      
      return `${start.toLocaleDateString()} - ${end.toLocaleDateString()}`
    }
    
    const formatScheduleDays = (schedule) => {
      if (!schedule || !schedule.daysOfWeek || schedule.daysOfWeek.length === 0) {
        return 'No days selected'
      }
      
      const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
      const selectedDays = schedule.daysOfWeek
        .sort((a, b) => a - b)
        .map(dayNum => dayNames[dayNum])
      
      if (selectedDays.length === 7) {
        return 'Every day'
      } else if (selectedDays.length === 5 && 
                 schedule.daysOfWeek.includes(0) && 
                 schedule.daysOfWeek.includes(1) && 
                 schedule.daysOfWeek.includes(2) && 
                 schedule.daysOfWeek.includes(3) && 
                 schedule.daysOfWeek.includes(4)) {
        return 'Sun-Thu (Weekdays)'
      } else if (selectedDays.length === 2 && 
                 schedule.daysOfWeek.includes(0) && 
                 schedule.daysOfWeek.includes(6)) {
        return 'Sat-Sun (Weekends)'
      } else {
        return selectedDays.join(', ')
      }
    }
    
    const formatScheduleType = (type) => {
      const typeMap = {
        daily: 'Daily',
        weekdays: 'Weekdays',
        weekends: 'Weekends',
        custom: 'Custom'
      }
      return typeMap[type] || type || 'Not specified'
    }
    
    const getDriverName = (driver) => {
      if (!driver) return 'No driver assigned'
      if (typeof driver === 'string') return 'Driver assigned'
      return `${driver.firstName || ''} ${driver.lastName || ''}`.trim() || 'Driver assigned'
    }
    
    const getVehicleName = (vehicle) => {
      if (!vehicle) return 'No vehicle assigned'
      if (typeof vehicle === 'string') return 'Vehicle assigned'
      return vehicle.licensePlate || 'Vehicle assigned'
    }
    
    const handleEdit = () => {
      if (line.value) {
        router.push(`/lines/${line.value._id}/edit`)
      }
    }
    
    const goBack = () => {
      router.push('/lines')
    }
    
    onMounted(async () => {
      await fetchLine()
    })
    
    return {
      line,
      loading,
      error,
      fetchLine,
      formatDate,
      formatScheduleDuration,
      formatScheduleDays,
      formatScheduleType,
      getDriverName,
      getVehicleName,
      handleEdit,
      goBack
    }
  }
}
</script>

<style scoped>
.line-view-container {
  min-height: 100vh;
  background-color: #f8f9fa;
}

.header {
  background-color: #007bff;
  color: white;
  padding: 1rem 0;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.header-content {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-info {
  display: flex;
  align-items: center;
  gap: 15px;
}

.header-info h1 {
  margin: 0;
  font-size: 1.8rem;
}

.status-badge {
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 0.8rem;
  font-weight: bold;
  text-transform: uppercase;
}

.status-badge.active {
  background-color: #28a745;
  color: white;
}

.status-badge.inactive {
  background-color: #6c757d;
  color: white;
}

.header-actions {
  display: flex;
  gap: 12px;
}

.back-button, .edit-button {
  padding: 8px 16px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  transition: background-color 0.2s;
  font-weight: 500;
}

.back-button {
  background-color: #6c757d;
  color: white;
}

.back-button:hover {
  background-color: #545b62;
}

.edit-button {
  background-color: #28a745;
  color: white;
}

.edit-button:hover:not(:disabled) {
  background-color: #218838;
}

.edit-button:disabled {
  background-color: #ccc;
  cursor: not-allowed;
}

.main-content {
  max-width: 1200px;
  margin: 0 auto;
  padding: 30px 20px;
}

.loading-container, .error-container, .not-found-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 400px;
}

.loading {
  font-size: 1.1rem;
  color: #666;
}

.error-message, .not-found {
  text-align: center;
  background: white;
  padding: 40px;
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
}

.error-message h3, .not-found h3 {
  color: #dc3545;
  margin-bottom: 15px;
}

.retry-button {
  background-color: #007bff;
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 4px;
  cursor: pointer;
  margin-top: 15px;
}

.content-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 30px;
  grid-template-areas:
    "notice notice"
    "info assignment"
    "schedule schedule"
    "route route"
    "students students";
}

.notice-section {
  grid-area: notice;
}

.info-section {
  grid-area: info;
}

.assignment-section {
  grid-area: assignment;
}

.schedule-section {
  grid-area: schedule;
}

.route-section {
  grid-area: route;
}

.students-section {
  grid-area: students;
}

.notice-section {
  margin-bottom: 10px;
}

.notice {
  display: flex;
  align-items: flex-start;
  gap: 15px;
  padding: 20px;
  border-radius: 8px;
  border-left: 4px solid;
}

.active-notice {
  background-color: #fff3cd;
  border-left-color: #ffc107;
  color: #856404;
}

.notice-icon {
  font-size: 1.5rem;
  margin-top: 2px;
}

.notice-content h3 {
  margin: 0 0 8px 0;
  font-size: 1.1rem;
  color: #856404;
}

.notice-content p {
  margin: 0;
  line-height: 1.5;
  font-size: 0.95rem;
}

.info-section, .assignment-section, .schedule-section, .route-section, .students-section {
  background: white;
  border-radius: 8px;
  padding: 30px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
}

.info-section h2, .assignment-section h2, .schedule-section h2 {
  margin: 0 0 20px 0;
  color: #333;
  font-size: 1.3rem;
}

.info-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
}

.info-item {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.info-item label {
  font-weight: 600;
  color: #666;
  font-size: 0.9rem;
}

.info-item span {
  color: #333;
  font-size: 1rem;
}

.status.active {
  color: #28a745;
  font-weight: 600;
}

.status.inactive {
  color: #6c757d;
  font-weight: 600;
}

.assignment-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 20px;
}

.assignment-item {
  padding: 15px;
  background-color: #f8f9fa;
  border-radius: 6px;
  border-left: 4px solid #007bff;
}

.assignment-header {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 8px;
}

.assignment-icon {
  font-size: 1.2rem;
}

.assignment-label {
  font-weight: 600;
  color: #666;
  font-size: 0.9rem;
}

.assignment-value {
  color: #333;
  font-size: 1rem;
}

.capacity {
  color: #666;
  font-size: 0.9rem;
}

.schedule-details {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 20px;
}

.schedule-item {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.schedule-item label {
  font-weight: 600;
  color: #666;
  font-size: 0.9rem;
}

.operating-days {
  color: #28a745;
  font-weight: 500;
}

.schedule-type {
  color: #007bff;
  font-weight: 500;
}

/* Placeholder Sections */
.placeholder-section {
  border: 2px dashed #ddd;
  background-color: #fafafa;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 25px;
}

.section-header h2 {
  margin: 0;
  color: #333;
  font-size: 1.3rem;
}

.section-action-btn {
  background-color: #007bff;
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.9rem;
}

.section-action-btn:disabled {
  background-color: #ccc;
  cursor: not-allowed;
}

.placeholder-content {
  display: flex;
  align-items: flex-start;
  gap: 20px;
  color: #666;
}

.placeholder-icon {
  font-size: 3rem;
  opacity: 0.5;
}

.placeholder-text h3 {
  margin: 0 0 10px 0;
  color: #333;
  font-size: 1.1rem;
}

.placeholder-text p {
  margin: 0 0 15px 0;
  line-height: 1.5;
}

.feature-list {
  margin: 0;
  padding-left: 20px;
}

.feature-list li {
  margin-bottom: 5px;
}

@media (max-width: 768px) {
  .header-content {
    flex-direction: column;
    gap: 15px;
    text-align: center;
  }
  
  .header-info {
    flex-direction: column;
    gap: 10px;
  }
  
  .header-actions {
    justify-content: center;
  }
  
  .content-grid {
    grid-template-columns: 1fr;
    gap: 20px;
    grid-template-areas:
      "notice"
      "info"
      "assignment"
      "schedule"
      "route"
      "students";
  }
  
  .info-grid {
    grid-template-columns: 1fr;
    gap: 15px;
  }
  
  .schedule-details {
    grid-template-columns: 1fr;
    gap: 15px;
  }
  
  .placeholder-content {
    flex-direction: column;
    text-align: center;
    gap: 15px;
  }
}
</style>