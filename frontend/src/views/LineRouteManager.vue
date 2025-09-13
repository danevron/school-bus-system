<template>
  <AppLayout 
    :page-title="line ? `Route Manager - ${line.name}` : 'Route Manager'"
    :breadcrumbs="breadcrumbs"
  >
    <template #actions>
      <Button 
        @click="goBack" 
        icon="pi pi-arrow-left"
        label="Back to Line"
        severity="secondary"
        outlined
      />
    </template>
    
    <div class="route-manager-content">
      <div v-if="loading" class="loading">
        <div class="loading-spinner"></div>
        Loading route data...
      </div>

      <div v-else-if="error" class="error-state">
        <div class="error-message">
          <h3>Error Loading Route</h3>
          <p>{{ error }}</p>
          <Button @click="fetchLine" label="Try Again" icon="pi pi-refresh" severity="info" />
        </div>
      </div>

      <div v-else-if="line" class="content-wrapper">
        <!-- Route Overview -->
        <Card class="route-overview">
          <template #header>
            <div class="section-header-card">
              <h2><i class="pi pi-chart-bar"></i>Route Overview</h2>
            </div>
          </template>
          <template #content>
            <div class="overview-stats">
              <div class="stat-card">
                <div class="stat-icon"><i class="pi pi-map-marker"></i></div>
                <div class="stat-info">
                  <div class="stat-value">{{ routeData.stops.length }}</div>
                  <div class="stat-label">Total Stops</div>
                </div>
              </div>
              <div class="stat-card">
                <div class="stat-icon"><i class="pi pi-compass"></i></div>
                <div class="stat-info">
                  <div class="stat-value">{{ routeData.totalDistance }} km</div>
                  <div class="stat-label">Total Distance</div>
                </div>
              </div>
              <div class="stat-card">
                <div class="stat-icon"><i class="pi pi-clock"></i></div>
                <div class="stat-info">
                  <div class="stat-value">{{ formatDuration(routeData.estimatedDuration) }}</div>
                  <div class="stat-label">Est. Duration</div>
                </div>
              </div>
              <div class="stat-card">
                <div class="stat-icon"><i class="pi pi-user"></i></div>
                <div class="stat-info">
                  <div class="stat-value">{{ getDriverName(line.driver) }}</div>
                  <div class="stat-label">Line Driver</div>
                </div>
              </div>
              <div class="stat-card">
                <div class="stat-icon"><i class="pi pi-car"></i></div>
                <div class="stat-info">
                  <div class="stat-value">{{ getVehicleName(line.vehicle) }}</div>
                  <div class="stat-label">Vehicle</div>
                </div>
              </div>
            </div>
          </template>
        </Card>

        <!-- Route Stops -->
        <Card class="route-stops">
          <template #header>
            <div class="section-header-card">
              <h2><i class="pi pi-map"></i>Route Stops</h2>
              <Button 
                @click="showStopDialog = true" 
                icon="pi pi-plus"
                label="Add Stop"
                severity="success"
              />
            </div>
          </template>
          <template #content>
          
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
                      <Button 
                        v-if="index > 0"
                        @click="moveStopUp(index)"
                        icon="pi pi-chevron-up"
                        :disabled="loading"
                        title="Move up"
                        size="small"
                        severity="secondary"
                        outlined
                      />
                      <Button 
                        v-if="index < routeData.stops.length - 1"
                        @click="moveStopDown(index)"
                        icon="pi pi-chevron-down"
                        :disabled="loading"
                        title="Move down"
                        size="small"
                        severity="secondary"
                        outlined
                      />
                      <Button 
                        @click="deleteStop(index)"
                        :icon="canDeleteStop(stop) ? 'pi pi-trash' : 'pi pi-lock'"
                        :disabled="loading || !canDeleteStop(stop)"
                        :title="canDeleteStop(stop) ? 'Delete stop' : 'Cannot delete: stop has assigned students'"
                        size="small"
                        :severity="canDeleteStop(stop) ? 'danger' : 'secondary'"
                        outlined
                      />
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
            </div>
          </div>
          </template>
        </Card>

        <!-- Route Map -->
        <Card v-if="routeData.stops.length > 0" class="route-map-section">
          <template #header>
            <div class="section-header-card">
              <h2><i class="pi pi-map-marker"></i>Interactive Route Map</h2>
            </div>
          </template>
          <template #content>
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
          </template>
        </Card>

        <!-- Student Management Section -->
        <Card class="student-management">
          <template #header>
            <div class="section-header-card">
              <h2><i class="pi pi-users"></i>Assigned Students</h2>
              <Button 
                @click="showStudentDialog = true" 
                icon="pi pi-plus"
                label="Add Student"
                severity="success"
              />
            </div>
          </template>
          <template #content>
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
                <div class="assignment-actions">
                  <Button 
                    @click="editStudentAssignment(assignment)" 
                    icon="pi pi-pencil"
                    severity="secondary"
                    size="small"
                    outlined
                    title="Edit stops"
                  />
                  <Button 
                    @click="removeStudentAssignment(assignment)" 
                    icon="pi pi-trash"
                    severity="danger"
                    size="small"
                    outlined
                    title="Remove student"
                  />
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

      </div>

      <div v-else class="not-found-container">
        <div class="not-found">
          <h3>Line Not Found</h3>
          <p>The requested line could not be found.</p>
          <Button @click="goBack" label="Back to Lines" icon="pi pi-arrow-left" severity="secondary" />
        </div>
      </div>
    
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
    </AppLayout>
</template>

<script>
import { ref, reactive, inject, onMounted, onUnmounted, nextTick, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import apiService from '../services/api'
import AppLayout from '../components/AppLayout.vue'
import StopCreationDialog from '../components/StopCreationDialog.vue'
import StudentSelectionDialog from '../components/StudentSelectionDialog.vue'
import StopSelectionDialog from '../components/StopSelectionDialog.vue'
import RouteMap from '../components/RouteMap.vue'

export default {
  name: 'LineRouteManager',
  components: {
    AppLayout,
    StopCreationDialog,
    StudentSelectionDialog,
    StopSelectionDialog,
    RouteMap
  },
  setup() {
    const authStore = inject('authStore')
    const router = useRouter()
    const route = useRoute()
    const lineId = route.params.lineId
    
    const breadcrumbs = ref([
      { label: 'Dashboard', path: '/home' },
      { label: 'Line Management', path: '/lines' },
      { label: 'Line Details', path: `/lines/${lineId}` },
      { label: 'Route Manager' }
    ])
    
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
      breadcrumbs,
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
/* Route Manager specific styles */

.route-manager-content {
  /* Content wrapper for proper layout */
}

.loading {
  text-align: center;
  color: var(--p-text-muted-color);
  padding: 60px 20px;
  font-size: 1.1rem;
}

.loading-spinner {
  width: 40px;
  height: 40px;
  border: 4px solid var(--p-surface-200);
  border-top: 4px solid var(--p-primary-color);
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
  background: var(--p-surface-0);
  padding: 40px;
  border-radius: var(--p-border-radius);
  box-shadow: var(--p-card-shadow);
}

.error-message h3 {
  color: var(--p-red-500);
  margin-bottom: 10px;
}

.error-message p {
  color: var(--p-text-muted-color);
  margin-bottom: 30px;
}

/* Removed - using PrimeVue Button component */

.content-wrapper {
  display: flex;
  flex-direction: column;
  gap: 30px;
}

/* Removed - using PrimeVue Card components */

/* PrimeVue Card Headers */
.section-header-card {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.25rem 1.25rem 0 1.25rem;
}

.section-header-card h2 {
  margin: 0;
  color: var(--p-text-color);
  font-size: 1.25rem;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.section-header-card h2 i {
  color: var(--p-primary-color);
}

/* Removed obsolete styles */

.overview-stats {
  display: flex;
  gap: 20px;
  flex-wrap: wrap;
}

.stat-card {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 20px;
  background-color: var(--p-surface-50);
  border-radius: var(--p-border-radius);
  min-width: 200px;
  flex: 1;
}

.stat-icon {
  font-size: 1.5rem;
  color: var(--p-primary-color);
}

.stat-info {
  display: flex;
  flex-direction: column;
}

.stat-value {
  font-size: 1.5rem;
  font-weight: bold;
  color: var(--p-primary-color);
  display: block;
}

.stat-label {
  font-size: 0.85rem;
  color: var(--p-text-muted-color);
  margin-top: 5px;
}

.no-stops {
  text-align: center;
  color: var(--p-text-muted-color);
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

.stop-controls {
  display: flex;
  gap: 4px;
}

/* Removed - using PrimeVue Button components */

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


.not-found-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 400px;
}

.not-found {
  text-align: center;
  background: var(--p-surface-0);
  padding: 40px;
  border-radius: var(--p-border-radius);
  box-shadow: var(--p-card-shadow);
}

.not-found h3 {
  color: var(--p-red-500);
  margin-bottom: 15px;
}

@media (max-width: 768px) {
  
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

/* Removed - using PrimeVue Card and Button components */

.loading-students {
  text-align: center;
  padding: 40px 20px;
  color: var(--p-text-muted-color);
}

.loading-students .loading-spinner {
  width: 32px;
  height: 32px;
  border: 3px solid var(--p-surface-200);
  border-top: 3px solid var(--p-green-500);
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 15px;
}

.no-students {
  text-align: center;
  color: var(--p-text-muted-color);
  font-style: italic;
  padding: 40px 20px;
}

.students-list {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.student-assignment-item {
  border: 1px solid var(--p-surface-300);
  border-radius: var(--p-border-radius);
  padding: 20px;
  background-color: var(--p-surface-50);
  transition: box-shadow 0.2s;
}

.student-assignment-item:hover {
  box-shadow: var(--p-card-shadow);
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
  color: var(--p-text-color);
  font-size: 1.1rem;
}

.student-contact {
  display: flex;
  flex-direction: column;
  gap: 4px;
  font-size: 0.85rem;
  color: var(--p-text-muted-color);
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
  border-radius: var(--p-border-radius);
  background-color: var(--p-surface-0);
  border: 1px solid var(--p-surface-300);
}

.stop-info.pickup {
  border-left: 4px solid var(--p-cyan-500);
}

.stop-info.dropoff {
  border-left: 4px solid var(--p-yellow-500);
}

.stop-info.no-stop {
  border-left: 4px solid var(--p-surface-300);
}

.stop-label {
  font-weight: 600;
  color: var(--p-text-color);
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
  color: var(--p-text-color);
  font-weight: 500;
}

.stop-time {
  color: var(--p-primary-color);
  font-size: 0.85rem;
  font-weight: 500;
}

.no-stop-assigned {
  color: var(--p-text-muted-color);
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
  border: 1px solid var(--p-surface-300);
  border-radius: var(--p-border-radius);
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
  border-color: var(--p-primary-color);
  background-color: var(--p-primary-50);
}

.remove-button:hover {
  border-color: var(--p-red-500);
  background-color: var(--p-red-50);
}

.capacity-info {
  margin-top: 20px;
  padding: 15px;
  background-color: var(--p-surface-50);
  border-radius: var(--p-border-radius);
  border: 1px solid var(--p-surface-300);
}

.capacity-bar {
  width: 100%;
  height: 8px;
  background-color: var(--p-surface-300);
  border-radius: 4px;
  overflow: hidden;
  margin-bottom: 8px;
}

.capacity-filled {
  height: 100%;
  background: linear-gradient(90deg, var(--p-green-500) 0%, var(--p-yellow-500) 70%, var(--p-red-500) 100%);
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

.assignment-actions {
  display: flex;
  gap: 0.5rem;
  flex-shrink: 0;
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