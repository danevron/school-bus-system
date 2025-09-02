<template>
  <div class="route-manager-container">
    <header class="header">
      <div class="header-content">
        <div class="header-info">
          <h1 v-if="line">Route Manager - {{ line.name }}</h1>
          <h1 v-else>Route Manager</h1>
        </div>
        <div class="header-actions">
          <button @click="goBack" class="back-button">← Back to Line</button>
        </div>
      </div>
    </header>

    <main class="main-content">
      <div v-if="loading" class="loading">
        <div class="loading-spinner"></div>
        Loading route data...
      </div>

      <div v-else-if="error" class="error-state">
        <div class="error-message">
          <h3>Error Loading Route</h3>
          <p>{{ error }}</p>
          <button @click="fetchLine" class="retry-button">Try Again</button>
        </div>
      </div>

      <div v-else-if="line" class="content-wrapper">
        <!-- Route Overview -->
        <div class="route-overview">
          <div class="overview-grid">
            <div class="overview-stats">
              <div class="stat-card">
                <div class="stat-value">{{ routeData.stops.length }}</div>
                <div class="stat-label">Total Stops</div>
              </div>
              <div class="stat-card">
                <div class="stat-value">{{ routeData.totalDistance }} km</div>
                <div class="stat-label">Total Distance</div>
              </div>
              <div class="stat-card">
                <div class="stat-value">{{ formatDuration(routeData.estimatedDuration) }}</div>
                <div class="stat-label">Est. Duration</div>
              </div>
              <div class="stat-card">
                <div class="stat-value">{{ getDriverName(line.driver) }}</div>
                <div class="stat-label">Line Driver</div>
              </div>
              <div class="stat-card">
                <div class="stat-value">{{ getVehicleName(line.vehicle) }}</div>
                <div class="stat-label">Vehicle</div>
              </div>
            </div>
          </div>
        </div>

        <!-- Route Stops -->
        <div class="route-stops">
          <div class="stops-header">
            <h2>Route Stops</h2>
            <button @click="showStopDialog = true" class="add-stop-button">
              + Add Stop
            </button>
          </div>
          
          <div v-if="routeData.stops.length === 0" class="no-stops">
            <p>No stops have been defined for this route.</p>
          </div>

          <div v-else class="stops-timeline">
            <div 
              v-for="(stop, index) in routeData.stops" 
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
                      <span class="time-badge">
                        {{ formatTime(stop.estimatedTime) }}
                      </span>
                    </div>
                    <div class="stop-controls">
                      <button 
                        v-if="index > 0"
                        @click="moveStopUp(index)"
                        class="move-button"
                        :disabled="loading"
                        title="Move up"
                      >
                        ↑
                      </button>
                      <button 
                        v-if="index < routeData.stops.length - 1"
                        @click="moveStopDown(index)"
                        class="move-button"
                        :disabled="loading"
                        title="Move down"
                      >
                        ↓
                      </button>
                      <button 
                        @click="deleteStop(index)"
                        class="delete-button"
                        :class="{ 'delete-disabled': !canDeleteStop(stop) }"
                        :disabled="loading || !canDeleteStop(stop)"
                        :title="canDeleteStop(stop) ? 'Delete stop' : 'Cannot delete: stop has assigned students'"
                      >
                        {{ canDeleteStop(stop) ? '🗑️' : '🔒' }}
                      </button>
                    </div>
                  </div>
                </div>

                <div class="stop-details">
                  <div class="stop-address">
                    <strong>Address:</strong> {{ stop.address }}
                  </div>
                  <div class="stop-time">
                    <strong>Estimated Time:</strong> {{ stop.estimatedTime }} minutes from start
                  </div>
                  <div v-if="getStopUsageInfo(stop)" class="stop-usage-info">
                    <div class="usage-indicator">
                      <span class="usage-icon">👥</span>
                      <span class="usage-text">
                        {{ getStopUsageInfo(stop).totalStudents }} student{{ getStopUsageInfo(stop).totalStudents !== 1 ? 's' : '' }} assigned
                      </span>
                      <span class="usage-details">
                        ({{ getStopUsageInfo(stop).pickupCount }} pickup, {{ getStopUsageInfo(stop).dropoffCount }} dropoff)
                      </span>
                    </div>
                    <div class="assigned-students">
                      {{ getStopUsageInfo(stop).students.join(', ') }}
                    </div>
                  </div>
                </div>
              </div>

              <div v-if="index < routeData.stops.length - 1" class="route-connector"></div>
            </div>
          </div>
        </div>

        <!-- Route Map -->
        <div v-if="routeData.stops.length > 0">
          <RouteMap
            :stops="routeData.stops"
            :studentAssignments="studentAssignments"
            :showDrivingInstructions="true"
            :showDrivingRoute="true"
            :showDetailedPopups="true"
            :formatTime="formatTime"
            mapHeight="800px"
            mapId="route-manager-map"
            @route-updated="handleRouteUpdate"
          />
        </div>

        <!-- Student Management Section -->
        <div class="student-management">
          <div class="students-header">
            <h2>Assigned Students</h2>
            <button @click="showStudentDialog = true" class="add-student-button">
              + Add Student
            </button>
          </div>
          
          <div v-if="loadingStudents" class="loading-students">
            <div class="loading-spinner"></div>
            Loading student assignments...
          </div>

          <div v-else-if="studentAssignments.length === 0" class="no-students">
            <p>No students have been assigned to this line yet.</p>
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

              <div class="assignment-actions">
                <button 
                  @click="editStudentAssignment(assignment)" 
                  class="edit-button"
                  title="Edit stops"
                >
                  ✏️
                </button>
                <button 
                  @click="removeStudentAssignment(assignment)" 
                  class="remove-button"
                  title="Remove student"
                >
                  🗑️
                </button>
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

      </div>

      <div v-else class="not-found-container">
        <div class="not-found">
          <h3>Line Not Found</h3>
          <p>The requested line could not be found.</p>
          <button @click="goBack" class="back-button">Back to Lines</button>
        </div>
      </div>
    </main>
    
    <!-- Stop Creation Dialog -->
    <StopCreationDialog 
      :isOpen="showStopDialog"
      @close="showStopDialog = false"
      @save="handleAddStopFromDialog"
    />

    <!-- Student Selection Dialog -->
    <StudentSelectionDialog
      :isOpen="showStudentDialog"
      :lineId="route.params.id"
      :assignedStudents="studentAssignments.map(a => a.student)"
      @close="showStudentDialog = false"
      @student-selected="handleStudentSelected"
    />

    <!-- Stop Selection Dialog -->
    <StopSelectionDialog
      :isOpen="showStopSelectionDialog"
      :student="selectedStudentForStops"
      :stops="routeData.stops"
      @close="handleStopSelectionClose"
      @save="handleStopAssignmentSave"
    />
  </div>
</template>

<script>
import { ref, reactive, inject, onMounted, onUnmounted, nextTick, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import apiService from '../services/api'
import StopCreationDialog from '../components/StopCreationDialog.vue'
import StudentSelectionDialog from '../components/StudentSelectionDialog.vue'
import StopSelectionDialog from '../components/StopSelectionDialog.vue'
import RouteMap from '../components/RouteMap.vue'

export default {
  name: 'LineRouteManager',
  components: {
    StopCreationDialog,
    StudentSelectionDialog,
    StopSelectionDialog,
    RouteMap
  },
  setup() {
    const authStore = inject('authStore')
    const router = useRouter()
    const route = useRoute()
    
    const loading = ref(false)
    const error = ref('')
    const line = ref(null)
    const showStopDialog = ref(false)
    
    // Student management state
    const showStudentDialog = ref(false)
    const showStopSelectionDialog = ref(false)
    const selectedStudentForStops = ref(null)
    const studentAssignments = ref([])
    const loadingStudents = ref(false)
    const stopUsage = ref({})
    
    // Route data - using reactive for embedded route
    const routeData = reactive({
      name: '',
      stops: [],
      totalDistance: 0,
      estimatedDuration: 0
    })
    
    const fetchLine = async () => {
      const lineId = route.params.id
      if (!lineId) {
        error.value = 'No line ID provided'
        return
      }
      
      try {
        loading.value = true
        error.value = ''
        
        const response = await apiService.get(`/lines/${lineId}`)
        line.value = response.line || response.data
        
        // Initialize route data from line's embedded route
        if (line.value.route) {
          routeData.name = line.value.route.name || `${line.value.name} Route`
          routeData.stops = [...(line.value.route.stops || [])]
          routeData.totalDistance = line.value.route.totalDistance || 0
          routeData.estimatedDuration = line.value.route.estimatedDuration || 0
        } else {
          // Initialize empty route
          routeData.name = `${line.value.name} Route`
          routeData.stops = []
          routeData.totalDistance = 0
          routeData.estimatedDuration = 0
        }
      } catch (err) {
        console.error('Failed to fetch line:', err)
        if (err.response?.status === 404) {
          error.value = 'Line not found. It may have been deleted or the ID is invalid.'
        } else {
          error.value = 'Failed to load line details. Please try again.'
        }
      } finally {
        loading.value = false
      }
      
    }
    
    const formatDuration = (minutes) => {
      if (minutes < 60) {
        return `${minutes} min`
      }
      const hours = Math.floor(minutes / 60)
      const remainingMinutes = minutes % 60
      return `${hours}h ${remainingMinutes}m`
    }
    
    const formatTime = (minutes) => {
      const hours = Math.floor(minutes / 60)
      const mins = minutes % 60
      return `${hours.toString().padStart(2, '0')}:${mins.toString().padStart(2, '0')}`
    }
    
    const getStopsByType = (type) => {
      return routeData.stops.filter(stop => stop.type === type) || []
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
    

    
    const handleAddStopFromDialog = async (newStop) => {
      try {
        loading.value = true
        
        await apiService.post(`/lines/${route.params.id}/route/stops`, { stop: newStop })
        
        // Refresh line data
        await fetchLine()
        

        // Close dialog
        showStopDialog.value = false
        
      } catch (error) {
        console.error('Failed to add stop:', error)
        alert(error.response?.data?.message || 'Failed to add stop')
      } finally {
        loading.value = false
      }
    }
    
    const moveStopUp = async (index) => {
      if (index <= 0) return
      
      const stops = [...routeData.stops]
      const temp = stops[index]
      stops[index] = stops[index - 1]
      stops[index - 1] = temp
      
      await updateRouteStops(stops)
    }
    
    const moveStopDown = async (index) => {
      if (index >= routeData.stops.length - 1) return
      
      const stops = [...routeData.stops]
      const temp = stops[index]
      stops[index] = stops[index + 1]
      stops[index + 1] = temp
      
      await updateRouteStops(stops)
    }
    
    const deleteStop = async (index) => {
      const stop = routeData.stops[index]
      const usage = stopUsage.value[stop.stopId]
      
      // Check if stop has active assignments
      if (usage && !usage.canDelete) {
        const students = [...usage.pickupStudents, ...usage.dropoffStudents]
        const uniqueStudents = [...new Set(students)]
        
        alert(`Cannot delete "${stop.name}": This stop is currently assigned to ${uniqueStudents.length} student(s): ${uniqueStudents.join(', ')}.\n\nPlease remove student assignments before deleting this stop.`)
        return
      }
      
      if (!confirm(`Are you sure you want to delete "${stop.name}"?`)) return
      
      try {
        loading.value = true
        await apiService.delete(`/lines/${route.params.id}/route/stops/${index}`)
        await fetchLine()
        await fetchStopUsage()

      } catch (error) {
        console.error('Failed to delete stop:', error)
        
        // Handle detailed error from backend
        if (error.response?.data?.affectedStudents) {
          const details = error.response.data
          alert(`${details.message}\n\n${details.details}\n\nPlease remove student assignments before deleting this stop.`)
        } else {
          alert(error.response?.data?.message || 'Failed to delete stop')
        }
      } finally {
        loading.value = false
      }
    }

    const canDeleteStop = (stop) => {
      const usage = stopUsage.value[stop.stopId]
      return !usage || usage.canDelete
    }

    const getStopUsageInfo = (stop) => {
      const usage = stopUsage.value[stop.stopId]
      if (!usage || usage.totalUsage === 0) return null
      
      const students = [...new Set([...usage.pickupStudents, ...usage.dropoffStudents])]
      return {
        totalStudents: students.length,
        students: students,
        pickupCount: usage.pickupStudents.length,
        dropoffCount: usage.dropoffStudents.length
      }
    }
    
    const updateRouteStops = async (stops) => {
      try {
        loading.value = true
        await apiService.put(`/lines/${route.params.id}/route/stops`, { stops })
        await fetchLine()

      } catch (error) {
        console.error('Failed to reorder stops:', error)
        alert(error.response?.data?.message || 'Failed to reorder stops')
      } finally {
        loading.value = false
      }
    }
    
    const goBack = () => {
      if (line.value) {
        router.push(`/lines/${line.value._id}`)
      } else {
        router.push('/lines')
      }
    }
    
    const formatDistance = (distanceInMeters) => {
      if (distanceInMeters < 1000) {
        return `${Math.round(distanceInMeters)} m`
      } else {
        return `${(distanceInMeters / 1000).toFixed(1)} km`
      }
    }
    
    
    
    
    const handleRouteUpdate = (routeInfo) => {
      routeData.totalDistance = routeInfo.totalDistance
      routeData.estimatedDuration = routeInfo.estimatedDuration
    }

    // Student management functions
    const fetchStudentAssignments = async () => {
      const lineId = route.params.id
      if (!lineId) return

      try {
        loadingStudents.value = true
        const response = await apiService.get(`/lines/${lineId}/student-assignments`)
        studentAssignments.value = response.assignments || []
        
        // Also fetch stop usage info
        await fetchStopUsage()
      } catch (error) {
        console.error('Failed to fetch student assignments:', error)
        // Could show error message to user
      } finally {
        loadingStudents.value = false
      }
    }

    const fetchStopUsage = async () => {
      const lineId = route.params.id
      if (!lineId) return

      try {
        const response = await apiService.get(`/lines/${lineId}/stop-usage`)
        stopUsage.value = response.stopUsage || {}
      } catch (error) {
        console.error('Failed to fetch stop usage:', error)
        stopUsage.value = {}
      }
    }

    const handleStudentSelected = (student) => {
      showStudentDialog.value = false
      selectedStudentForStops.value = student

      // Check if route has stops, if so show stop selection dialog
      if (routeData.stops && routeData.stops.length > 0) {
        showStopSelectionDialog.value = true
      } else {
        // No stops available, assign student without stops
        assignStudentToLine(student, null, null, true)
      }
    }

    const handleStopSelectionClose = () => {
      showStopSelectionDialog.value = false
      selectedStudentForStops.value = null
    }

    const handleStopAssignmentSave = async (assignment) => {
      showStopSelectionDialog.value = false
      
      const { student, pickupStop, dropoffStop, skipStops } = assignment
      
      if (student._isEditing) {
        // Update existing assignment
        await updateStudentAssignment(student._assignmentId, pickupStop, dropoffStop, skipStops)
      } else {
        // Create new assignment
        await assignStudentToLine(student, pickupStop, dropoffStop, skipStops)
      }
      
      selectedStudentForStops.value = null
    }

    const assignStudentToLine = async (student, pickupStop, dropoffStop, skipStops) => {
      const lineId = route.params.id
      if (!lineId) return

      try {
        loading.value = true
        
        const requestData = {
          studentId: student._id,
          pickupStop: skipStops ? undefined : pickupStop?.stopId,
          dropoffStop: skipStops ? undefined : dropoffStop?.stopId
        }

        await apiService.post(`/lines/${lineId}/student-assignments`, requestData)
        
        // Refresh student assignments
        await fetchStudentAssignments()
        
      } catch (error) {
        console.error('Failed to assign student to line:', error)
        alert(error.response?.data?.message || 'Failed to assign student to line')
      } finally {
        loading.value = false
      }
    }

    const updateStudentAssignment = async (assignmentId, pickupStop, dropoffStop, skipStops) => {
      const lineId = route.params.id
      if (!lineId) return

      try {
        loading.value = true
        
        const requestData = {
          pickupStop: skipStops ? undefined : pickupStop?.stopId,
          dropoffStop: skipStops ? undefined : dropoffStop?.stopId
        }

        await apiService.put(`/lines/${lineId}/student-assignments/${assignmentId}`, requestData)
        
        // Refresh student assignments
        await fetchStudentAssignments()
        
      } catch (error) {
        console.error('Failed to update student assignment:', error)
        alert(error.response?.data?.message || 'Failed to update student assignment')
      } finally {
        loading.value = false
      }
    }

    const editStudentAssignment = (assignment) => {
      selectedStudentForStops.value = {
        ...assignment.student,
        _isEditing: true,
        _assignmentId: assignment._id,
        _currentPickupStop: assignment.pickupStop,
        _currentDropoffStop: assignment.dropoffStop
      }
      showStopSelectionDialog.value = true
    }

    const removeStudentAssignment = async (assignment) => {
      if (!confirm(`Remove ${assignment.student.firstName} ${assignment.student.lastName} from this line?`)) {
        return
      }

      const lineId = route.params.id
      if (!lineId) return

      try {
        loading.value = true
        await apiService.delete(`/lines/${lineId}/student-assignments/${assignment._id}`)
        await fetchStudentAssignments()
      } catch (error) {
        console.error('Failed to remove student assignment:', error)
        alert(error.response?.data?.message || 'Failed to remove student from line')
      } finally {
        loading.value = false
      }
    }
    
    
    onMounted(async () => {
      await fetchLine()
      await fetchStudentAssignments()
    })
    
    
    return {
      loading,
      error,
      line,
      routeData,
      route,
      showStopDialog,
      // Student management state
      showStudentDialog,
      showStopSelectionDialog,
      selectedStudentForStops,
      studentAssignments,
      loadingStudents,
      stopUsage,
      // Functions
      fetchLine,
      handleAddStopFromDialog,
      moveStopUp,
      moveStopDown,
      deleteStop,
      formatDuration,
      formatTime,
      getStopsByType,
      getDriverName,
      getVehicleName,
      goBack,
      handleRouteUpdate,
      // Student management functions
      fetchStudentAssignments,
      fetchStopUsage,
      handleStudentSelected,
      handleStopSelectionClose,
      handleStopAssignmentSave,
      editStudentAssignment,
      removeStudentAssignment,
      updateStudentAssignment,
      canDeleteStop,
      getStopUsageInfo
    }
  }
}
</script>

<style scoped>
.route-manager-container {
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

.header h1 {
  margin: 0;
}

.back-button {
  background-color: #6c757d;
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: 4px;
  cursor: pointer;
  transition: background-color 0.2s;
}

.back-button:hover {
  background-color: #545b62;
}

.main-content {
  max-width: 1200px;
  margin: 0 auto;
  padding: 30px 20px;
}

.loading {
  text-align: center;
  color: #666;
  padding: 60px 20px;
  font-size: 1.1rem;
}

.loading-spinner {
  width: 40px;
  height: 40px;
  border: 4px solid #f3f3f3;
  border-top: 4px solid #007bff;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 20px;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.error-state {
  text-align: center;
  padding: 60px 20px;
}

.error-message {
  background: white;
  padding: 40px;
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
}

.error-message h3 {
  color: #dc3545;
  margin-bottom: 10px;
}

.error-message p {
  color: #666;
  margin-bottom: 30px;
}

.retry-button {
  background-color: #007bff;
  color: white;
  border: none;
  padding: 12px 24px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 1rem;
  transition: background-color 0.2s;
}

.retry-button:hover {
  background-color: #0056b3;
}

.content-wrapper {
  display: flex;
  flex-direction: column;
  gap: 30px;
}

.route-overview,
.route-stops,
.route-summary,
.student-management {
  background: white;
  border-radius: 8px;
  padding: 30px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
}

/* Stop Management Styles */
.stops-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  border-bottom: 2px solid #e9ecef;
  padding-bottom: 10px;
}

.stops-header h2 {
  margin: 0;
  color: #333;
}

.add-stop-button {
  background-color: #28a745;
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: 4px;
  cursor: pointer;
  font-weight: 500;
  transition: background-color 0.2s;
}

.add-stop-button:hover {
  background-color: #218838;
}

.route-overview h2,
.route-stops h2,
.route-summary h2 {
  color: #333;
  margin-bottom: 20px;
  border-bottom: 2px solid #e9ecef;
  padding-bottom: 10px;
}

.overview-grid {
  display: grid;
  grid-template-columns: 1fr auto;
  gap: 30px;
  align-items: start;
}

.overview-item h3 {
  color: #495057;
  margin-bottom: 10px;
}

.overview-item p {
  color: #666;
  line-height: 1.5;
}

.overview-stats {
  display: flex;
  gap: 20px;
}

.stat-card {
  text-align: center;
  padding: 20px;
  background-color: #f8f9fa;
  border-radius: 8px;
  min-width: 120px;
}

.stat-value {
  font-size: 1.5rem;
  font-weight: bold;
  color: #007bff;
  display: block;
}

.stat-label {
  font-size: 0.85rem;
  color: #666;
  margin-top: 5px;
}

.no-stops {
  text-align: center;
  color: #666;
  font-style: italic;
  padding: 40px;
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
  background-color: #007bff;
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: bold;
  font-size: 0.9rem;
  margin-right: 10px;
}

.pickup-stop .stop-number {
  background-color: #17a2b8;
}

.dropoff-stop .stop-number {
  background-color: #ffc107;
  color: #000;
}

.stop-type-icon {
  font-size: 1.2rem;
}

.stop-content {
  flex: 1;
  background-color: #f8f9fa;
  border-radius: 8px;
  padding: 20px;
  border-left: 4px solid #007bff;
}

.pickup-stop .stop-content {
  border-left-color: #17a2b8;
}

.dropoff-stop .stop-content {
  border-left-color: #ffc107;
}

.stop-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 15px;
}

.stop-name {
  margin: 0;
  color: #333;
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

.stop-controls {
  display: flex;
  gap: 4px;
}

.move-button,
.delete-button {
  background-color: #6c757d;
  color: white;
  border: none;
  padding: 4px 8px;
  border-radius: 4px;
  cursor: pointer;
  font-size: 12px;
  transition: background-color 0.2s;
  min-width: 28px;
  height: 28px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.move-button:hover:not(:disabled) {
  background-color: #007bff;
}

.delete-button:hover:not(:disabled) {
  background-color: #dc3545;
}

.move-button:disabled,
.delete-button:disabled {
  background-color: #ccc;
  cursor: not-allowed;
}

.delete-button.delete-disabled {
  background-color: #ffeaea;
  border-color: #dc3545;
  color: #dc3545;
  cursor: not-allowed;
}

.delete-button.delete-disabled:hover {
  background-color: #ffeaea;
  border-color: #dc3545;
}

.type-badge {
  padding: 4px 8px;
  border-radius: 12px;
  font-size: 0.7rem;
  font-weight: bold;
  text-transform: uppercase;
}

.type-badge.pickup {
  background-color: #17a2b8;
  color: white;
}

.type-badge.dropoff {
  background-color: #ffc107;
  color: #000;
}

.time-badge {
  padding: 4px 8px;
  background-color: #e9ecef;
  border-radius: 12px;
  font-size: 0.7rem;
  font-weight: bold;
  color: #495057;
}

.stop-details {
  display: grid;
  gap: 8px;
}

.stop-details > div {
  font-size: 0.9rem;
  color: #666;
}

.stop-usage-info {
  margin-top: 12px;
  padding: 8px 12px;
  background-color: #e3f2fd;
  border-radius: 6px;
  border-left: 3px solid #2196f3;
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
  color: #1976d2;
  font-size: 0.85rem;
}

.usage-details {
  color: #666;
  font-size: 0.75rem;
}

.assigned-students {
  font-size: 0.75rem;
  color: #555;
  font-style: italic;
  line-height: 1.3;
}

.route-connector {
  position: absolute;
  left: 15px;
  top: 50px;
  width: 2px;
  height: 40px;
  background-color: #dee2e6;
  z-index: 1;
}

.summary-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 20px;
}

.summary-item h4 {
  color: #495057;
  margin-bottom: 15px;
  border-bottom: 1px solid #e9ecef;
  padding-bottom: 8px;
}

.type-breakdown {
  display: flex;
  gap: 15px;
}

.type-count {
  display: flex;
  align-items: center;
  gap: 8px;
}

.count {
  font-weight: bold;
  color: #333;
}

.timeline-info > div,
.metadata-info > div {
  margin-bottom: 8px;
  font-size: 0.9rem;
  color: #666;
}

.no-timeline {
  color: #999;
  font-style: italic;
}





.not-found-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 400px;
}

.not-found {
  text-align: center;
  background: white;
  padding: 40px;
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
}

.not-found h3 {
  color: #dc3545;
  margin-bottom: 15px;
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
  
  .overview-grid {
    grid-template-columns: 1fr;
  }
  
  .overview-stats {
    justify-content: center;
  }
  
  .stop-header {
    flex-direction: column;
    gap: 10px;
    align-items: flex-start;
  }
  
  .summary-grid {
    grid-template-columns: 1fr;
  }
}

/* Student Management Styles */
.students-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  border-bottom: 2px solid #e9ecef;
  padding-bottom: 10px;
}

.students-header h2 {
  margin: 0;
  color: #333;
}

.add-student-button {
  background-color: #28a745;
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: 4px;
  cursor: pointer;
  font-weight: 500;
  transition: background-color 0.2s;
}

.add-student-button:hover {
  background-color: #218838;
}

.loading-students {
  text-align: center;
  padding: 40px 20px;
  color: #666;
}

.loading-students .loading-spinner {
  width: 32px;
  height: 32px;
  border: 3px solid #f3f3f3;
  border-top: 3px solid #28a745;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 15px;
}

.no-students {
  text-align: center;
  color: #666;
  font-style: italic;
  padding: 40px 20px;
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
}

.student-assignment-item:hover {
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.student-assignment-item {
  display: grid;
  grid-template-columns: 1fr 2fr auto;
  gap: 20px;
  align-items: flex-start;
}

.student-info {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.student-name {
  font-weight: 600;
  color: #333;
  font-size: 1.1rem;
}

.student-contact {
  display: flex;
  flex-direction: column;
  gap: 4px;
  font-size: 0.85rem;
  color: #666;
}

.phone, .email {
  display: flex;
  align-items: center;
  gap: 6px;
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

.assignment-actions {
  display: flex;
  flex-direction: column;
  gap: 8px;
  align-items: center;
}

.edit-button, .remove-button {
  background: none;
  border: 1px solid #dee2e6;
  border-radius: 6px;
  width: 36px;
  height: 36px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
  transition: all 0.2s;
}

.edit-button:hover {
  border-color: #007bff;
  background-color: #e3f2fd;
}

.remove-button:hover {
  border-color: #dc3545;
  background-color: #ffeaea;
}

.capacity-info {
  margin-top: 20px;
  padding: 15px;
  background-color: #f8f9fa;
  border-radius: 6px;
  border: 1px solid #e9ecef;
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
  background: linear-gradient(90deg, #28a745 0%, #ffc107 70%, #dc3545 100%);
  transition: width 0.3s ease;
}

.capacity-text {
  text-align: center;
  font-size: 0.9rem;
  color: #495057;
  font-weight: 500;
}

@media (max-width: 768px) {
  .student-assignment-item {
    grid-template-columns: 1fr;
    gap: 15px;
  }
  
  .assignment-details {
    grid-template-columns: 1fr;
  }
  
  .assignment-actions {
    flex-direction: row;
    justify-content: center;
  }
  
  .students-header {
    flex-direction: column;
    gap: 15px;
    align-items: stretch;
  }
}
</style>