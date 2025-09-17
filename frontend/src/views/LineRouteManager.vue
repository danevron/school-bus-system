<template>
  <AppLayout 
    :page-title="line ? `${$t('routeManager.routeManager')} - ${line.name}` : $t('routeManager.routeManager')"
    :breadcrumbs="breadcrumbs"
  >
    <template #actions>
      <Button 
        @click="goBack" 
        icon="pi pi-arrow-left"
        :label="$t('routeManager.backToLine')"
        severity="secondary"
        outlined
      />
    </template>
    
    <div class="route-manager-content">
      <div v-if="loading" class="loading">
        <div class="loading-spinner"></div>
        {{ $t('routeManager.loadingRouteData') }}
      </div>

      <div v-else-if="error" class="error-state">
        <div class="error-message">
          <h3>{{ $t('routeManager.errorLoadingRoute') }}</h3>
          <p>{{ error }}</p>
          <Button @click="fetchLine" :label="$t('common.retry')" icon="pi pi-refresh" severity="info" />
        </div>
      </div>

      <div v-else-if="line" class="content-wrapper">
        <!-- Route Overview -->
        <Card class="route-overview">
          <template #header>
            <div class="section-header-card">
              <h2><i class="pi pi-chart-bar"></i>{{ $t('routeManager.routeOverview') }}</h2>
            </div>
          </template>
          <template #content>
            <div class="overview-stats">
              <div class="stat-card">
                <div class="stat-icon"><i class="pi pi-map-marker"></i></div>
                <div class="stat-info">
                  <div class="stat-value">{{ routeData.stops.length }}</div>
                  <div class="stat-label">{{ $t('routeManager.totalStops') }}</div>
                </div>
              </div>
              <div class="stat-card">
                <div class="stat-icon"><i class="pi pi-compass"></i></div>
                <div class="stat-info">
                  <div class="stat-value">{{ routeData.totalDistance }} {{ $t('common.km') }}</div>
                  <div class="stat-label">{{ $t('routeManager.totalDistance') }}</div>
                </div>
              </div>
              <div class="stat-card">
                <div class="stat-icon"><i class="pi pi-clock"></i></div>
                <div class="stat-info">
                  <div class="stat-value">{{ formatDuration(routeData.estimatedDuration) }}</div>
                  <div class="stat-label">{{ $t('routeManager.estimatedDuration') }}</div>
                </div>
              </div>
              <div class="stat-card">
                <div class="stat-icon"><i class="pi pi-user"></i></div>
                <div class="stat-info">
                  <div class="stat-value">{{ getDriverName(line.driver) }}</div>
                  <div class="stat-label">{{ $t('routeManager.lineDriver') }}</div>
                </div>
              </div>
              <div class="stat-card">
                <div class="stat-icon"><i class="pi pi-car"></i></div>
                <div class="stat-info">
                  <div class="stat-value">{{ getVehicleName(line.vehicle) }}</div>
                  <div class="stat-label">{{ $t('lines.vehicle') }}</div>
                </div>
              </div>
            </div>
          </template>
        </Card>

        <!-- Route Stops -->
        <Card class="route-stops">
          <template #header>
            <div class="section-header-card">
              <h2><i class="pi pi-map"></i>{{ $t('routeManager.routeStops') }}</h2>
              <Button 
                @click="showStopDialog = true" 
                icon="pi pi-plus"
                :label="$t('routeManager.addStop')"
                severity="success"
              />
            </div>
          </template>
          <template #content>
          
          <div v-if="routeData.stops.length === 0" class="no-stops">
            <p>{{ $t('routeManager.noStopsDefined') }}</p>
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
                        {{ $t(`lineView.${stop.type}`) }}
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
                        :title="$t('routeManager.moveUp')"
                        size="small"
                        severity="secondary"
                        outlined
                      />
                      <Button 
                        v-if="index < routeData.stops.length - 1"
                        @click="moveStopDown(index)"
                        icon="pi pi-chevron-down"
                        :disabled="loading"
                        :title="$t('routeManager.moveDown')"
                        size="small"
                        severity="secondary"
                        outlined
                      />
                      <Button 
                        @click="deleteStop(index)"
                        :icon="canDeleteStop(stop) ? 'pi pi-trash' : 'pi pi-lock'"
                        :disabled="loading || !canDeleteStop(stop)"
                        :title="canDeleteStop(stop) ? $t('routeManager.deleteStop') : $t('routeManager.cannotDeleteStopHasStudents')"
                        size="small"
                        :severity="canDeleteStop(stop) ? 'danger' : 'secondary'"
                        outlined
                      />
                    </div>
                  </div>
                </div>

                <div class="stop-details">
                  <div class="stop-address">
                    <strong>{{ $t('lineView.address') }}:</strong> {{ stop.address }}
                  </div>
                  <div class="stop-time">
                    <strong>{{ $t('lineView.estimatedTime') }}:</strong> {{ stop.estimatedTime }} {{ $t('routeManager.minutesFromStart') }}
                  </div>
                  <div v-if="getStopUsageInfo(stop)" class="stop-usage-info">
                    <div class="usage-indicator">
                      <span class="usage-icon">👥</span>
                      <span class="usage-details">
                        ({{ getStopUsageInfo(stop).pickupCount }} {{ $t('lineView.pickup') }}, {{ getStopUsageInfo(stop).dropoffCount }} {{ $t('lineView.dropoff') }})
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
              <h2><i class="pi pi-map-marker"></i>{{ $t('routeManager.interactiveRouteMap') }}</h2>
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
              <h2><i class="pi pi-users"></i>{{ $t('lineView.assignedStudents') }}</h2>
              <Button 
                @click="showStudentDialog = true" 
                icon="pi pi-plus"
                :label="$t('routeManager.addStudent')"
                severity="success"
              />
            </div>
          </template>
          <template #content>
            <div v-if="loadingStudents" class="loading-students">
            <div class="loading-spinner"></div>
            {{ $t('routeManager.loadingStudentAssignments') }}
          </div>

          <div v-else-if="studentAssignments.length === 0" class="no-students">
            <p>{{ $t('routeManager.noStudentsAssigned') }}</p>
          </div>

          <div v-else class="students-list">
            <div
              v-for="assignment in studentAssignments"
              :key="assignment._id"
              class="student-assignment-row"
            >
              <div class="student-basic-info">
                <div class="student-avatar">
                  <Avatar 
                    :label="`${assignment.student.firstName[0]}${assignment.student.lastName[0]}`"
                    size="normal"
                    shape="circle"
                  />
                </div>
                <div class="student-details">
                  <div class="student-name">
                    {{ assignment.student.firstName }} {{ assignment.student.lastName }}
                  </div>
                  <div class="student-contact">
                    <i class="pi pi-phone"></i>
                    {{ assignment.student.phone }}
                  </div>
                </div>
              </div>

              <div class="stop-info-inline">
                <div class="stop-item pickup">
                  <i class="pi pi-sign-in stop-icon pickup-icon"></i>
                  <span class="stop-label">{{ $t('lineView.pickup') }}:</span>
                  <span v-if="assignment.pickupStopDetails" class="stop-details">
                    {{ assignment.pickupStopDetails.name }}
                    <span class="stop-time">({{ formatTime(assignment.pickupStopDetails.estimatedTime) }})</span>
                  </span>
                  <span v-else class="not-assigned">{{ $t('lineView.notAssigned') }}</span>
                </div>
                
                <div class="stop-item dropoff">
                  <i class="pi pi-sign-out stop-icon dropoff-icon"></i>
                  <span class="stop-label">{{ $t('lineView.dropoff') }}:</span>
                  <span v-if="assignment.dropoffStopDetails" class="stop-details">
                    {{ assignment.dropoffStopDetails.name }}
                    <span class="stop-time">({{ formatTime(assignment.dropoffStopDetails.estimatedTime) }})</span>
                  </span>
                  <span v-else class="not-assigned">{{ $t('lineView.notAssigned') }}</span>
                </div>
              </div>

              <div class="row-end-badges">
                <span v-if="assignment.daysOfWeek && assignment.daysOfWeek.length > 0" class="partial-assignment-badge">
                  <i class="pi pi-calendar"></i>
                  {{ $t('routeManager.partialAssignment') }}
                </span>
              </div>

              <div class="assignment-actions">
                <Button 
                  @click="editStudentAssignment(assignment)" 
                  icon="pi pi-pencil"
                  severity="secondary"
                  size="small"
                  outlined
                  :title="$t('routeManager.editStops')"
                />
                <Button 
                  @click="removeStudentAssignment(assignment)" 
                  icon="pi pi-trash"
                  severity="danger"
                  size="small"
                  outlined
                  :title="$t('routeManager.removeStudent')"
                />
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
                {{ studentAssignments.length }} / {{ line?.maxCapacity || 0 }} {{ $t('routeManager.studentsAssignedCapacity') }}
              </div>
            </div>
          </template>
        </Card>

      </div>

      <div v-else class="not-found-container">
        <div class="not-found">
          <h3>{{ $t('lineView.lineNotFound') }}</h3>
          <p>{{ $t('lineView.lineNotFoundDesc') }}</p>
          <Button @click="goBack" :label="$t('lines.backToLines')" icon="pi pi-arrow-left" severity="secondary" />
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

    <!-- Confirm Dialog -->
    <ConfirmDialog />
    </div>
    </AppLayout>
</template>

<script>
import { ref, reactive, computed, inject, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useConfirm } from 'primevue/useconfirm'
import apiService from '../services/api'
import AppLayout from '../components/AppLayout.vue'
import StopCreationDialog from '../components/StopCreationDialog.vue'
import StudentSelectionDialog from '../components/StudentSelectionDialog.vue'
import StopSelectionDialog from '../components/StopSelectionDialog.vue'
import RouteMap from '../components/RouteMap.vue'
import { useToast } from 'primevue/usetoast'

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
    const router = useRouter()
    const route = useRoute()
    const { t } = useI18n()
    const toast = useToast()
    const confirm = useConfirm()
    const lineId = route.params.lineId
    
    const breadcrumbs = computed(() => [
      { label: t('navigation.dashboard'), path: '/home' },
      { label: t('navigation.lineManagement'), path: '/lines' },
      { label: t('lineView.lineDetails'), path: `/lines/${lineId}` },
      { label: t('routeManager.routeManager') }
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
        error.value = t('lineView.noLineIdProvided')
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
          error.value = t('routeManager.lineNotFoundError')
        } else {
          error.value = t('lineView.failedToLoadLineDetails')
        }
      } finally {
        loading.value = false
      }
      
    }

    const updateLineRouteInformation = async (updatedRoute) => {
      const lineId = line.value?._id
      if (!lineId) return

      try {
        loading.value = true
        await apiService.put(`/lines/${lineId}`, { route: {
          totalDistance: updatedRoute.totalDistance,
          estimatedDuration: updatedRoute.estimatedDuration
        }})

        await fetchLine()
      } catch (error) {
        alert(error.response?.data?.message || t('routeManager.failedToUpdateRoute'))
      } finally {
        loading.value = false
      }
    }
    
    const formatDuration = (minutes) => {
      if (minutes < 60) {
        return `${minutes} ${t('common.min')}`
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
      if (!driver) return t('routeManager.noDriverAssigned')
      if (typeof driver === 'string') return t('routeManager.driverAssigned')
      return `${driver.firstName || ''} ${driver.lastName || ''}`.trim() || t('routeManager.driverAssigned')
    }
    
    const getVehicleName = (vehicle) => {
      if (!vehicle) return t('routeManager.noVehicleAssigned')
      if (typeof vehicle === 'string') return t('routeManager.vehicleAssigned')
      return vehicle.licensePlate || t('routeManager.vehicleAssigned')
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
        alert(error.response?.data?.message || t('routeManager.failedToAddStop'))
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
        
        alert(t('routeManager.cannotDeleteStopMessage', { stopName: stop.name, studentCount: uniqueStudents.length, students: uniqueStudents.join(', ') }))
        return
      }
      
      confirm.require({
        message: t('routeManager.confirmDeleteStopSimple'),
        header: t('routeManager.confirmDeleteStopHeader'),
        icon: 'pi pi-exclamation-triangle',
        acceptLabel: t('common.delete'),
        rejectLabel: t('common.cancel'),
        acceptClass: 'p-button-danger',
        rejectClass: 'p-button-secondary p-button-outlined',
        accept: async () => {
          try {
            loading.value = true
            await apiService.delete(`/lines/${route.params.id}/route/stops/${index}`)
            await fetchLine()
            await fetchStopUsage()
          } catch (error) {
            // Handle detailed error from backend
            if (error.response?.data?.affectedStudents) {
              const details = error.response.data
              toast.add({
                severity: 'error',
                summary: details.message,
                detail: `${details.details}\n\n${t('routeManager.removeStudentAssignmentsFirst')}`
              })
            } else {
              toast.add({
                severity: 'error',
                summary: error.response?.data?.message || t('routeManager.failedToDeleteStop')
              })
            }
          } finally {
            loading.value = false
          }
        }
      })
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
        alert(error.response?.data?.message || t('routeManager.failedToReorderStops'))
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

    const handleRouteUpdate = async (routeInfo) => {
      if (routeInfo.totalDistance === routeData.totalDistance &&
          routeInfo.estimatedDuration === routeData.estimatedDuration) {
        return
      }

      routeData.totalDistance = routeInfo.totalDistance
      routeData.estimatedDuration = routeInfo.estimatedDuration
      await updateLineRouteInformation(routeInfo)
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
      
      const { student, pickupStop, dropoffStop, skipStops, daysOfWeek } = assignment
      
      if (student._isEditing) {
        // Update existing assignment
        await updateStudentAssignment(student._assignmentId, pickupStop, dropoffStop, skipStops, daysOfWeek)
      } else {
        // Create new assignment
        await assignStudentToLine(student, pickupStop, dropoffStop, skipStops, daysOfWeek)
      }
      
      selectedStudentForStops.value = null
    }

    const assignStudentToLine = async (student, pickupStop, dropoffStop, skipStops, daysOfWeek) => {
      const lineId = route.params.id
      if (!lineId) return

      try {
        loading.value = true
        
        const requestData = {
          studentId: student._id,
          pickupStop: skipStops ? undefined : pickupStop?.stopId,
          dropoffStop: skipStops ? undefined : dropoffStop?.stopId,
          daysOfWeek: daysOfWeek
        }

        await apiService.post(`/lines/${lineId}/student-assignments`, requestData)
        
        // Refresh student assignments
        await fetchStudentAssignments()
        
      } catch (error) {
        console.error('Failed to assign student to line:', error)
        alert(error.response?.data?.message || t('routeManager.failedToAssignStudent'))
      } finally {
        loading.value = false
      }
    }

    const updateStudentAssignment = async (assignmentId, pickupStop, dropoffStop, skipStops, daysOfWeek) => {
      const lineId = route.params.id
      if (!lineId) return

      try {
        loading.value = true
        
        const requestData = {
          pickupStop: skipStops ? undefined : pickupStop?.stopId,
          dropoffStop: skipStops ? undefined : dropoffStop?.stopId,
          daysOfWeek: daysOfWeek
        }

        await apiService.put(`/lines/${lineId}/student-assignments/${assignmentId}`, requestData)
        
        // Refresh student assignments
        await fetchStudentAssignments()
        
      } catch (error) {
        console.error('Failed to update student assignment:', error)
        alert(error.response?.data?.message || t('routeManager.failedToUpdateStudentAssignment'))
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
        _currentDropoffStop: assignment.dropoffStop,
        _currentDaysOfWeek: assignment.daysOfWeek
      }
      showStopSelectionDialog.value = true
    }

    const removeStudentAssignment = async (assignment) => {
      const lineId = route.params.id
      if (!lineId) return

      confirm.require({
        message: t('routeManager.confirmRemoveStudentSimple'),
        header: t('routeManager.confirmRemoveStudentHeader'),
        icon: 'pi pi-exclamation-triangle',
        acceptLabel: t('common.remove'),
        rejectLabel: t('common.cancel'),
        acceptClass: 'p-button-danger',
        rejectClass: 'p-button-secondary p-button-outlined',
        accept: async () => {
          try {
            loading.value = true
            await apiService.delete(`/lines/${lineId}/student-assignments/${assignment._id}`)
            await fetchStudentAssignments()
          } catch (error) {
            console.error('Failed to remove student assignment:', error)
            alert(error.response?.data?.message || t('routeManager.failedToRemoveStudent'))
          } finally {
            loading.value = false
          }
        }
      })
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

/* Compact Student Row Styles */
.student-assignment-row {
  display: flex;
  align-items: center;
  gap: 1.5rem;
  padding: 0.75rem 1rem;
  border: 1px solid var(--p-surface-border);
  border-radius: var(--p-border-radius);
  background-color: var(--p-surface-0);
  transition: all 0.2s ease;
}

.student-assignment-row:hover {
  box-shadow: var(--p-card-shadow);
  background-color: var(--p-surface-50);
}

.student-basic-info {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  min-width: 170px;
  flex-shrink: 0;
}

.student-avatar {
  flex-shrink: 0;
}

.student-details {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.student-name {
  font-weight: 600;
  color: var(--p-text-color);
  font-size: 1rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.student-contact {
  display: flex;
  align-items: center;
  gap: 0.25rem;
  font-size: 0.8rem;
  color: var(--p-text-muted-color);
}

.student-contact i {
  color: var(--p-primary-color);
  font-size: 0.75rem;
}

.stop-info-inline {
  display: flex;
  gap: 2rem;
  flex: 1;
  align-items: center;
}

.stop-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.85rem;
}

.stop-icon {
  font-size: 0.9rem;
  padding: 0.2rem;
  border-radius: 50%;
  flex-shrink: 0;
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
  white-space: nowrap;
}

.stop-details {
  color: var(--p-text-color);
  font-weight: 500;
}

.stop-time {
  color: var(--p-text-muted-color);
  font-weight: 400;
  font-size: 0.8rem;
}

.not-assigned {
  color: var(--p-text-muted-color);
  font-style: italic;
  font-size: 0.8rem;
}

.partial-assignment-badge {
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
  padding: 0.25rem 0.5rem;
  background-color: var(--p-orange-100);
  color: var(--p-orange-700);
  border-radius: 12px;
  border: 1px solid var(--p-orange-200);
  font-size: 0.75rem;
  font-weight: 500;
  white-space: nowrap;
}

.partial-assignment-badge i {
  font-size: 0.7rem;
}

.row-end-badges {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  flex-shrink: 0;
}

.assignment-actions {
  display: flex;
  gap: 0.5rem;
  flex-shrink: 0;
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