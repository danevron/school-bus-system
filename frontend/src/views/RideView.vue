<template>
  <AppLayout 
    :page-title="ride?.route?.name || $t('rideView.rideDetails')"
    :breadcrumbs="breadcrumbs"
  >
    <template #actions>
      <Button 
        @click="goBack" 
        icon="pi pi-arrow-left"
        :label="$t('rideView.backToRides')"
        severity="secondary"
        outlined
      />
      <Button 
        v-if="canBookRide" 
        @click="openBookingModal" 
        icon="pi pi-calendar-plus"
        :label="$t('rideView.bookRide')"
        severity="success"
      />
      <Button 
        v-if="ride && ride.status === 'scheduled'" 
        @click="startRide" 
        icon="pi pi-play"
        :label="$t('rideView.startRide')"
        severity="success"
      />
      <Button 
        v-if="ride && ride.status === 'in_progress'" 
        @click="openLiveTracking" 
        icon="pi pi-map-marker"
        :label="$t('rideView.trackOnMap')"
        severity="warning"
      />
      <Button 
        v-if="ride && ride.status === 'in_progress'" 
        @click="endRide" 
        icon="pi pi-stop"
        :label="$t('rideView.endRide')"
        severity="info"
      />
    </template>
    
    <div v-if="loading" class="loading-container">
      <Card>
        <template #content>
          <div class="loading-content">
            <i class="pi pi-spin pi-spinner loading-icon"></i>
            <h3>{{ $t('rideView.loadingRideDetails') }}</h3>
            <p>{{ $t('rideView.pleaseWaitFetchingRideInfo') }}</p>
          </div>
        </template>
      </Card>
    </div>

    <div v-else-if="error" class="error-container">
        <Card>
          <template #content>
            <div class="error-content">
              <i class="pi pi-exclamation-triangle error-icon"></i>
              <h3>{{ $t('rideView.errorLoadingRide') }}</h3>
              <p>{{ error }}</p>
              <Button 
                @click="fetchRide" 
                icon="pi pi-refresh"
                :label="$t('common.retry')"
                severity="info"
              />
            </div>
          </template>
        </Card>
    </div>

    <div v-if="ride" class="content-grid">
        <!-- Status Notice Section -->
        <div v-if="ride.status === 'in_progress'" class="notice-section">
          <Card class="in-progress-notice-card">
            <template #content>
              <div class="notice-content">
                <div class="notice-header">
                  <i class="pi pi-car notice-icon"></i>
                  <h3>{{ $t('rideView.rideInProgress') }}</h3>
                </div>
                <p>
                  {{ $t('rideView.rideInProgressDesc') }}
                </p>
              </div>
            </template>
          </Card>
        </div>

        <!-- Basic Information Section -->
        <Card class="info-section">
          <template #header>
            <div class="section-header-card">
              <h2><i class="pi pi-info-circle"></i>{{ $t('rideView.rideInformation') }}</h2>
            </div>
          </template>
          <template #content>
          <div class="info-grid">
            <div class="info-group">
              <h4>{{ $t('rideView.basicDetails') }}</h4>
              <div class="info-item">
                <span class="info-label">{{ $t('common.date') }}:</span>
                <span class="info-value">{{ formatDate(ride.date) }}</span>
              </div>
              <div class="info-item">
                <span class="info-label">{{ $t('rideView.scheduledStart') }}:</span>
                <span class="info-value">{{ formatTime(ride.startTime) }}</span>
              </div>
              <div v-if="ride.actualStartTime" class="info-item">
                <span class="info-label">{{ $t('rideView.actualStart') }}:</span>
                <span class="info-value">{{ formatTime(ride.actualStartTime) }}</span>
              </div>
              <div v-if="ride.actualEndTime" class="info-item">
                <span class="info-label">{{ $t('rideView.actualEnd') }}:</span>
                <span class="info-value">{{ formatTime(ride.actualEndTime) }}</span>
              </div>
              <div class="info-item">
                <span class="info-label">{{ $t('common.status') }}:</span>
                <span class="info-value">
                  <Tag :value="getStatusLabel(ride.status)" :severity="getStatusTagSeverity(ride.status)" />
                </span>
              </div>
            </div>

            <div class="info-group">
              <h4>{{ $t('rideView.assignment') }}</h4>
              <div class="info-item">
                <span class="info-label">{{ $t('rideView.driver') }}:</span>
                <span class="info-value">{{ getDriverName(ride.driver) }}</span>
              </div>
              <div class="info-item">
                <span class="info-label">{{ $t('rideView.vehicle') }}:</span>
                <span class="info-value">{{ getVehicleName(ride.vehicle) }}</span>
              </div>
              <div v-if="ride.lineId" class="info-item">
                <span class="info-label">{{ $t('rideView.line') }}:</span>
                <span class="info-value">
                  <button 
                    @click="viewLine(ride.lineId._id)"
                    class="line-link-button"
                  >
                    {{ ride.lineId.name }}
                  </button>
                </span>
              </div>
            </div>

            <div class="info-group">
              <h4>{{ $t('rideView.capacity') }}</h4>
              <div class="info-item">
                <span class="info-label">{{ $t('rideView.maxCapacity') }}:</span>
                <span class="info-value">{{ ride.maxCapacity }} {{ $t('rideView.seats') }}</span>
              </div>
              <div class="info-item">
                <span class="info-label">{{ $t('rideView.availableSeats') }}:</span>
                <span class="info-value">{{ ride.availableSeats }} {{ $t('rideView.seats') }}</span>
              </div>
              <div class="info-item">
                <span class="info-label">{{ $t('rideView.bookedSeats') }}:</span>
                <span class="info-value">{{ ride.maxCapacity - ride.availableSeats }} {{ $t('rideView.seats') }}</span>
              </div>
              <div class="info-item">
                <span class="info-label">{{ $t('rideView.waitingList') }}:</span>
                <span class="info-value">{{ waitingListCount }} {{ $t('rideView.seats') }}</span>
              </div>
            </div>
          </div>

            <div v-if="ride.notes" class="notes-section">
              <h4><i class="pi pi-file-edit"></i>{{ $t('rideView.notes') }}</h4>
              <div class="notes-content">{{ ride.notes }}</div>
            </div>
          </template>
        </Card>

        <!-- Route Section -->
        <Card class="route-section">
          <template #header>
            <div class="section-header-card">
              <h2><i class="pi pi-map"></i>{{ $t('rideView.routeDetails') }}</h2>
            </div>
          </template>
          <template #content>
          <div v-if="ride.route && ride.route.stops && ride.route.stops.length > 0" class="route-content">
            <div class="route-stats">
              <div class="stat">
                <i class="pi pi-map-marker stat-icon"></i>
                <div class="stat-info">
                  <span class="stat-value">{{ ride.route.stops.length }}</span>
                  <span class="stat-label">{{ $t('rideView.stops') }}</span>
                </div>
              </div>
              <div class="stat">
                <i class="pi pi-globe stat-icon"></i>
                <div class="stat-info">
                  <span class="stat-value">{{ ride.route.totalDistance || 0 }} {{ $t('common.km') }}</span>
                  <span class="stat-label">{{ $t('rideView.distance') }}</span>
                </div>
              </div>
              <div class="stat">
                <i class="pi pi-clock stat-icon"></i>
                <div class="stat-info">
                  <span class="stat-value">{{ ride.route.estimatedDuration || 0 }} {{ $t('common.min') }}</span>
                  <span class="stat-label">{{ $t('rideView.duration') }}</span>
                </div>
              </div>
            </div>
            <div class="route-stops">
              <h4>{{ $t('rideView.routeStops') }}</h4>
              <div class="stops-list">
                <div v-for="(stop, index) in ride.route.stops" :key="index" class="stop-item">
                  <span class="stop-number">{{ index + 1 }}</span>
                  <div class="stop-info">
                    <div class="stop-main">
                      <span class="stop-name">{{ stop.name }}</span>
                      <span class="stop-type" :class="stop.type">{{ $t('rideView.' + stop.type) }}</span>
                    </div>
                    <div class="stop-address">{{ stop.address }}</div>
                    <div v-if="stop.estimatedArrivalTime" class="stop-time">
                      <span class="time-label">{{ $t('rideView.estimated') }}:</span>
                      <span class="time-value">{{ formatTime(stop.estimatedArrivalTime) }}</span>
                    </div>
                    <div v-if="stop.actualArrivalTime" class="stop-time">
                      <span class="time-label">{{ $t('rideView.actual') }}:</span>
                      <span class="time-value">{{ formatTime(stop.actualArrivalTime) }}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div v-else class="empty-route">
            <i class="pi pi-map empty-icon"></i>
            <h3>{{ $t('rideView.noRouteDefined') }}</h3>
            <p>{{ $t('rideView.noRouteDefinedDesc') }}</p>
          </div>
          </template>
        </Card>

        <!-- Bookings Section -->
        <Card class="bookings-section">
          <template #header>
            <div class="section-header-card">
              <h2><i class="pi pi-users"></i>{{ $t('rideView.passengerBookings') }}</h2>
              <div class="header-controls">
                <div class="show-cancelled-toggle">
                  <Checkbox 
                    v-model="showCancelled"
                    inputId="show-cancelled"
                    binary
                  />
                  <label for="show-cancelled" class="toggle-text">{{ $t('rideView.showCancelled') }}</label>
                </div>
                <Button 
                  @click="loadBookings" 
                  icon="pi pi-refresh"
                  :label="$t('common.refresh')"
                  severity="secondary"
                  size="small"
                  outlined
                />
              </div>
            </div>
          </template>
          <template #content>
          
            <div v-if="bookingsLoading" class="bookings-loading">
              <i class="pi pi-spin pi-spinner"></i>
              <span>{{ $t('rideView.loadingBookings') }}</span>
            </div>
            
            <div v-else-if="filteredBookings.length === 0" class="empty-bookings">
              <i class="pi pi-calendar-times empty-icon"></i>
              <h3>{{ $t('rideView.noBookings') }}</h3>
              <p v-if="!showCancelled && bookings.length > 0">{{ $t('rideView.allBookingsCancelled') }}</p>
              <p v-else>{{ $t('rideView.noPassengersBooked') }}</p>
            </div>
          
          <div v-else class="bookings-list">
            <div v-for="booking in filteredBookings" :key="booking._id" class="booking-card">
              <div class="booking-header">
                <div class="passenger-avatar">
                  <Avatar 
                    :label="`${getPassengerName(booking.passenger).split(' ').map(n => n[0]).join('')}`"
                    size="large"
                    shape="circle"
                  />
                </div>
                <div class="passenger-info">
                  <div class="passenger-name">
                    <i class="pi pi-user"></i>
                    {{ getPassengerName(booking.passenger) }}
                    <Tag v-if="booking.passenger.isGuest" 
                         :value="$t('common.guest')" 
                         severity="warn" 
                         class="guest-tag" />
                  </div>
                  <div class="booking-status-container">
                    <span class="booking-status-badge" :class="getBookingStatusClass(booking.status)">
                      <i :class="getBookingStatusIcon(booking.status)"></i>
                      {{ getBookingStatusLabel(booking.status) }}
                    </span>
                  </div>
                </div>
                <div class="stops-info">
                  <div class="stops-compact">
                    <div class="stop-compact pickup">
                      <i class="pi pi-sign-in stop-icon pickup-icon"></i>
                      <span class="stop-label">{{ $t('rideView.pickup') }}:</span>
                      <span class="stop-name">{{ booking.pickupStop.name }}</span>
                    </div>
                    <div class="stop-compact dropoff">
                      <i class="pi pi-sign-out stop-icon dropoff-icon"></i>
                      <span class="stop-label">{{ $t('rideView.dropoff') }}:</span>
                      <span v-if="booking.dropoffStop" class="stop-name">{{ booking.dropoffStop.name }}</span>
                      <span v-else class="not-assigned">{{ $t('rideView.notSpecified') }}</span>
                    </div>
                    <!-- Parent Information -->
                    <div v-if="booking.passenger.parents && booking.passenger.parents.length > 0" class="parents-info">
                      <i class="pi pi-users parent-icon"></i>
                      <span class="parent-label">{{ $t('rideView.parents') }}:</span>
                      <div class="parents-list">
                        <div v-for="parent in booking.passenger.parents" :key="parent._id" class="parent-contact">
                          <span class="parent-name">{{ parent.firstName }} {{ parent.lastName }}</span>
                          <span v-if="parent.phone" class="parent-phone">{{ parent.phone }}</span>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
                <div class="booking-actions">
                  <!-- Admit/Cancel buttons for waiting list bookings -->
                  <template v-if="booking.status === 'waiting_list'">
                    <Button 
                      @click="admitWaitingListBooking(booking._id)"
                      icon="pi pi-check"
                      :label="$t('rideView.admit')"
                      severity="success"
                      size="small"
                    />
                    <Button 
                      @click="cancelBooking(booking._id)"
                      icon="pi pi-times"
                      :label="$t('common.cancel')"
                      severity="danger"
                      size="small"
                      outlined
                    />
                  </template>

                  <!-- Confirm/Cancel buttons for unconfirmed bookings -->
                  <template v-if="booking.status === 'unconfirmed'">
                    <Button 
                      @click="confirmBooking(booking._id)"
                      icon="pi pi-check"
                      :label="$t('common.confirm')"
                      severity="info"
                      size="small"
                    />
                    <Button 
                      @click="cancelBooking(booking._id)"
                      icon="pi pi-times"
                      :label="$t('common.cancel')"
                      severity="danger"
                      size="small"
                      outlined
                    />
                  </template>

                  <!-- Cancel button for confirmed bookings (that haven't started yet) -->
                  <template v-if="booking.status === 'confirmed' && ride.status === 'scheduled'">
                    <Button 
                      @click="cancelBooking(booking._id)"
                      icon="pi pi-times"
                      :label="$t('common.cancel')"
                      severity="danger"
                      size="small"
                      outlined
                    />
                  </template>

                  <!-- Check In button for confirmed bookings during ride -->
                  <template v-if="booking.status === 'confirmed' && ride.status === 'in_progress'">
                    <Button 
                      @click="checkInPassenger(booking._id)"
                      icon="pi pi-sign-in"
                      :label="$t('rideView.checkIn')"
                      severity="info"
                      size="small"
                    />
                  </template>

                  <!-- Drop Off button for checked-in passengers -->
                  <template v-if="booking.status === 'checked_in' && ride.status === 'in_progress'">
                    <Button 
                      @click="dropOffPassenger(booking._id)"
                      icon="pi pi-sign-out"
                      :label="$t('rideView.dropOff')"
                      severity="success"
                      size="small"
                    />
                  </template>
                </div>
              </div>
            </div>
          </div>
          </template>
        </Card>

        <!-- Route Map Section -->
        <Card v-if="ride.route && ride.route.stops && ride.route.stops.length > 0" class="map-section">
          <template #header>
            <div class="section-header-card">
              <h2><i class="pi pi-map"></i>{{ $t('rideView.interactiveRouteMap') }}</h2>
            </div>
          </template>
          <template #content>
            <RouteMap
              :stops="ride.route.stops"
              :studentAssignments="[]"
              :showDrivingInstructions="false"
              :showDrivingRoute="true"
              mapHeight="600px"
              mapId="ride-route-map"
            />
          </template>
        </Card>
      </div>
      
      <div v-else class="not-found-container">
        <Card>
          <template #content>
            <div class="not-found-message">
              <i class="pi pi-exclamation-triangle not-found-icon"></i>
              <h2>{{ $t('rideView.rideNotFound') }}</h2>
              <p>{{ $t('rideView.rideNotFoundDesc') }}</p>
              <Button 
                @click="goBack" 
                icon="pi pi-arrow-left"
                :label="$t('rideView.backToRides')"
                severity="secondary"
              />
            </div>
          </template>
        </Card>
      </div>

    <!-- Booking Modal -->
    <div v-if="showBookingModal" class="modal-overlay" @click="closeBookingModal">
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <h3>{{ $t('rideView.bookRide') }}</h3>
          <button @click="closeBookingModal" class="close-button">×</button>
        </div>
        
        <div class="modal-body">
          <div v-if="bookingFormLoading" class="loading-text">
            {{ $t('rideView.loadingUsersAndStops') }}
          </div>
          
          <form v-else @submit.prevent="submitBooking" class="booking-form">
            <!-- Passenger Selection -->
            <div class="form-group">
              <label for="passenger">{{ $t('rideView.selectPassenger') }}:</label>
              <select 
                id="passenger" 
                v-model="bookingForm.passengerId" 
                required 
                class="form-control"
              >
                <option value="">{{ $t('rideView.choosePassenger') }}</option>
                <option 
                  v-for="user in users" 
                  :key="user._id" 
                  :value="user._id"
                >
                  {{ user.firstName }} {{ user.lastName }} ({{ user.role }})
                </option>
              </select>
            </div>

            <!-- Pickup Stop Selection -->
            <div class="form-group">
              <label for="pickupStop">{{ $t('rideView.pickupStop') }}:</label>
              <select 
                id="pickupStop" 
                v-model="bookingForm.pickupStopId" 
                required 
                class="form-control"
              >
                <option value="">{{ $t('rideView.choosePickupStop') }}</option>
                <option 
                  v-for="stop in pickupStops" 
                  :key="stop.stopId" 
                  :value="stop.stopId"
                >
                  {{ stop.name }} - {{ stop.address }}
                </option>
              </select>
            </div>

            <!-- Dropoff Stop Selection -->
            <div class="form-group">
              <label for="dropoffStop">{{ $t('rideView.dropoffStop') }}:</label>
              <select 
                id="dropoffStop" 
                v-model="bookingForm.dropoffStopId" 
                required
                class="form-control"
              >
                <option value="">{{ $t('rideView.chooseDropoffStop') }}</option>
                <option 
                  v-for="stop in dropoffStops" 
                  :key="stop.stopId" 
                  :value="stop.stopId"
                >
                  {{ stop.name }} - {{ stop.address }}
                </option>
              </select>
            </div>

            <!-- Notes -->
            <div class="form-group">
              <label for="notes">{{ $t('rideView.notesOptional') }}:</label>
              <textarea 
                id="notes" 
                v-model="bookingForm.notes" 
                class="form-control"
                rows="3"
                :placeholder="$t('rideView.specialRequirementsPlaceholder')"
              ></textarea>
            </div>

            <!-- Form Actions -->
            <div class="form-actions">
              <button 
                type="button" 
                @click="closeBookingModal" 
                class="cancel-button"
              >
                {{ $t('common.cancel') }}
              </button>
              <button 
                type="submit" 
                :disabled="bookingSubmitting || !isBookingFormValid"
                class="submit-button"
              >
                {{ bookingSubmitting ? $t('rideView.creating') : $t('rideView.createBooking') }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>

    <!-- Live Tracking Modal -->
    <div v-if="showLiveTrackingModal" class="modal-overlay" @click="closeLiveTracking">
      <div class="modal-content live-tracking-modal" @click.stop>
        <div class="modal-header">
          <h3>🚌 {{ $t('rideView.liveRideTracking') }}</h3>
          <div class="tracking-status">
            <span v-if="trackingActive" class="status-indicator active">● {{ $t('rideView.live') }}</span>
            <span v-else class="status-indicator inactive">● {{ $t('rideView.disconnected') }}</span>
          </div>
          <button @click="closeLiveTracking" class="close-button">×</button>
        </div>
        
        <div class="modal-body tracking-body">
          <div v-if="trackingLoading" class="loading-text">
            {{ $t('rideView.loadingRideTrackingData') }}
          </div>
          
          <div v-else-if="trackingError" class="error-text">
            <p>{{ trackingError }}</p>
            <button @click="startTracking" class="retry-button">{{ $t('common.retry') }}</button>
          </div>
          
          <div v-else class="tracking-container">
            <!-- Tracking Info Header -->
            <div class="tracking-info">
              <div class="info-item">
                <span class="info-label">{{ $t('rideView.lastUpdate') }}:</span>
                <span class="info-value">{{ lastUpdateTime || $t('rideView.noDataYet') }}</span>
              </div>
              <div v-if="rideProgress" class="info-item">
                <span class="info-label">{{ $t('common.status') }}:</span>
                <span class="info-value">{{ rideProgress.status }}</span>
              </div>
              <div v-if="rideProgress && rideProgress.totalDistance" class="info-item">
                <span class="info-label">{{ $t('rideView.distanceTraveled') }}:</span>
                <span class="info-value">{{ Math.round(rideProgress.totalDistance * 100) / 100 }} {{ $t('common.km') }}</span>
              </div>
            </div>
            
            <!-- Map Container -->
            <div class="map-container">
              <LiveTrackingMap
                :ride="ride"
                :rideProgress="rideProgress"
                :busLocation="currentBusLocation"
                mapHeight="500px"
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  </AppLayout>
</template>

<script>
import { ref, onMounted, computed, onUnmounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useToast } from 'primevue/usetoast'
import apiService from '../services/api.js'
import AppLayout from '../components/AppLayout.vue'
import RouteMap from '../components/RouteMap.vue'
import LiveTrackingMap from '../components/LiveTrackingMap.vue'

export default {
  name: 'RideView',
  components: {
    AppLayout,
    RouteMap,
    LiveTrackingMap
  },
  setup() {
    const router = useRouter()
    const route = useRoute()
    const { t: $t } = useI18n()
    const toast = useToast()
    const rideId = route.params.id

    const breadcrumbs = computed(() => [
      { label: $t('navigation.dashboard'), path: '/home' },
      { label: $t('navigation.rideManagement'), path: '/rides' },
      { label: $t('rideView.rideDetails') }
    ])

    const ride = ref(null)
    const bookings = ref([])
    const loading = ref(true)
    const bookingsLoading = ref(false)
    const error = ref('')
    const showCancelled = ref(false)
    
    // Booking modal state
    const showBookingModal = ref(false)
    const bookingFormLoading = ref(false)
    const bookingSubmitting = ref(false)
    const users = ref([])
    const bookingForm = ref({
      passengerId: '',
      pickupStopId: '',
      dropoffStopId: '',
      notes: ''
    })

    // Live tracking state
    const showLiveTrackingModal = ref(false)
    const trackingLoading = ref(false)
    const trackingError = ref('')
    const trackingActive = ref(false)
    const rideProgress = ref(null)
    const currentBusLocation = ref(null)
    const lastUpdateTime = ref('')
    let trackingInterval = null

    // Computed properties
    const canBookRide = computed(() => {
      return ride.value && 
             ride.value.status === 'scheduled'
    })

    const pickupStops = computed(() => {
      return ride.value?.route?.stops?.filter(stop => stop.type === 'pickup') || []
    })

    const dropoffStops = computed(() => {
      return ride.value?.route?.stops?.filter(stop => stop.type === 'dropoff') || []
    })

    const isBookingFormValid = computed(() => {
      return bookingForm.value.passengerId && bookingForm.value.pickupStopId && bookingForm.value.dropoffStopId
    })

    const waitingListCount = computed(() => {
      return bookings.value.filter(booking => booking.status === 'waiting_list').length
    })

    const filteredBookings = computed(() => {
      if (showCancelled.value) {
        return bookings.value
      }
      return bookings.value.filter(booking => booking.status !== 'cancelled')
    })


    const fetchRide = async () => {
      try {
        loading.value = true
        error.value = ''
        const response = await apiService.get(`/rides/${rideId}`)
        ride.value = response.data.ride
      } catch (err) {
        console.error('Error loading ride:', err)
        error.value = err.response?.data?.message || 'Failed to load ride details'
      } finally {
        loading.value = false
      }
    }

    const loadBookings = async () => {
      try {
        bookingsLoading.value = true
        const response = await apiService.get(`/bookings/ride/${rideId}`)
        bookings.value = response.data.bookings || []
      } catch (err) {
        console.error('Error loading bookings:', err)
        bookings.value = []
      } finally {
        bookingsLoading.value = false
      }
    }

    const formatDate = (dateString) => {
      if (!dateString) return $t('common.notSet')
      return new Date(dateString).toLocaleDateString()
    }

    const formatTime = (timeString) => {
      if (!timeString) return $t('common.notSet')
      return new Date(timeString).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    }

    const getStatusTagSeverity = (status) => {
      const severities = {
        'scheduled': 'info',
        'in_progress': 'warn',
        'completed': 'success',
        'cancelled': 'danger'
      }
      return severities[status] || 'secondary'
    }

    const getStatusLabel = (status) => {
      const labels = {
        'scheduled': $t('rides.scheduled'),
        'in_progress': $t('rides.inProgress'),
        'completed': $t('rides.completed'),
        'cancelled': $t('rides.cancelled')
      }
      return labels[status] || status
    }

    const getBookingStatusClass = (status) => {
      return `booking-status-${status?.toLowerCase().replace('_', '-')}`
    }

    const getBookingStatusLabel = (status) => {
      const labels = {
        'unconfirmed': $t('rideView.unconfirmed'),
        'confirmed': $t('rideView.confirmed'),
        'cancelled': $t('rideView.cancelled'),
        'checked_in': $t('rideView.checkedIn'),
        'completed': $t('rideView.completed'),
        'waiting_list': $t('rideView.waitingList')
      }
      return labels[status] || status
    }

    const getBookingStatusIcon = (status) => {
      const icons = {
        'unconfirmed': 'pi pi-clock',
        'confirmed': 'pi pi-check',
        'cancelled': 'pi pi-times',
        'checked_in': 'pi pi-sign-in',
        'completed': 'pi pi-check-circle',
        'waiting_list': 'pi pi-hourglass'
      }
      return icons[status] || 'pi pi-info-circle'
    }

    const getDriverName = (driver) => {
      if (typeof driver === 'object' && driver) {
        return `${driver.firstName} ${driver.lastName}`
      }
      return $t('common.loading')
    }

    const getVehicleName = (vehicle) => {
      if (typeof vehicle === 'object' && vehicle) {
        return `${vehicle.make} ${vehicle.vehicleModel} (${vehicle.licensePlate})`
      }
      return $t('common.loading')
    }

    const getPassengerName = (passenger) => {
      if (typeof passenger === 'object' && passenger) {
        return `${passenger.firstName} ${passenger.lastName}`
      }
      return $t('common.loading')
    }

    const goBack = () => {
      router.push('/rides')
    }

    const viewLine = (lineId) => {
      router.push(`/lines/${lineId}`)
    }

    const startRide = async () => {
      try {
        await apiService.post(`/rides/${rideId}/start`)
        await fetchRide() // Reload ride data
      } catch (err) {
        toast.add({
          severity: 'error',
          summary: $t('common.error'),
          detail: $t('rideView.errorStartingRide') + ': ' + (err.response?.data?.message || err.message),
          life: 5000
        })
      }
    }

    const endRide = async () => {
      try {
        await apiService.post(`/rides/${rideId}/end`)
        await fetchRide() // Reload ride data
      } catch (err) {
        toast.add({
          severity: 'error',
          summary: $t('common.error'),
          detail: $t('rideView.errorEndingRide') + ': ' + (err.response?.data?.message || err.message),
          life: 5000
        })
      }
    }

    const checkInPassenger = async (bookingId) => {
      try {
        await apiService.post(`/bookings/${bookingId}/checkin`)
        await loadBookings() // Reload bookings
      } catch (err) {
        toast.add({
          severity: 'error',
          summary: $t('common.error'),
          detail: 'Error checking in passenger: ' + (err.response?.data?.message || err.message),
          life: 5000
        })
      }
    }

    const dropOffPassenger = async (bookingId) => {
      try {
        await apiService.post(`/bookings/${bookingId}/dropoff`)
        await loadBookings() // Reload bookings
      } catch (err) {
        toast.add({
          severity: 'error',
          summary: $t('common.error'),
          detail: 'Error dropping off passenger: ' + (err.response?.data?.message || err.message),
          life: 5000
        })
      }
    }

    const confirmBooking = async (bookingId) => {
      try {
        await apiService.post(`/bookings/${bookingId}/confirm`)
        await loadBookings() // Reload bookings
        await fetchRide() // Reload ride to update available seats
        toast.add({
          severity: 'success',
          summary: $t('common.success'),
          detail: $t('rideView.bookingConfirmedSuccess'),
          life: 3000
        })
      } catch (err) {
        toast.add({
          severity: 'error',
          summary: $t('common.error'),
          detail: 'Error confirming booking: ' + (err.response?.data?.message || err.message),
          life: 5000
        })
      }
    }

    const cancelBooking = async (bookingId) => {
      try {
        await apiService.post(`/bookings/${bookingId}/cancel`, {})
        await loadBookings() // Reload bookings
        await fetchRide() // Reload ride to update available seats
        toast.add({
          severity: 'success',
          summary: $t('common.success'),
          detail: $t('rideView.bookingCancelledSuccess'),
          life: 3000
        })
      } catch (err) {
        toast.add({
          severity: 'error',
          summary: $t('common.error'),
          detail: 'Error cancelling booking: ' + (err.response?.data?.message || err.message),
          life: 5000
        })
      }
    }

    const admitWaitingListBooking = async (bookingId) => {
      try {
        await apiService.post(`/bookings/${bookingId}/admit`)
        await loadBookings() // Reload bookings
        await fetchRide() // Reload ride to update available seats
        toast.add({
          severity: 'success',
          summary: $t('common.success'),
          detail: $t('rideView.waitingListBookingAdmittedSuccess'),
          life: 3000
        })
      } catch (err) {
        toast.add({
          severity: 'error',
          summary: $t('common.error'),
          detail: 'Error admitting waiting list booking: ' + (err.response?.data?.message || err.message),
          life: 5000
        })
      }
    }

    // Live tracking functions
    const fetchRideProgress = async () => {
      try {
        trackingError.value = ''
        const response = await apiService.get(`/rides/${rideId}/progress`)
        rideProgress.value = response.data
        
        if (response.data.currentLocation) {
          currentBusLocation.value = response.data.currentLocation.coordinates
          lastUpdateTime.value = new Date(response.data.lastUpdated).toLocaleTimeString()
          trackingActive.value = true
        } else {
          trackingActive.value = false
        }
        
        return response.data
      } catch (err) {
        console.error('Error fetching ride progress:', err)
        trackingError.value = err.response?.data?.message || 'Failed to load tracking data'
        trackingActive.value = false
        throw err
      }
    }

    const startTracking = async () => {
      try {
        trackingLoading.value = true
        trackingError.value = ''
        
        // Initial fetch
        await fetchRideProgress()
        
        // Set up polling every 10 seconds
        if (trackingInterval) {
          clearInterval(trackingInterval)
        }
        
        trackingInterval = setInterval(async () => {
          try {
            await fetchRideProgress()
          } catch (err) {
            console.error('Error in tracking poll:', err)
            // Don't stop tracking on individual poll failures
          }
        }, 10000) // Poll every 10 seconds
        
      } catch (err) {
        console.error('Error starting tracking:', err)
        trackingError.value = 'Failed to start live tracking'
      } finally {
        trackingLoading.value = false
      }
    }

    const stopTracking = () => {
      if (trackingInterval) {
        clearInterval(trackingInterval)
        trackingInterval = null
      }
      trackingActive.value = false
      rideProgress.value = null
      currentBusLocation.value = null
      lastUpdateTime.value = ''
    }

    const openLiveTracking = async () => {
      showLiveTrackingModal.value = true
      await startTracking()
    }

    const closeLiveTracking = () => {
      showLiveTrackingModal.value = false
      stopTracking()
    }

    // Booking functions
    const loadUsers = async () => {
      try {
        const response = await apiService.get('/auth/users')
        users.value = response.users || []
      } catch (err) {
        console.error('Error loading users:', err)
        users.value = []
      }
    }

    const closeBookingModal = () => {
      showBookingModal.value = false
      bookingForm.value = {
        passengerId: '',
        pickupStopId: '',
        dropoffStopId: '',
        notes: ''
      }
    }

    const submitBooking = async () => {
      try {
        bookingSubmitting.value = true
        
        const selectedPickupStop = pickupStops.value.find(stop => stop.stopId === bookingForm.value.pickupStopId)
        const selectedDropoffStop = dropoffStops.value.find(stop => stop.stopId === bookingForm.value.dropoffStopId)
        
        const bookingData = {
          rideId: rideId,
          passengerId: bookingForm.value.passengerId,
          pickupStop: {
            stopId: selectedPickupStop.stopId,
            name: selectedPickupStop.name,
            address: selectedPickupStop.address
          },
          dropoffStop: {
            stopId: selectedDropoffStop.stopId,
            name: selectedDropoffStop.name,
            address: selectedDropoffStop.address
          },
          notes: bookingForm.value.notes || undefined
        }

        await apiService.post('/bookings', bookingData)
        
        // Close modal and reload data
        closeBookingModal()
        await fetchRide() // Reload ride to update available seats
        await loadBookings() // Reload bookings to show new booking
        
        // Check if booking went to waiting list by checking available seats
        if (ride.value.availableSeats <= 0) {
          toast.add({
            severity: 'info',
            summary: $t('common.info'),
            detail: $t('rideView.bookingAddedToWaitingList'),
            life: 5000
          })
        } else {
          toast.add({
            severity: 'success',
            summary: $t('common.success'),
            detail: $t('rideView.bookingCreatedSuccess'),
            life: 3000
          })
        }
        
      } catch (err) {
        console.error('Error creating booking:', err)
        toast.add({
          severity: 'error',
          summary: $t('common.error'),
          detail: $t('rideView.errorCreatingBooking') + ': ' + (err.response?.data?.message || err.message),
          life: 5000
        })
      } finally {
        bookingSubmitting.value = false
      }
    }

    const openBookingModal = async () => {
      showBookingModal.value = true
      bookingFormLoading.value = true
      await loadUsers()
      bookingFormLoading.value = false
    }

    onMounted(() => {
      fetchRide()
      loadBookings()
    })

    onUnmounted(() => {
      stopTracking() // Clean up tracking interval on component unmount
    })

    return {
      $t,
      ride,
      bookings,
      loading,
      bookingsLoading,
      breadcrumbs,
      error,
      showCancelled,
      filteredBookings,
      fetchRide,
      loadBookings,
      formatDate,
      formatTime,
      getStatusTagSeverity,
      getStatusLabel,
      getBookingStatusClass,
      getBookingStatusLabel,
      getBookingStatusIcon,
      getDriverName,
      getVehicleName,
      getPassengerName,
      goBack,
      viewLine,
      startRide,
      endRide,
      checkInPassenger,
      dropOffPassenger,
      confirmBooking,
      cancelBooking,
      admitWaitingListBooking,
      // Booking functionality
      canBookRide,
      showBookingModal,
      bookingFormLoading,
      bookingSubmitting,
      users,
      bookingForm,
      pickupStops,
      dropoffStops,
      isBookingFormValid,
      waitingListCount,
      openBookingModal,
      closeBookingModal,
      submitBooking,
      // Live tracking functionality
      showLiveTrackingModal,
      trackingLoading,
      trackingError,
      trackingActive,
      rideProgress,
      currentBusLocation,
      lastUpdateTime,
      openLiveTracking,
      closeLiveTracking,
      startTracking
    }
  }
}
</script>

<style scoped>
/* Modern Component Styles */
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

.header-controls {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.show-cancelled-toggle {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.toggle-text {
  font-size: 0.875rem;
  color: var(--p-text-color);
}

.loading-content, .error-content, .not-found-message {
  text-align: center;
  padding: 2rem;
}

.loading-icon, .error-icon, .not-found-icon {
  font-size: 3rem;
  color: var(--p-primary-color);
  margin-bottom: 1rem;
}

.error-icon {
  color: var(--p-red-500);
}

.loading-content h3, .error-content h3 {
  color: var(--p-text-color);
  margin: 0 0 0.5rem 0;
}

.loading-content p, .error-content p {
  color: var(--p-text-muted-color);
  margin-bottom: 1.5rem;
}


.in-progress-notice-card {
  background: linear-gradient(135deg, var(--p-yellow-50) 0%, var(--p-yellow-100) 100%);
  border-left: 4px solid var(--p-yellow-500);
}

.notice-header {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-bottom: 1rem;
}

.notice-icon {
  font-size: 2rem;
  color: var(--p-yellow-600);
}

.notice-content h3 {
  margin: 0;
  color: var(--p-text-color);
}

.notice-content p {
  margin: 0;
  color: var(--p-text-muted-color);
  line-height: 1.5;
}

.stat-icon {
  color: var(--p-primary-color);
}

.empty-icon {
  font-size: 4rem;
  color: var(--p-text-muted-color);
  margin-bottom: 1rem;
}

.bookings-loading {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  padding: 2rem;
  color: var(--p-text-muted-color);
}

.bookings-loading i {
  font-size: 1.5rem;
  color: var(--p-primary-color);
}

/* Modern Booking Card Styles */
.booking-card {
  border: 1px solid var(--p-surface-border);
  border-radius: var(--p-border-radius);
  padding: 0;
  background-color: var(--p-surface-0);
  transition: all 0.2s ease;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  margin-bottom: 1rem;
}

.booking-card:hover {
  box-shadow: var(--p-card-shadow);
  transform: translateY(-2px);
}

.booking-header {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1.25rem;
  border-bottom: 1px solid var(--p-surface-border);
}

.passenger-avatar {
  flex-shrink: 0;
}

.stops-info {
  flex: 1;
  display: flex;
  align-items: center;
  margin-left: 0.5rem;
  min-width: 0;
}

.passenger-info {
  flex: 0 0 auto;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  min-width: 0;
}

.passenger-name {
  font-weight: 600;
  color: var(--p-text-color);
  font-size: 1.1rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.passenger-name .guest-tag {
  font-size: 0.7rem;
  margin-left: 0.25rem;
}

.passenger-name i {
  color: var(--p-primary-color);
  font-size: 0.9rem;
}

.booking-status-container {
  display: flex;
  align-items: center;
}

.booking-status-badge {
  padding: 0.25rem 0.75rem;
  border-radius: var(--p-border-radius);
  font-size: 0.75rem;
  font-weight: 600;
  text-transform: uppercase;
  white-space: nowrap;
  display: flex;
  align-items: center;
  gap: 0.25rem;
}

.booking-status-unconfirmed { 
  background-color: var(--p-yellow-500); 
  color: var(--p-yellow-950); 
}
.booking-status-confirmed { 
  background-color: var(--p-green-500); 
  color: white; 
}
.booking-status-cancelled { 
  background-color: var(--p-red-500); 
  color: white; 
}
.booking-status-checked-in { 
  background-color: var(--p-cyan-500); 
  color: white; 
}
.booking-status-completed { 
  background-color: var(--p-surface-600); 
  color: white; 
}
.booking-status-waiting-list { 
  background-color: var(--p-orange-500); 
  color: white; 
}

.booking-actions {
  display: flex;
  gap: 0.5rem;
  flex-shrink: 0;
}

.booking-details {
  padding: 1.25rem;
}

/* Compact stops layout styles - table-like alignment */
.stops-compact {
  display: flex;
  flex-direction: column;
  gap: 0.375rem;
  width: 100%;
}

.stop-compact {
  display: flex;
  align-items: center;
  gap: 0.375rem;
}

.stop-compact .stop-icon {
  font-size: 0.875rem;
  padding: 0.25rem;
  border-radius: 50%;
  flex-shrink: 0;
  width: 1.5rem;
  height: 1.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
}

.stop-compact .pickup-icon {
  color: var(--p-green-600);
  background-color: var(--p-green-50);
}

.stop-compact .dropoff-icon {
  color: var(--p-orange-600);
  background-color: var(--p-orange-50);
}

.stop-compact .stop-label {
  font-weight: 500;
  color: var(--p-text-color);
  font-size: 0.8rem;
  min-width: 4rem;
  flex-shrink: 0;
}

.stop-compact .stop-name {
  font-weight: 400;
  color: var(--p-text-color);
  font-size: 0.8rem;
  flex: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.stop-compact .not-assigned {
  color: var(--p-text-muted-color);
  font-style: italic;
  font-size: 0.8rem;
  flex: 1;
  min-width: 0;
}

/* Parent Information Styles */
.parents-info {
  display: flex;
  align-items: flex-start;
  gap: 0.375rem;
  margin-top: 0.5rem;
  padding-top: 0.5rem;
  border-top: 1px solid var(--p-surface-border);
}

.parent-icon {
  font-size: 0.875rem;
  padding: 0.25rem;
  border-radius: 50%;
  flex-shrink: 0;
  width: 1.5rem;
  height: 1.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--p-purple-600);
  background-color: var(--p-purple-50);
}

.parent-label {
  font-weight: 500;
  color: var(--p-text-color);
  font-size: 0.8rem;
  min-width: 4rem;
  flex-shrink: 0;
}

.parents-list {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  flex: 1;
  min-width: 0;
}

.parent-contact {
  display: flex;
  flex-direction: column;
  gap: 0.125rem;
}

.parent-name {
  font-weight: 500;
  color: var(--p-text-color);
  font-size: 0.8rem;
}

.parent-phone {
  font-size: 0.75rem;
  color: var(--p-text-muted-color);
  font-family: monospace;
}


.loading-container, .error-container, .not-found-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 400px;
}

.loading {
  font-size: 1.2rem;
  color: #666;
}

.error-message, .not-found-message {
  text-align: center;
  background: white;
  padding: 40px;
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
}

.error-message h3, .not-found-message h2 {
  color: #dc3545;
  margin-bottom: 15px;
}

.retry-button, .back-to-rides-button {
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
  gap: 30px;
  grid-template-areas: 
    "notice notice"
    "info route"
    "bookings bookings"
    "map map";
  grid-template-columns: 1fr 1fr;
}

.notice-section {
  grid-area: notice;
}

.info-section {
  grid-area: info;
}

.route-section {
  grid-area: route;
}

.bookings-section {
  grid-area: bookings;
}

.map-section {
  grid-area: map;
}

.notice {
  background: white;
  border-radius: 8px;
  padding: 20px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  display: flex;
  align-items: flex-start;
  gap: 15px;
}

.in-progress-notice {
  background: linear-gradient(135deg, #fff3cd 0%, #ffeeba 100%);
  border-left: 4px solid #ffc107;
}

.notice-icon {
  font-size: 2rem;
  flex-shrink: 0;
}

.notice-content h3 {
  margin: 0 0 10px 0;
  color: #333;
}

.notice-content p {
  margin: 0;
  color: #666;
  line-height: 1.5;
}

.info-section, .route-section, .bookings-section, .map-section {
  background: white;
  border-radius: 8px;
  padding: 30px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 25px;
  padding-bottom: 15px;
  border-bottom: 2px solid #f8f9fa;
}

.header-controls {
  display: flex;
  align-items: center;
  gap: 15px;
}

.section-header h2 {
  margin: 0;
  color: #333;
  font-size: 1.5rem;
}

.refresh-button {
  background: none;
  border: 1px solid #dee2e6;
  padding: 6px 12px;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.9rem;
  color: #666;
  transition: all 0.2s;
}

.refresh-button:hover {
  background-color: #f8f9fa;
  border-color: #adb5bd;
}

.show-cancelled-toggle {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  font-size: 0.9rem;
  color: #666;
  user-select: none;
}

.toggle-checkbox {
  appearance: none;
  width: 18px;
  height: 18px;
  border: 2px solid #ddd;
  border-radius: 3px;
  position: relative;
  cursor: pointer;
  transition: all 0.2s;
}

.toggle-checkbox:checked {
  background-color: #007bff;
  border-color: #007bff;
}

.toggle-checkbox:checked::after {
  content: '✓';
  position: absolute;
  top: -2px;
  left: 1px;
  color: white;
  font-size: 12px;
  font-weight: bold;
}

.toggle-checkbox:hover {
  border-color: #007bff;
}

.toggle-text {
  cursor: pointer;
}

.info-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 30px;
  margin-bottom: 25px;
}

.info-group h4 {
  margin: 0 0 15px 0;
  color: #495057;
  font-size: 1.1rem;
  border-bottom: 1px solid #e9ecef;
  padding-bottom: 8px;
}

.info-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 0;
  border-bottom: 1px solid #f8f9fa;
}

.info-label {
  font-weight: 500;
  color: #666;
}

.info-value {
  color: #333;
  text-align: right;
}

.line-link-button {
  background: none;
  border: none;
  color: #007bff;
  text-decoration: underline;
  cursor: pointer;
  font-size: inherit;
  padding: 0;
  font-family: inherit;
}

.line-link-button:hover {
  color: #0056b3;
  text-decoration: none;
}

.notes-section {
  margin-top: 25px;
  padding-top: 25px;
  border-top: 1px solid #e9ecef;
}

.notes-section h4 {
  margin: 0 0 15px 0;
  color: #495057;
}

.notes-content {
  background: #f8f9fa;
  padding: 15px;
  border-radius: 4px;
  color: #333;
  line-height: 1.5;
}

.route-stats {
  display: flex;
  gap: 30px;
  margin-bottom: 25px;
  padding: 20px;
  background: #f8f9fa;
  border-radius: 8px;
}

.stat {
  display: flex;
  align-items: center;
  gap: 12px;
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
  font-weight: bold;
  color: #333;
  line-height: 1;
}

.stat-label {
  font-size: 0.9rem;
  color: #666;
  margin-top: 2px;
}

.route-stops h4 {
  margin: 0 0 15px 0;
  color: #495057;
}

.stops-list {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.stop-item {
  display: flex;
  align-items: flex-start;
  gap: 15px;
  padding: 15px;
  background: #f8f9fa;
  border-radius: 8px;
  transition: all 0.2s;
}

.stop-item:hover {
  background: #e9ecef;
}

.stop-number {
  background: #007bff;
  color: white;
  width: 30px;
  height: 30px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: bold;
  font-size: 0.9rem;
  flex-shrink: 0;
}

.stop-info {
  flex: 1;
}

.stop-main {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 5px;
}

.stop-name {
  font-weight: 600;
  color: #333;
  font-size: 1.1rem;
}

.stop-type {
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 0.75rem;
  font-weight: bold;
  text-transform: uppercase;
}

.stop-type.pickup {
  background-color: #d4edda;
  color: #155724;
}

.stop-type.dropoff {
  background-color: #f8d7da;
  color: #721c24;
}

.stop-address {
  color: #666;
  font-size: 0.9rem;
  margin-bottom: 5px;
}

.stop-time {
  display: flex;
  gap: 8px;
  align-items: center;
  font-size: 0.9rem;
}

.time-label {
  color: #666;
  font-weight: 500;
}

.time-value {
  color: #333;
}

.empty-route, .empty-bookings {
  text-align: center;
  padding: 60px 20px;
  color: #666;
}

.empty-icon {
  font-size: 4rem;
  margin-bottom: 20px;
}

.empty-route h3, .empty-bookings h3 {
  color: #666;
  margin-bottom: 10px;
}

.bookings-loading {
  text-align: center;
  padding: 40px;
  color: #666;
}

.bookings-list {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.booking-item {
  border: 1px solid #dee2e6;
  border-radius: 8px;
  padding: 20px;
  transition: all 0.2s;
}

.booking-item:hover {
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.booking-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 15px;
}

.passenger-name {
  font-weight: 600;
  color: #333;
  font-size: 1.1rem;
}

.booking-status-badge {
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 0.75rem;
  font-weight: bold;
  text-transform: uppercase;
}

.booking-status-unconfirmed { background-color: #ffc107; color: #000; }
.booking-status-confirmed { background-color: #28a745; color: white; }
.booking-status-cancelled { background-color: #dc3545; color: white; }
.booking-status-checked-in { background-color: #17a2b8; color: white; }
.booking-status-completed { background-color: #6c757d; color: white; }
.booking-status-waiting-list { background-color: #fd7e14; color: white; }

.booking-details {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.booking-info {
  flex: 1;
}

.stop-info {
  margin-bottom: 5px;
  color: #666;
}

.booking-actions {
  display: flex;
  gap: 10px;
}

.booking-action-btn {
  padding: 6px 12px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.8rem;
  transition: all 0.2s;
}

.checkin-btn {
  background-color: #17a2b8;
  color: white;
}

.checkin-btn:hover {
  background-color: #138496;
}

.dropoff-btn {
  background-color: #28a745;
  color: white;
}

.dropoff-btn:hover {
  background-color: #218838;
}

.confirm-btn {
  background-color: #007bff;
  color: white;
}

.confirm-btn:hover {
  background-color: #0056b3;
}

.cancel-btn {
  background-color: #dc3545;
  color: white;
}

.cancel-btn:hover {
  background-color: #c82333;
}

.admit-btn {
  background-color: #fd7e14;
  color: white;
}

.admit-btn:hover {
  background-color: #e8690b;
}

@media (max-width: 768px) {
  .content-grid {
    grid-template-areas: 
      "notice"
      "info"
      "route"
      "bookings"
      "map";
    grid-template-columns: 1fr;
  }
  
  .info-grid {
    grid-template-columns: 1fr;
    gap: 20px;
  }
  
  .route-stats {
    flex-direction: column;
    gap: 20px;
  }
  
  .header-content {
    flex-direction: column;
    gap: 15px;
    text-align: center;
  }
  
  .header-actions {
    justify-content: center;
  }
}

/* Modal Styles */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.modal-content {
  background: white;
  border-radius: 8px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
  max-width: 500px;
  width: 90%;
  max-height: 90vh;
  overflow-y: auto;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 20px 0 20px;
  border-bottom: 1px solid #e9ecef;
  margin-bottom: 20px;
}

.modal-header h3 {
  margin: 0;
  color: #333;
}

.close-button {
  background: none;
  border: none;
  font-size: 24px;
  cursor: pointer;
  color: #999;
  padding: 0;
  width: 30px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.close-button:hover {
  color: #666;
}

.modal-body {
  padding: 0 20px 20px 20px;
}

.loading-text {
  text-align: center;
  padding: 40px;
  color: #666;
}

.booking-form {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.form-group label {
  font-weight: 500;
  color: #333;
}

.form-control {
  padding: 10px 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
  transition: border-color 0.2s;
}

.form-control:focus {
  outline: none;
  border-color: #007bff;
  box-shadow: 0 0 0 2px rgba(0, 123, 255, 0.25);
}

.form-actions {
  display: flex;
  gap: 10px;
  justify-content: flex-end;
  margin-top: 10px;
}

.cancel-button {
  background-color: #6c757d;
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 4px;
  cursor: pointer;
  transition: background-color 0.2s;
}

.cancel-button:hover {
  background-color: #545b62;
}

.submit-button {
  background-color: #007bff;
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 4px;
  cursor: pointer;
  transition: background-color 0.2s;
}

.submit-button:hover:not(:disabled) {
  background-color: #0056b3;
}

.submit-button:disabled {
  background-color: #ccc;
  cursor: not-allowed;
}

@media (max-width: 768px) {
  .modal-content {
    width: 95%;
    margin: 20px;
  }
  
  .form-actions {
    flex-direction: column;
  }
  
  .cancel-button,
  .submit-button {
    width: 100%;
  }
}

/* Live Tracking Modal Styles */
.live-tracking-modal {
  max-width: 1200px;
  width: 95%;
  max-height: 90vh;
}

.live-tracking-modal .modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  border-bottom: 2px solid #f8f9fa;
  background: linear-gradient(135deg, #007bff 0%, #0056b3 100%);
  color: white;
  border-radius: 8px 8px 0 0;
}

.live-tracking-modal .modal-header h3 {
  color: white;
  margin: 0;
}

.tracking-status {
  display: flex;
  align-items: center;
  gap: 10px;
}

.status-indicator {
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 0.8rem;
  font-weight: bold;
  display: flex;
  align-items: center;
  gap: 5px;
}

.status-indicator.active {
  background-color: rgba(40, 167, 69, 0.9);
  color: white;
  animation: pulse 2s infinite;
}

.status-indicator.inactive {
  background-color: rgba(220, 53, 69, 0.9);
  color: white;
}

@keyframes pulse {
  0% { opacity: 1; }
  50% { opacity: 0.7; }
  100% { opacity: 1; }
}

.live-tracking-modal .close-button {
  color: rgba(255, 255, 255, 0.8);
  background: rgba(255, 255, 255, 0.1);
  border-radius: 50%;
  width: 35px;
  height: 35px;
}

.live-tracking-modal .close-button:hover {
  color: white;
  background: rgba(255, 255, 255, 0.2);
}

.tracking-body {
  padding: 0;
  max-height: calc(90vh - 100px);
  overflow-y: auto;
}

.tracking-container {
  display: flex;
  flex-direction: column;
  height: 100%;
}

.tracking-info {
  display: flex;
  justify-content: space-around;
  padding: 20px;
  background: #f8f9fa;
  border-bottom: 1px solid #dee2e6;
  gap: 20px;
  flex-wrap: wrap;
}

.tracking-info .info-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 5px;
}

.tracking-info .info-label {
  font-size: 0.9rem;
  color: #666;
  font-weight: 500;
}

.tracking-info .info-value {
  font-size: 1.1rem;
  color: #333;
  font-weight: bold;
}

.map-container {
  flex: 1;
  min-height: 500px;
  position: relative;
}

.error-text {
  text-align: center;
  padding: 40px 20px;
  color: #dc3545;
}

.error-text p {
  margin-bottom: 15px;
  font-size: 1.1rem;
}

.retry-button {
  background-color: #007bff;
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 4px;
  cursor: pointer;
  font-size: 1rem;
  transition: background-color 0.2s;
}

.retry-button:hover {
  background-color: #0056b3;
}

@media (max-width: 768px) {
  .live-tracking-modal {
    width: 98%;
    max-height: 95vh;
  }
  
  .live-tracking-modal .modal-header {
    flex-direction: column;
    gap: 10px;
    text-align: center;
  }
  
  .tracking-info {
    flex-direction: column;
    gap: 15px;
  }
  
  .map-container {
    min-height: 400px;
  }
}
</style>