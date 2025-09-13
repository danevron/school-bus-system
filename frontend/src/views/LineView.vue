<template>
  <AppLayout 
    :page-title="line ? line.name : 'Line Details'"
    :breadcrumbs="breadcrumbs"
  >
    <template #actions>
      <div v-if="line" class="status-badge" :class="line.isActive ? 'active' : 'inactive'">
        {{ line.isActive ? 'Active' : 'Inactive' }}
      </div>
      <Button 
        @click="goBack" 
        icon="pi pi-arrow-left"
        label="Back to Lines"
        severity="secondary"
        outlined
      />
      <Button 
        v-if="canActivateLine"
        @click="activateLineAction" 
        icon="pi pi-play"
        :label="activating ? 'Activating...' : 'Activate Line'"
        severity="warning"
        :loading="activating"
        :disabled="activating"
      />
      <Button 
        @click="manageRoute" 
        icon="pi pi-cog"
        label="Manage Stops and Students"
        severity="success"
        :disabled="!line"
      />
    </template>
    
    <div v-if="loading" class="loading-container">
        <div class="loading">Loading line details...</div>
      </div>

      <div v-else-if="error" class="error-container">
        <div class="error-message">
          <h3>Error Loading Line</h3>
          <p>{{ error }}</p>
          <Button @click="fetchLine" label="Try Again" icon="pi pi-refresh" severity="info" />
        </div>
      </div>

      <!-- Success Message -->
      <div v-if="successMessage" class="success-message-container">
        <div class="success-message">
          <div class="success-icon">✓</div>
          <span>{{ successMessage }}</span>
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
                This line is currently <strong>active</strong> and providing scheduled transportation services. 
                Changes to this line should be made carefully as they may affect ongoing schedules and student assignments.
              </p>
            </div>
          </div>
        </div>

        <!-- Basic Information Section -->
        <Card class="info-section">
          <template #header>
            <div class="section-header-card">
              <h2><i class="pi pi-info-circle"></i>Line Information</h2>
            </div>
          </template>
          <template #content>
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
          </template>
        </Card>

        <!-- Assignment Details Section -->
        <Card class="assignment-section">
          <template #header>
            <div class="section-header-card">
              <h2><i class="pi pi-users"></i>Assignments</h2>
            </div>
          </template>
          <template #content>
            <div class="assignment-grid">
              <div class="assignment-item">
                <div class="assignment-header">
                  <i class="pi pi-user assignment-icon"></i>
                  <span class="assignment-label">Driver</span>
                </div>
                <div class="assignment-value">
                  {{ getDriverName(line.driver) }}
                </div>
              </div>
              
              <div class="assignment-item">
                <div class="assignment-header">
                  <i class="pi pi-car assignment-icon"></i>
                  <span class="assignment-label">Vehicle</span>
                </div>
                <div class="assignment-value">
                  {{ getVehicleName(line.vehicle) }}
                </div>
              </div>
              
              <div class="assignment-item">
                <div class="assignment-header">
                  <i class="pi pi-users assignment-icon"></i>
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
          </template>
        </Card>

        <!-- Schedule Section -->
        <Card class="schedule-section">
          <template #header>
            <div class="section-header-card">
              <h2><i class="pi pi-calendar"></i>Schedule</h2>
            </div>
          </template>
          <template #content>
            <div class="schedule-details">
              <div class="schedule-item">
                <label><i class="pi pi-clock"></i> Ride Start Time</label>
                <span class="start-time">{{ formatTime(line.rideStartTime) }}</span>
              </div>
              <div class="schedule-item">
                <label><i class="pi pi-calendar-times"></i> Duration</label>
                <span>{{ formatScheduleDuration(line.schedule) }}</span>
              </div>
              <div class="schedule-item">
                <label><i class="pi pi-calendar-plus"></i> Operating Days</label>
                <span class="operating-days">{{ formatScheduleDays(line.schedule) }}</span>
              </div>
              <div class="schedule-item">
                <label><i class="pi pi-tags"></i> Schedule Type</label>
                <span class="schedule-type">{{ formatScheduleType(line.schedule?.type) }}</span>
              </div>
            </div>
          </template>
        </Card>

        <!-- Route Management Section -->
        <Card class="route-section">
          <template #header>
            <div class="section-header-card">
              <h2><i class="pi pi-map"></i>Route Management</h2>
            </div>
          </template>
          <template #content>
            <div class="route-content">
              <div v-if="line.route && line.route.stops && line.route.stops.length > 0" class="route-summary">
                <div class="route-stats">
                  <div class="stat">
                    <span class="stat-icon">📍</span>
                    <div class="stat-info">
                      <span class="stat-value">{{ line.route.stops.length }}</span>
                      <span class="stat-label">Stops</span>
                    </div>
                  </div>
                  <div class="stat">
                    <span class="stat-icon">📏</span>
                    <div class="stat-info">
                      <span class="stat-value">{{ line.route.totalDistance || 0 }}km</span>
                      <span class="stat-label">Distance</span>
                    </div>
                  </div>
                  <div class="stat">
                    <span class="stat-icon">⏱️</span>
                    <div class="stat-info">
                      <span class="stat-value">{{ line.route.estimatedDuration || 0 }}min</span>
                      <span class="stat-label">Duration</span>
                    </div>
                  </div>
                </div>
                <div class="route-stops">
                  <h4><i class="pi pi-map-marker"></i>Route Stops</h4>
                  <div class="stops-timeline">
                    <div 
                      v-for="(stop, index) in line.route.stops" 
                      :key="index"
                      class="stop-item"
                      :class="{ 
                        'pickup-stop': stop.type === 'pickup',
                        'dropoff-stop': stop.type === 'dropoff'
                      }"
                    >
                      <div class="stop-marker">
                        <div class="stop-number">{{ index + 1 }}</div>
                        <div class="stop-type-icon">
                          <span v-if="stop.type === 'pickup'">📍</span>
                          <span v-else>🏁</span>
                        </div>
                      </div>

                      <div class="stop-content">
                        <div class="stop-header">
                          <h3 class="stop-name">{{ stop.name }}</h3>
                          <div class="stop-actions">
                            <div class="stop-badges">
                              <span class="type-badge" :class="stop.type">
                                {{ stop.type }}
                              </span>
                              <span class="time-badge" v-if="stop.estimatedTime">
                                {{ formatTime(stop.estimatedTime) }}
                              </span>
                            </div>
                          </div>
                        </div>

                        <div class="stop-details">
                          <div class="stop-address" v-if="stop.address">
                            <strong>Address:</strong> {{ stop.address }}
                          </div>
                          <div class="stop-time" v-if="stop.estimatedTime">
                            <strong>Estimated Time:</strong> {{ stop.estimatedTime }} minutes from start
                          </div>
                          <div v-if="getStopStudents(stop).pickup.length > 0 || getStopStudents(stop).dropoff.length > 0" class="stop-usage-info">
                            <div class="usage-indicator">
                              <span class="usage-icon">👥</span>
                              <span class="usage-text">
                                {{ (getStopStudents(stop).pickup.length + getStopStudents(stop).dropoff.length) }} student{{ (getStopStudents(stop).pickup.length + getStopStudents(stop).dropoff.length) !== 1 ? 's' : '' }} assigned
                              </span>
                              <span class="usage-details">
                                ({{ getStopStudents(stop).pickup.length }} pickup, {{ getStopStudents(stop).dropoff.length }} dropoff)
                              </span>
                            </div>
                            <div class="assigned-students">
                              <div v-if="getStopStudents(stop).pickup.length > 0" class="student-group pickup">
                                <span class="group-label">Pickup:</span>
                                {{ getStopStudents(stop).pickup.map(s => `${s.firstName} ${s.lastName}`).join(', ') }}
                              </div>
                              <div v-if="getStopStudents(stop).dropoff.length > 0" class="student-group dropoff">
                                <span class="group-label">Dropoff:</span>
                                {{ getStopStudents(stop).dropoff.map(s => `${s.firstName} ${s.lastName}`).join(', ') }}
                              </div>
                            </div>
                          </div>
                          <div v-else class="no-students-assigned">
                            <span class="usage-icon">👥</span>
                            <span class="usage-text muted">No students assigned to this stop</span>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              <div v-else class="empty-route">
                <div class="empty-icon">🗺️</div>
                <div class="empty-text">
                  <h3>No Route Configured</h3>
                  <p>
                    This line doesn't have any stops configured yet. Click "Manage Route" 
                    to add stops and configure the pickup and dropoff locations.
                  </p>
                </div>
              </div>
            </div>
          </template>
        </Card>

        <!-- Assigned Students Section -->
        <Card class="students-section">
          <template #header>
            <div class="section-header-card">
              <h2><i class="pi pi-users"></i>Assigned Students</h2>
              <span class="student-count">{{ studentAssignments.length }} students</span>
            </div>
          </template>
          <template #content>
          
            <div v-if="studentAssignments.length === 0" class="no-students">
              <div class="empty-icon">👥</div>
              <div class="empty-text">
                <h3>No Students Assigned</h3>
                <p>No students are currently assigned to this line. Use the Route Manager to add students and configure their pickup/dropoff stops.</p>
              </div>
            </div>
            
            <div v-else class="students-list">
              <div
                v-for="assignment in studentAssignments"
                :key="assignment._id"
                class="student-assignment-card"
              >
                <div class="student-header">
                  <div class="student-avatar">
                    <Avatar 
                      :label="`${assignment.student.firstName[0]}${assignment.student.lastName[0]}`"
                      size="large"
                      shape="circle"
                    />
                  </div>
                  <div class="student-info">
                    <div class="student-name">
                      <i class="pi pi-user"></i>
                      {{ assignment.student.firstName }} {{ assignment.student.lastName }}
                    </div>
                    <div class="student-contact">
                      <span class="contact-item phone">
                        <i class="pi pi-phone"></i>
                        {{ assignment.student.phone }}
                      </span>
                      <span v-if="assignment.student.email" class="contact-item email">
                        <i class="pi pi-envelope"></i>
                        {{ assignment.student.email }}
                      </span>
                    </div>
                  </div>
                </div>

                <div class="assignment-details">
                  <div class="stops-row">
                    <div class="stop-assignment pickup">
                      <div class="stop-header">
                        <i class="pi pi-sign-in stop-icon pickup-icon"></i>
                        <span class="stop-label">Pickup</span>
                      </div>
                      <div v-if="assignment.pickupStopDetails" class="stop-content">
                        <div class="stop-name">{{ assignment.pickupStopDetails.name }}</div>
                        <div class="stop-time">
                          <i class="pi pi-clock"></i>
                          {{ formatTime(assignment.pickupStopDetails.estimatedTime) }}
                        </div>
                      </div>
                      <div v-else class="no-stop-assigned">
                        <span class="not-assigned">Not assigned</span>
                      </div>
                    </div>

                    <div class="stop-assignment dropoff">
                      <div class="stop-header">
                        <i class="pi pi-sign-out stop-icon dropoff-icon"></i>
                        <span class="stop-label">Dropoff</span>
                      </div>
                      <div v-if="assignment.dropoffStopDetails" class="stop-content">
                        <div class="stop-name">{{ assignment.dropoffStopDetails.name }}</div>
                        <div class="stop-time">
                          <i class="pi pi-clock"></i>
                          {{ formatTime(assignment.dropoffStopDetails.estimatedTime) }}
                        </div>
                      </div>
                      <div v-else class="no-stop-assigned">
                        <span class="not-assigned">Not assigned</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          
            <div v-if="studentAssignments.length > 0" class="capacity-info">
              <div class="capacity-bar">
                <div 
                  class="capacity-filled" 
                  :style="{ width: `${(studentAssignments.length / (line?.maxCapacity || 1)) * 100}%` }"
                ></div>
              </div>
              <div class="capacity-text">
                {{ studentAssignments.length }} / {{ line?.maxCapacity || 0 }} students assigned
              </div>
            </div>
          </template>
        </Card>

        <!-- Route Map Section -->
        <Card v-if="line.route && line.route.stops && line.route.stops.length > 0" class="map-section">
          <template #header>
            <div class="section-header-card">
              <h2><i class="pi pi-map-marker"></i>Route Map</h2>
            </div>
          </template>
          <template #content>
            <RouteMap
              :stops="line.route.stops"
              :studentAssignments="studentAssignments"
              :showDrivingInstructions="false"
              :showDrivingRoute="true"
              mapHeight="600px"
              mapId="line-route-map"
            />
          </template>
        </Card>
      </div>

      <div v-else class="not-found-container">
        <div class="not-found">
          <h3>Line Not Found</h3>
          <p>The requested line could not be found.</p>
          <Button @click="goBack" label="Back to Lines" icon="pi pi-arrow-left" severity="secondary" />
        </div>
      </div>
    </AppLayout>
</template>

<script>
import { ref, inject, onMounted, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import apiService from '../services/api'
import AppLayout from '../components/AppLayout.vue'
import RouteMap from '../components/RouteMap.vue'

export default {
  name: 'LineView',
  components: {
    AppLayout,
    RouteMap
  },
  setup() {
    const authStore = inject('authStore')
    const router = useRouter()
    const route = useRoute()
    
    const breadcrumbs = ref([
      { label: 'Dashboard', path: '/home' },
      { label: 'Line Management', path: '/lines' },
      { label: 'Line Details' }
    ])
    
    const line = ref(null)
    const loading = ref(false)
    const error = ref(null)
    const studentAssignments = ref([])
    const activating = ref(false)
    const successMessage = ref('')
    
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
        
        // Fetch student assignments after getting line data
        if (line.value) {
          await fetchStudentAssignments(lineId)
        }
      } catch (err) {
        console.error('Failed to fetch line:', err)
        error.value = err.response?.data?.message || 'Failed to load line details'
      } finally {
        loading.value = false
      }
    }
    
    const fetchStudentAssignments = async (lineId) => {
      try {
        const response = await apiService.get(`/lines/${lineId}/student-assignments`)
        studentAssignments.value = response.assignments || response.data || []
      } catch (err) {
        console.error('Failed to fetch student assignments:', err)
        studentAssignments.value = []
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
    
    const formatTime = (timeInput) => {
      if (!timeInput && timeInput !== 0) return 'N/A'
      
      // If it's a string (HH:MM format like "07:30"), convert to 12-hour format
      if (typeof timeInput === 'string' && timeInput.includes(':')) {
        const [hours, minutes] = timeInput.split(':')
        const hour12 = hours % 12 || 12
        const ampm = hours < 12 ? 'AM' : 'PM'
        return `${hour12}:${minutes} ${ampm}`
      }
      
      // If it's a number (minutes from start), convert to HH:MM format
      const hours = Math.floor(timeInput / 60)
      const mins = timeInput % 60
      return `${hours.toString().padStart(2, '0')}:${mins.toString().padStart(2, '0')}`
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
    
    const manageRoute = () => {
      if (line.value) {
        router.push(`/lines/${line.value._id}/route`)
      }
    }
    
    const getStopStudents = (stop) => {
      const pickupStudents = studentAssignments.value
        .filter(assignment => 
          assignment.pickupStopDetails && String(assignment.pickupStopDetails.stopId) === String(stop.stopId)
        )
        .map(assignment => assignment.student)
        
      const dropoffStudents = studentAssignments.value
        .filter(assignment => 
          assignment.dropoffStopDetails && String(assignment.dropoffStopDetails.stopId) === String(stop.stopId)
        )
        .map(assignment => assignment.student)

      return { pickup: pickupStudents, dropoff: dropoffStudents }
    }

    // Check if user can activate the line
    const canActivateLine = computed(() => {
      return line.value && 
             !line.value.isActive && 
             authStore.user?.role === 'admin' &&
             line.value.route &&
             line.value.route.stops &&
             line.value.route.stops.length > 0 &&
             studentAssignments.value.length > 0
    })

    // Show success message with auto-hide
    const showSuccessMessage = (message) => {
      successMessage.value = message
      setTimeout(() => {
        successMessage.value = ''
      }, 3000)
    }

    // Activate line function
    const activateLineAction = async () => {
      if (!line.value || activating.value) return
      
      try {
        activating.value = true
        const response = await apiService.post(`/lines/${line.value._id}/activate`)
        
        // Refresh line data to show activated status
        await fetchLine()
        
        showSuccessMessage(
          `Line activated successfully! Generated ${response.generatedRides} future rides.`
        )
      } catch (err) {
        console.error('Failed to activate line:', err)
        const errorMessage = err.response?.data?.message || 'Failed to activate line'
        alert(`Error: ${errorMessage}`)
      } finally {
        activating.value = false
      }
    }
    
    
    onMounted(async () => {
      await fetchLine()
    })
    
    return {
      breadcrumbs,
      line,
      loading,
      error,
      studentAssignments,
      activating,
      successMessage,
      route,
      fetchLine,
      formatDate,
      formatScheduleDuration,
      formatScheduleDays,
      formatScheduleType,
      formatTime,
      getDriverName,
      getVehicleName,
      handleEdit,
      goBack,
      manageRoute,
      getStopStudents,
      canActivateLine,
      activateLineAction
    }
  }
}
</script>

<style scoped>
/* Line view specific styles */

.status-badge {
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 0.8rem;
  font-weight: bold;
  text-transform: uppercase;
}

.status-badge.active {
  background-color: var(--p-green-500);
  color: white;
}

.status-badge.inactive {
  background-color: var(--p-surface-400);
  color: white;
}

/* Card Header Styles */
.section-header-card {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.25rem 1.25rem 0 1.25rem;
}

.section-header-card h2 {
  margin: 0;
  color: var(--p-text-color);
  font-size: 1.3rem;
  display: flex;
  align-items: center;
  gap: 8px;
}

.section-header-card h2 i {
  color: var(--p-primary-color);
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
  color: var(--p-text-muted-color);
}

.error-message, .not-found {
  text-align: center;
  background: var(--p-surface-0);
  padding: 40px;
  border-radius: var(--p-border-radius);
  box-shadow: var(--p-card-shadow);
}

.error-message h3, .not-found h3 {
  color: var(--p-red-500);
  margin-bottom: 15px;
}

.success-message-container {
  position: fixed;
  top: 20px;
  right: 20px;
  z-index: 1001;
  animation: slideInRight 0.3s ease-out;
}

.success-message {
  background: linear-gradient(135deg, var(--p-green-500) 0%, var(--p-green-400) 100%);
  color: white;
  padding: 15px 20px;
  border-radius: var(--p-border-radius);
  box-shadow: 0 4px 12px rgba(40, 167, 69, 0.3);
  display: flex;
  align-items: center;
  gap: 10px;
  font-weight: 500;
  max-width: 350px;
}

.success-icon {
  background: rgba(255, 255, 255, 0.2);
  border-radius: 50%;
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
  font-weight: bold;
}

@keyframes slideInRight {
  from {
    transform: translateX(100%);
    opacity: 0;
  }
  to {
    transform: translateX(0);
    opacity: 1;
  }
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
    "students students"
    "map map";
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

.map-section {
  grid-area: map;
  background: white;
  border-radius: 8px;
  padding: 30px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
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
  background-color: var(--p-yellow-50);
  border-left-color: var(--p-yellow-500);
  color: var(--p-yellow-800);
}

.notice-icon {
  font-size: 1.5rem;
  margin-top: 2px;
}

.notice-content h3 {
  margin: 0 0 8px 0;
  font-size: 1.1rem;
  color: var(--p-yellow-800);
}

.notice-content p {
  margin: 0;
  line-height: 1.5;
  font-size: 0.95rem;
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
  color: var(--p-text-muted-color);
  font-size: 0.9rem;
}

.info-item span {
  color: var(--p-text-color);
  font-size: 1rem;
}

.status.active {
  color: var(--p-green-500);
  font-weight: 600;
}

.status.inactive {
  color: var(--p-surface-400);
  font-weight: 600;
}

.assignment-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 20px;
}

.assignment-item {
  padding: 15px;
  background-color: var(--p-surface-50);
  border-radius: var(--p-border-radius);
  border-left: 4px solid var(--p-primary-color);
}

.assignment-header {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 8px;
}

.assignment-icon {
  font-size: 1.2rem;
  color: var(--p-primary-color);
}

.assignment-label {
  font-weight: 600;
  color: var(--p-text-muted-color);
  font-size: 0.9rem;
}

.assignment-value {
  color: var(--p-text-color);
  font-size: 1rem;
}

.capacity {
  color: var(--p-text-muted-color);
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
  color: var(--p-text-muted-color);
  font-size: 0.9rem;
  display: flex;
  align-items: center;
  gap: 6px;
}

.schedule-item label i {
  color: var(--p-primary-color);
}

.start-time {
  color: var(--p-green-500);
  font-weight: 500;
  font-size: 1.1rem;
}

.operating-days {
  color: var(--p-green-500);
  font-weight: 500;
}

.schedule-type {
  color: var(--p-primary-color);
  font-weight: 500;
}

/* Route Management Section */
.route-content {
  margin-top: 20px;
}

.route-summary {
  display: flex;
  flex-direction: column;
  gap: 25px;
}

.route-stats {
  display: flex;
  gap: 30px;
  flex-wrap: wrap;
}

.stat {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 15px;
  background-color: var(--p-surface-50);
  border-radius: var(--p-border-radius);
  min-width: 140px;
}

.stat-icon {
  font-size: 1.5rem;
}

.stat-info {
  display: flex;
  flex-direction: column;
}

.stat-value {
  font-size: 1.2rem;
  font-weight: 600;
  color: var(--p-text-color);
}

.stat-label {
  font-size: 0.85rem;
  color: var(--p-text-muted-color);
}

.route-stops h4 {
  margin: 0 0 15px 0;
  color: var(--p-text-color);
  font-size: 1.1rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.route-stops h4 i {
  color: var(--p-primary-color);
}

.stops-timeline {
  position: relative;
}

.stop-item {
  position: relative;
  display: flex;
  align-items: flex-start;
  margin-bottom: 30px;
  padding-bottom: 20px;
}

.stop-marker {
  display: flex;
  align-items: center;
  margin-right: 20px;
  position: relative;
  z-index: 2;
}

.stop-number {
  width: 30px;
  height: 30px;
  border-radius: 50%;
  background-color: var(--p-primary-color);
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: bold;
  font-size: 0.9rem;
  margin-right: 10px;
}

.pickup-stop .stop-number {
  background-color: var(--p-cyan-500);
}

.dropoff-stop .stop-number {
  background-color: var(--p-yellow-500);
  color: var(--p-yellow-950);
}

.stop-type-icon {
  font-size: 1.2rem;
}

.stop-content {
  flex: 1;
  background-color: var(--p-surface-50);
  border-radius: var(--p-border-radius);
  padding: 20px;
  border-left: 4px solid var(--p-primary-color);
}

.pickup-stop .stop-content {
  border-left-color: var(--p-cyan-500);
}

.dropoff-stop .stop-content {
  border-left-color: var(--p-yellow-500);
}

.stop-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 15px;
}

.stop-name {
  margin: 0;
  color: var(--p-text-color);
  font-size: 1.1rem;
  flex: 1;
}

.stop-actions {
  display: flex;
  align-items: center;
  gap: 15px;
}

.stop-badges {
  display: flex;
  gap: 8px;
}

.type-badge {
  padding: 4px 8px;
  border-radius: 12px;
  font-size: 0.7rem;
  font-weight: bold;
  text-transform: uppercase;
}

.type-badge.pickup {
  background-color: var(--p-cyan-500);
  color: white;
}

.type-badge.dropoff {
  background-color: var(--p-yellow-500);
  color: var(--p-yellow-950);
}

.time-badge {
  padding: 4px 8px;
  background-color: var(--p-surface-200);
  border-radius: 12px;
  font-size: 0.7rem;
  font-weight: bold;
  color: var(--p-text-color);
}

.stop-details {
  display: grid;
  gap: 8px;
}

.stop-details > div {
  font-size: 0.9rem;
  color: var(--p-text-muted-color);
}

.stop-usage-info {
  margin-top: 12px;
  padding: 8px 12px;
  background-color: var(--p-blue-50);
  border-radius: var(--p-border-radius);
  border-left: 3px solid var(--p-blue-500);
}

.usage-indicator {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-bottom: 4px;
}

.usage-icon {
  font-size: 0.9rem;
}

.usage-text {
  font-weight: 600;
  color: var(--p-blue-600);
  font-size: 0.85rem;
}

.usage-text.muted {
  color: var(--p-text-muted-color);
  font-weight: normal;
}

.usage-details {
  color: var(--p-text-muted-color);
  font-size: 0.75rem;
}

.assigned-students {
  font-size: 0.75rem;
  color: var(--p-text-color);
  font-style: italic;
  line-height: 1.3;
}

.student-group {
  margin: 4px 0;
}

.group-label {
  font-weight: 600;
  color: var(--p-text-color);
}

.no-students-assigned {
  margin-top: 12px;
  padding: 8px 12px;
  background-color: var(--p-surface-100);
  border-radius: var(--p-border-radius);
  border-left: 3px solid var(--p-surface-300);
  display: flex;
  align-items: center;
  gap: 6px;
}

/* Updated timeline styles complete */

.empty-route {
  display: flex;
  align-items: center;
  gap: 20px;
  padding: 40px 20px;
  text-align: left;
  color: var(--p-text-muted-color);
}

.empty-icon {
  font-size: 3rem;
  opacity: 0.5;
}

.empty-text h3 {
  margin: 0 0 10px 0;
  color: var(--p-text-color);
  font-size: 1.1rem;
}

.empty-text p {
  margin: 0;
  line-height: 1.5;
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
      "students"
      "map";
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
  
  .student-assignment-item {
    grid-template-columns: 1fr;
    gap: 15px;
  }
  
  .assignment-details {
    grid-template-columns: 1fr;
    gap: 12px;
  }
}

/* Students Section */
.student-count {
  background-color: #e3f2fd;
  color: #0d47a1;
  padding: 4px 12px;
  border-radius: 16px;
  font-size: 0.85rem;
  font-weight: 600;
}

.no-students {
  display: flex;
  align-items: center;
  gap: 20px;
  padding: 40px 20px;
  text-align: left;
  color: #666;
}

.no-students .empty-icon {
  font-size: 3rem;
  opacity: 0.5;
}

.no-students .empty-text h3 {
  margin: 0 0 10px 0;
  color: #333;
  font-size: 1.1rem;
}

.no-students .empty-text p {
  margin: 0;
  line-height: 1.5;
}

.students-list {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.student-assignment-item {
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  padding: 20px;
  background-color: #f8f9fa;
  transition: box-shadow 0.2s;
  display: grid;
  grid-template-columns: 1fr 2fr;
  gap: 20px;
  align-items: flex-start;
}

.student-assignment-item:hover {
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.student-info {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.student-name {
  font-weight: 600;
  color: #333;
  margin-bottom: 4px;
  font-size: 1rem;
}

.student-contact {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.phone, .email {
  font-size: 0.85rem;
  color: #666;
}

.assignment-details {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 15px;
}

.stop-info {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 12px;
  border-radius: 6px;
  background-color: white;
  border: 1px solid #e9ecef;
}

.stop-info.pickup {
  border-left: 4px solid #17a2b8;
}

.stop-info.dropoff {
  border-left: 4px solid #ffc107;
}

.stop-info.no-stop {
  border-left: 4px solid #dee2e6;
}

.stop-label {
  font-weight: 600;
  color: #495057;
  font-size: 0.85rem;
  display: flex;
  align-items: center;
  gap: 6px;
}

.stop-details {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.stop-name {
  color: #333;
  font-weight: 500;
  font-size: 0.9rem;
}

.stop-time {
  color: #007bff;
  font-size: 0.85rem;
  font-weight: 500;
}

.no-stop-assigned {
  color: #999;
  font-style: italic;
  font-size: 0.85rem;
}

.capacity-info {
  margin-top: 20px;
  padding: 15px;
  background-color: #f8f9fa;
  border-radius: 6px;
  border-left: 4px solid #007bff;
}

.capacity-bar {
  width: 100%;
  height: 8px;
  background-color: #e9ecef;
  border-radius: 4px;
  overflow: hidden;
  margin-bottom: 8px;
}

.capacity-filled {
  height: 100%;
  background-color: #007bff;
  transition: width 0.3s ease;
}

.capacity-text {
  text-align: center;
  font-size: 0.9rem;
  color: var(--p-text-color);
  font-weight: 500;
}

/* Modern Student Card Styles */
.student-assignment-card {
  border: 1px solid var(--p-surface-border);
  border-radius: var(--p-border-radius);
  padding: 0;
  background-color: var(--p-surface-0);
  transition: all 0.2s ease;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.student-assignment-card:hover {
  box-shadow: var(--p-card-shadow);
  transform: translateY(-2px);
}

.student-header {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1.25rem;
  border-bottom: 1px solid var(--p-surface-border);
}

.student-avatar {
  flex-shrink: 0;
}

.student-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.student-name {
  font-weight: 600;
  color: var(--p-text-color);
  font-size: 1.1rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.student-name i {
  color: var(--p-primary-color);
  font-size: 0.9rem;
}

.student-contact {
  display: flex;
  gap: 1rem;
  font-size: 0.875rem;
}

.contact-item {
  display: flex;
  align-items: center;
  gap: 0.25rem;
  color: var(--p-text-muted-color);
}

.contact-item i {
  color: var(--p-primary-color);
  font-size: 0.8rem;
}

.assignment-details {
  padding: 1.25rem;
}

.stops-row {
  display: flex;
  align-items: stretch;
  gap: 1rem;
  min-height: 120px;
}

.stop-assignment {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
}

.stop-header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 0.75rem;
  flex-shrink: 0;
}

.stop-icon {
  font-size: 1rem;
  padding: 0.25rem;
  border-radius: 50%;
}

.pickup-icon {
  color: var(--p-green-600);
  background-color: var(--p-green-50);
}

.dropoff-icon {
  color: var(--p-orange-600);
  background-color: var(--p-orange-50);
}

.stop-label {
  font-weight: 500;
  color: var(--p-text-color);
  font-size: 0.875rem;
}

.stop-content {
  background-color: var(--p-surface-50);
  border-radius: var(--p-border-radius);
  padding: 0.75rem;
  border: 1px solid var(--p-surface-border);
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.stop-content .stop-name {
  font-weight: 500;
  color: var(--p-text-color);
  margin-bottom: 0.25rem;
}

.stop-content .stop-time {
  display: flex;
  align-items: center;
  gap: 0.25rem;
  font-size: 0.875rem;
  color: var(--p-text-muted-color);
}

.stop-content .stop-time i {
  color: var(--p-primary-color);
}

.no-stop-assigned {
  padding: 0.75rem;
  text-align: center;
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
}

.not-assigned {
  color: var(--p-text-muted-color);
  font-style: italic;
  font-size: 0.875rem;
}

</style>