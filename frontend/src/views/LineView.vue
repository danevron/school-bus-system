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
          <button @click="manageRoute" class="edit-button" :disabled="!line">
            Manage Stops and Students
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
                This line is currently <strong>active</strong> and providing scheduled transportation services. 
                Changes to this line should be made carefully as they may affect ongoing schedules and student assignments.
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

        <!-- Route Management Section -->
        <div class="route-section">
          <div class="section-header">
            <h2>Route Management</h2>
          </div>
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
                <h4>Route Stops</h4>
                <div class="stops-list">
                  <div v-for="(stop, index) in line.route.stops" :key="index" class="stop-item">
                    <span class="stop-number">{{ index + 1 }}</span>
                    <div class="stop-info">
                      <div class="stop-main">
                        <span class="stop-name">{{ stop.name }}</span>
                        <span class="stop-type" :class="stop.type">{{ stop.type }}</span>
                      </div>
                      <div class="stop-students">
                        <div v-if="getStopStudents(stop).pickup.length > 0" class="student-group pickup">
                          <div class="student-group-header">🚏 Pickup ({{ getStopStudents(stop).pickup.length }}):</div>
                          <div class="student-names">
                            <span v-for="student in getStopStudents(stop).pickup" :key="student._id" class="student-name">
                              {{ student.firstName }} {{ student.lastName }}
                            </span>
                          </div>
                        </div>
                        <div v-if="getStopStudents(stop).dropoff.length > 0" class="student-group dropoff">
                          <div class="student-group-header">🏁 Dropoff ({{ getStopStudents(stop).dropoff.length }}):</div>
                          <div class="student-names">
                            <span v-for="student in getStopStudents(stop).dropoff" :key="student._id" class="student-name">
                              {{ student.firstName }} {{ student.lastName }}
                            </span>
                          </div>
                        </div>
                        <div v-if="getStopStudents(stop).pickup.length === 0 && getStopStudents(stop).dropoff.length === 0" class="student-group none">
                          No students assigned
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
        </div>

        <!-- Assigned Students Section -->
        <div class="students-section">
          <div class="section-header">
            <h2>Assigned Students</h2>
            <span class="student-count">{{ studentAssignments.length }} students</span>
          </div>
          
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
              class="student-assignment-item"
            >
              <div class="student-info">
                <div class="student-name">
                  {{ assignment.student.firstName }} {{ assignment.student.lastName }}
                </div>
                <div class="student-contact">
                  <span class="phone">📞 {{ assignment.student.phone }}</span>
                  <span v-if="assignment.student.email" class="email">✉️ {{ assignment.student.email }}</span>
                </div>
              </div>

              <div class="assignment-details">
                <div v-if="assignment.pickupStopDetails" class="stop-info pickup">
                  <div class="stop-label">🚏 Pickup:</div>
                  <div class="stop-details">
                    <div class="stop-name">{{ assignment.pickupStopDetails.name }}</div>
                    <div class="stop-time">{{ formatTime(assignment.pickupStopDetails.estimatedTime) }}</div>
                  </div>
                </div>
                <div v-else class="stop-info no-stop">
                  <div class="stop-label">🚏 Pickup:</div>
                  <div class="no-stop-assigned">Not assigned</div>
                </div>

                <div v-if="assignment.dropoffStopDetails" class="stop-info dropoff">
                  <div class="stop-label">🏁 Dropoff:</div>
                  <div class="stop-details">
                    <div class="stop-name">{{ assignment.dropoffStopDetails.name }}</div>
                    <div class="stop-time">{{ formatTime(assignment.dropoffStopDetails.estimatedTime) }}</div>
                  </div>
                </div>
                <div v-else class="stop-info no-stop">
                  <div class="stop-label">🏁 Dropoff:</div>
                  <div class="no-stop-assigned">Not assigned</div>
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
        </div>

        <!-- Route Map Section -->
        <div v-if="line.route && line.route.stops && line.route.stops.length > 0" class="map-section">
          <RouteMap
            :stops="line.route.stops"
            :studentAssignments="studentAssignments"
            :showDrivingInstructions="false"
            :showDrivingRoute="true"
            mapHeight="600px"
            mapId="line-route-map"
          />
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
import RouteMap from '../components/RouteMap.vue'

export default {
  name: 'LineView',
  components: {
    RouteMap
  },
  setup() {
    const authStore = inject('authStore')
    const router = useRouter()
    const route = useRoute()
    
    const line = ref(null)
    const loading = ref(false)
    const error = ref(null)
    const studentAssignments = ref([])
    
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
    
    const formatTime = (minutes) => {
      if (!minutes && minutes !== 0) return 'N/A'
      const hours = Math.floor(minutes / 60)
      const mins = minutes % 60
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
    
    
    onMounted(async () => {
      await fetchLine()
    })
    
    return {
      line,
      loading,
      error,
      studentAssignments,
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
      getStopStudents
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
  background-color: #f8f9fa;
  border-radius: 8px;
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
  color: #333;
}

.stat-label {
  font-size: 0.85rem;
  color: #666;
}

.route-stops h4 {
  margin: 0 0 15px 0;
  color: #333;
  font-size: 1.1rem;
}

.stops-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.stop-item {
  display: flex;
  align-items: center;
  gap: 15px;
  padding: 12px;
  background-color: #f8f9fa;
  border-radius: 6px;
  border-left: 3px solid #007bff;
}

.stop-number {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 24px;
  height: 24px;
  background-color: #007bff;
  color: white;
  border-radius: 50%;
  font-size: 0.8rem;
  font-weight: 600;
}

.stop-info {
  display: flex;
  flex-direction: column;
  gap: 8px;
  flex: 1;
}

.stop-main {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.stop-name {
  font-weight: 500;
  color: #333;
}

.stop-students {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-top: 8px;
}

.student-group {
  padding: 8px 12px;
  border-radius: 6px;
  font-size: 0.85rem;
  width: 100%;
}

.student-group.pickup {
  background-color: #d4edda;
  border-left: 3px solid #155724;
}

.student-group.dropoff {
  background-color: #d1ecf1;
  border-left: 3px solid #0c5460;
}

.student-group.none {
  background-color: #f8f9fa;
  color: #6c757d;
  font-style: italic;
  text-align: center;
  padding: 12px;
}

.student-group-header {
  font-weight: 600;
  margin-bottom: 6px;
}

.student-group.pickup .student-group-header {
  color: #155724;
}

.student-group.dropoff .student-group-header {
  color: #0c5460;
}

.student-names {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.student-name {
  background-color: rgba(255, 255, 255, 0.8);
  padding: 2px 6px;
  border-radius: 4px;
  font-size: 0.8rem;
  font-weight: 500;
}

.stop-type {
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 0.75rem;
  font-weight: 500;
  text-transform: uppercase;
  width: fit-content;
}

.stop-type.pickup {
  background-color: #d4edda;
  color: #155724;
}

.stop-type.dropoff {
  background-color: #d1ecf1;
  color: #0c5460;
}

.empty-route {
  display: flex;
  align-items: center;
  gap: 20px;
  padding: 40px 20px;
  text-align: left;
  color: #666;
}

.empty-icon {
  font-size: 3rem;
  opacity: 0.5;
}

.empty-text h3 {
  margin: 0 0 10px 0;
  color: #333;
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
  gap: 15px;
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
  color: #495057;
  font-weight: 500;
}

</style>