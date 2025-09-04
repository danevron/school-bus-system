<template>
  <div class="ride-view-container">
    <header class="header">
      <div class="header-content">
        <div class="header-info">
          <h1 v-if="ride">{{ ride.route?.name || 'Ride Details' }}</h1>
          <h1 v-else>Ride Details</h1>
          <div class="status-badge" v-if="ride" :class="getStatusClass(ride.status)">
            {{ getStatusLabel(ride.status) }}
          </div>
        </div>
        <div class="header-actions">
          <button @click="goBack" class="back-button">← Back to Rides</button>
          <button 
            v-if="canBookRide" 
            @click="openBookingModal" 
            class="action-button book-button"
          >
            Book Ride
          </button>
          <button 
            v-if="ride && ride.status === 'scheduled'" 
            @click="startRide" 
            class="action-button start-button"
          >
            Start Ride
          </button>
          <button 
            v-if="ride && ride.status === 'in_progress'" 
            @click="endRide" 
            class="action-button end-button"
          >
            End Ride
          </button>
        </div>
      </div>
    </header>

    <main class="main-content">
      <div v-if="loading" class="loading-container">
        <div class="loading">Loading ride details...</div>
      </div>

      <div v-else-if="error" class="error-container">
        <div class="error-message">
          <h3>Error Loading Ride</h3>
          <p>{{ error }}</p>
          <button @click="fetchRide" class="retry-button">Try Again</button>
        </div>
      </div>

      <!-- Success Message -->
      <div v-if="successMessage" class="success-message-container">
        <div class="success-message">
          <div class="success-icon">✓</div>
          <span>{{ successMessage }}</span>
        </div>
      </div>

      <div v-else-if="ride" class="content-grid">
        <!-- Status Notice Section -->
        <div v-if="ride.status === 'in_progress'" class="notice-section">
          <div class="notice in-progress-notice">
            <div class="notice-icon">🚌</div>
            <div class="notice-content">
              <h3>Ride In Progress</h3>
              <p>
                This ride is currently <strong>in progress</strong>. 
                The driver has started the route and may be picking up or dropping off passengers.
              </p>
            </div>
          </div>
        </div>

        <!-- Basic Information Section -->
        <div class="info-section">
          <div class="section-header">
            <h2>Ride Information</h2>
          </div>
          <div class="info-grid">
            <div class="info-group">
              <h4>Basic Details</h4>
              <div class="info-item">
                <span class="info-label">Date:</span>
                <span class="info-value">{{ formatDate(ride.date) }}</span>
              </div>
              <div class="info-item">
                <span class="info-label">Scheduled Start:</span>
                <span class="info-value">{{ formatTime(ride.startTime) }}</span>
              </div>
              <div v-if="ride.actualStartTime" class="info-item">
                <span class="info-label">Actual Start:</span>
                <span class="info-value">{{ formatTime(ride.actualStartTime) }}</span>
              </div>
              <div v-if="ride.actualEndTime" class="info-item">
                <span class="info-label">Actual End:</span>
                <span class="info-value">{{ formatTime(ride.actualEndTime) }}</span>
              </div>
              <div class="info-item">
                <span class="info-label">Status:</span>
                <span class="info-value">
                  <span class="status-badge" :class="getStatusClass(ride.status)">
                    {{ getStatusLabel(ride.status) }}
                  </span>
                </span>
              </div>
            </div>

            <div class="info-group">
              <h4>Assignment</h4>
              <div class="info-item">
                <span class="info-label">Driver:</span>
                <span class="info-value">{{ getDriverName(ride.driver) }}</span>
              </div>
              <div class="info-item">
                <span class="info-label">Vehicle:</span>
                <span class="info-value">{{ getVehicleName(ride.vehicle) }}</span>
              </div>
              <div v-if="ride.lineId" class="info-item">
                <span class="info-label">Line:</span>
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
              <h4>Capacity</h4>
              <div class="info-item">
                <span class="info-label">Max Capacity:</span>
                <span class="info-value">{{ ride.maxCapacity }} seats</span>
              </div>
              <div class="info-item">
                <span class="info-label">Available Seats:</span>
                <span class="info-value">{{ ride.availableSeats }} seats</span>
              </div>
              <div class="info-item">
                <span class="info-label">Booked Seats:</span>
                <span class="info-value">{{ ride.maxCapacity - ride.availableSeats }} seats</span>
              </div>
              <div class="info-item">
                <span class="info-label">Waiting List:</span>
                <span class="info-value">{{ waitingListCount }} seats</span>
              </div>
            </div>
          </div>

          <div v-if="ride.notes" class="notes-section">
            <h4>Notes</h4>
            <div class="notes-content">{{ ride.notes }}</div>
          </div>
        </div>

        <!-- Route Section -->
        <div class="route-section">
          <div class="section-header">
            <h2>Route Details</h2>
          </div>
          <div v-if="ride.route && ride.route.stops && ride.route.stops.length > 0" class="route-content">
            <div class="route-stats">
              <div class="stat">
                <span class="stat-icon">📍</span>
                <div class="stat-info">
                  <span class="stat-value">{{ ride.route.stops.length }}</span>
                  <span class="stat-label">Stops</span>
                </div>
              </div>
              <div class="stat">
                <span class="stat-icon">📏</span>
                <div class="stat-info">
                  <span class="stat-value">{{ ride.route.totalDistance || 0 }}km</span>
                  <span class="stat-label">Distance</span>
                </div>
              </div>
              <div class="stat">
                <span class="stat-icon">⏱️</span>
                <div class="stat-info">
                  <span class="stat-value">{{ ride.route.estimatedDuration || 0 }}min</span>
                  <span class="stat-label">Duration</span>
                </div>
              </div>
            </div>
            <div class="route-stops">
              <h4>Route Stops</h4>
              <div class="stops-list">
                <div v-for="(stop, index) in ride.route.stops" :key="index" class="stop-item">
                  <span class="stop-number">{{ index + 1 }}</span>
                  <div class="stop-info">
                    <div class="stop-main">
                      <span class="stop-name">{{ stop.name }}</span>
                      <span class="stop-type" :class="stop.type">{{ stop.type }}</span>
                    </div>
                    <div class="stop-address">{{ stop.address }}</div>
                    <div v-if="stop.estimatedArrivalTime" class="stop-time">
                      <span class="time-label">Estimated:</span>
                      <span class="time-value">{{ formatTime(stop.estimatedArrivalTime) }}</span>
                    </div>
                    <div v-if="stop.actualArrivalTime" class="stop-time">
                      <span class="time-label">Actual:</span>
                      <span class="time-value">{{ formatTime(stop.actualArrivalTime) }}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div v-else class="empty-route">
            <div class="empty-icon">🗺️</div>
            <h3>No Route Defined</h3>
            <p>This ride doesn't have a route with stops defined yet.</p>
          </div>
        </div>

        <!-- Bookings Section -->
        <div class="bookings-section">
          <div class="section-header">
            <h2>Passenger Bookings</h2>
            <div class="header-controls">
              <label class="show-cancelled-toggle">
                <input 
                  type="checkbox" 
                  v-model="showCancelled"
                  class="toggle-checkbox"
                />
                <span class="toggle-text">Show Cancelled</span>
              </label>
              <button @click="loadBookings" class="refresh-button">🔄 Refresh</button>
            </div>
          </div>
          
          <div v-if="bookingsLoading" class="bookings-loading">
            Loading bookings...
          </div>
          
          <div v-else-if="filteredBookings.length === 0" class="empty-bookings">
            <div class="empty-icon">📋</div>
            <h3>No Bookings</h3>
            <p v-if="!showCancelled && bookings.length > 0">All bookings are cancelled. Toggle "Show Cancelled" to view them.</p>
            <p v-else>No passengers have booked this ride yet.</p>
          </div>
          
          <div v-else class="bookings-list">
            <div v-for="booking in filteredBookings" :key="booking._id" class="booking-item">
              <div class="booking-header">
                <span class="passenger-name">{{ getPassengerName(booking.passenger) }}</span>
                <span class="booking-status-badge" :class="getBookingStatusClass(booking.status)">
                  {{ getBookingStatusLabel(booking.status) }}
                </span>
              </div>
              <div class="booking-details">
                <div class="booking-info">
                  <div class="stop-info">
                    <strong>Pickup:</strong> {{ booking.pickupStop.name }}
                  </div>
                  <div v-if="booking.dropoffStop" class="stop-info">
                    <strong>Dropoff:</strong> {{ booking.dropoffStop.name }}
                  </div>
                </div>
                <div class="booking-actions">
                  <!-- Admit/Cancel buttons for waiting list bookings -->
                  <template v-if="booking.status === 'waiting_list'">
                    <button 
                      @click="admitWaitingListBooking(booking._id)"
                      class="booking-action-btn admit-btn"
                    >
                      Admit
                    </button>
                    <button 
                      @click="cancelBooking(booking._id)"
                      class="booking-action-btn cancel-btn"
                    >
                      Cancel
                    </button>
                  </template>

                  <!-- Confirm/Cancel buttons for unconfirmed bookings -->
                  <template v-if="booking.status === 'unconfirmed'">
                    <button 
                      @click="confirmBooking(booking._id)"
                      class="booking-action-btn confirm-btn"
                    >
                      Confirm
                    </button>
                    <button 
                      @click="cancelBooking(booking._id)"
                      class="booking-action-btn cancel-btn"
                    >
                      Cancel
                    </button>
                  </template>

                  <!-- Cancel button for confirmed bookings (that haven't started yet) -->
                  <template v-if="booking.status === 'confirmed' && ride.status === 'scheduled'">
                    <button 
                      @click="cancelBooking(booking._id)"
                      class="booking-action-btn cancel-btn"
                    >
                      Cancel
                    </button>
                  </template>

                  <!-- Check In button for confirmed bookings during ride -->
                  <template v-if="booking.status === 'confirmed' && ride.status === 'in_progress'">
                    <button 
                      @click="checkInPassenger(booking._id)"
                      class="booking-action-btn checkin-btn"
                    >
                      Check In
                    </button>
                  </template>

                  <!-- Drop Off button for checked-in passengers -->
                  <template v-if="booking.status === 'checked_in' && ride.status === 'in_progress'">
                    <button 
                      @click="dropOffPassenger(booking._id)"
                      class="booking-action-btn dropoff-btn"
                    >
                      Drop Off
                    </button>
                  </template>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Route Map Section -->
        <div v-if="ride.route && ride.route.stops && ride.route.stops.length > 0" class="map-section">
          <RouteMap
            :stops="ride.route.stops"
            :studentAssignments="[]"
            :showDrivingInstructions="false"
            :showDrivingRoute="true"
            mapHeight="600px"
            mapId="ride-route-map"
          />
        </div>
      </div>
      
      <div v-else class="not-found-container">
        <div class="not-found-message">
          <h2>Ride Not Found</h2>
          <p>The ride you're looking for doesn't exist or may have been deleted.</p>
          <button @click="goBack" class="back-to-rides-button">← Back to Rides</button>
        </div>
      </div>
    </main>

    <!-- Booking Modal -->
    <div v-if="showBookingModal" class="modal-overlay" @click="closeBookingModal">
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <h3>Book Ride</h3>
          <button @click="closeBookingModal" class="close-button">×</button>
        </div>
        
        <div class="modal-body">
          <div v-if="bookingFormLoading" class="loading-text">
            Loading users and stops...
          </div>
          
          <form v-else @submit.prevent="submitBooking" class="booking-form">
            <!-- Passenger Selection -->
            <div class="form-group">
              <label for="passenger">Select Passenger:</label>
              <select 
                id="passenger" 
                v-model="bookingForm.passengerId" 
                required 
                class="form-control"
              >
                <option value="">Choose a passenger...</option>
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
              <label for="pickupStop">Pickup Stop:</label>
              <select 
                id="pickupStop" 
                v-model="bookingForm.pickupStopId" 
                required 
                class="form-control"
              >
                <option value="">Choose pickup stop...</option>
                <option 
                  v-for="stop in pickupStops" 
                  :key="stop.stopId" 
                  :value="stop.stopId"
                >
                  {{ stop.name }} - {{ stop.address }}
                </option>
              </select>
            </div>

            <!-- Dropoff Stop Selection (Optional) -->
            <div class="form-group">
              <label for="dropoffStop">Dropoff Stop (Optional):</label>
              <select 
                id="dropoffStop" 
                v-model="bookingForm.dropoffStopId" 
                class="form-control"
              >
                <option value="">Choose dropoff stop (optional)...</option>
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
              <label for="notes">Notes (Optional):</label>
              <textarea 
                id="notes" 
                v-model="bookingForm.notes" 
                class="form-control"
                rows="3"
                placeholder="Any special requirements or notes..."
              ></textarea>
            </div>

            <!-- Form Actions -->
            <div class="form-actions">
              <button 
                type="button" 
                @click="closeBookingModal" 
                class="cancel-button"
              >
                Cancel
              </button>
              <button 
                type="submit" 
                :disabled="bookingSubmitting || !isBookingFormValid"
                class="submit-button"
              >
                {{ bookingSubmitting ? 'Creating...' : 'Create Booking' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, onMounted, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import apiService from '../services/api.js'
import RouteMap from '../components/RouteMap.vue'

export default {
  name: 'RideView',
  components: {
    RouteMap
  },
  setup() {
    const router = useRouter()
    const route = useRoute()
    const rideId = route.params.id

    const ride = ref(null)
    const bookings = ref([])
    const loading = ref(true)
    const bookingsLoading = ref(false)
    const error = ref('')
    const successMessage = ref('')
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
      return bookingForm.value.passengerId && bookingForm.value.pickupStopId
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

    const showSuccessMessage = (message) => {
      successMessage.value = message
      setTimeout(() => {
        successMessage.value = ''
      }, 3000) // Hide after 3 seconds
    }

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
      if (!dateString) return 'Not set'
      return new Date(dateString).toLocaleDateString()
    }

    const formatTime = (timeString) => {
      if (!timeString) return 'Not set'
      return new Date(timeString).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    }

    const getStatusClass = (status) => {
      return `status-${status?.toLowerCase().replace('_', '-')}`
    }

    const getStatusLabel = (status) => {
      const labels = {
        'scheduled': 'Scheduled',
        'in_progress': 'In Progress',
        'completed': 'Completed',
        'cancelled': 'Cancelled'
      }
      return labels[status] || status
    }

    const getBookingStatusClass = (status) => {
      return `booking-status-${status?.toLowerCase().replace('_', '-')}`
    }

    const getBookingStatusLabel = (status) => {
      const labels = {
        'unconfirmed': 'Unconfirmed',
        'confirmed': 'Confirmed',
        'cancelled': 'Cancelled',
        'checked_in': 'Checked In',
        'completed': 'Completed',
        'waiting_list': 'Waiting List'
      }
      return labels[status] || status
    }

    const getDriverName = (driver) => {
      if (typeof driver === 'object' && driver) {
        return `${driver.firstName} ${driver.lastName}`
      }
      return 'Loading...'
    }

    const getVehicleName = (vehicle) => {
      if (typeof vehicle === 'object' && vehicle) {
        return `${vehicle.make} ${vehicle.vehicleModel} (${vehicle.licensePlate})`
      }
      return 'Loading...'
    }

    const getPassengerName = (passenger) => {
      if (typeof passenger === 'object' && passenger) {
        return `${passenger.firstName} ${passenger.lastName}`
      }
      return 'Loading...'
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
        alert('Error starting ride: ' + (err.response?.data?.message || err.message))
      }
    }

    const endRide = async () => {
      try {
        await apiService.post(`/rides/${rideId}/end`)
        await fetchRide() // Reload ride data
      } catch (err) {
        alert('Error ending ride: ' + (err.response?.data?.message || err.message))
      }
    }

    const checkInPassenger = async (bookingId) => {
      try {
        await apiService.post(`/bookings/${bookingId}/checkin`)
        await loadBookings() // Reload bookings
      } catch (err) {
        alert('Error checking in passenger: ' + (err.response?.data?.message || err.message))
      }
    }

    const dropOffPassenger = async (bookingId) => {
      try {
        await apiService.post(`/bookings/${bookingId}/dropoff`)
        await loadBookings() // Reload bookings
      } catch (err) {
        alert('Error dropping off passenger: ' + (err.response?.data?.message || err.message))
      }
    }

    const confirmBooking = async (bookingId) => {
      try {
        await apiService.post(`/bookings/${bookingId}/confirm`)
        await loadBookings() // Reload bookings
        await fetchRide() // Reload ride to update available seats
        showSuccessMessage('Booking confirmed successfully!')
      } catch (err) {
        alert('Error confirming booking: ' + (err.response?.data?.message || err.message))
      }
    }

    const cancelBooking = async (bookingId) => {
      try {
        await apiService.post(`/bookings/${bookingId}/cancel`, {})
        await loadBookings() // Reload bookings
        await fetchRide() // Reload ride to update available seats
        showSuccessMessage('Booking cancelled successfully!')
      } catch (err) {
        alert('Error cancelling booking: ' + (err.response?.data?.message || err.message))
      }
    }

    const admitWaitingListBooking = async (bookingId) => {
      try {
        await apiService.post(`/bookings/${bookingId}/admit`)
        await loadBookings() // Reload bookings
        await fetchRide() // Reload ride to update available seats
        showSuccessMessage('Waiting list booking admitted successfully!')
      } catch (err) {
        alert('Error admitting waiting list booking: ' + (err.response?.data?.message || err.message))
      }
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
          dropoffStop: selectedDropoffStop ? {
            stopId: selectedDropoffStop.stopId,
            name: selectedDropoffStop.name,
            address: selectedDropoffStop.address
          } : undefined,
          notes: bookingForm.value.notes || undefined
        }

        await apiService.post('/bookings', bookingData)
        
        // Close modal and reload data
        closeBookingModal()
        await fetchRide() // Reload ride to update available seats
        await loadBookings() // Reload bookings to show new booking
        
        // Check if booking went to waiting list by checking available seats
        if (ride.value.availableSeats <= 0) {
          showSuccessMessage('Booking added to waiting list - no available seats currently!')
        } else {
          showSuccessMessage('Booking created successfully!')
        }
        
      } catch (err) {
        console.error('Error creating booking:', err)
        alert('Error creating booking: ' + (err.response?.data?.message || err.message))
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

    return {
      ride,
      bookings,
      loading,
      bookingsLoading,
      error,
      successMessage,
      showCancelled,
      filteredBookings,
      fetchRide,
      loadBookings,
      formatDate,
      formatTime,
      getStatusClass,
      getStatusLabel,
      getBookingStatusClass,
      getBookingStatusLabel,
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
      submitBooking
    }
  }
}
</script>

<style scoped>
.ride-view-container {
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
  gap: 20px;
}

.header h1 {
  margin: 0;
  font-size: 1.8rem;
}

.header-actions {
  display: flex;
  gap: 15px;
}

.back-button, .action-button {
  background-color: rgba(255, 255, 255, 0.2);
  color: white;
  border: 1px solid rgba(255, 255, 255, 0.3);
  padding: 8px 16px;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.2s;
}

.back-button:hover, .action-button:hover {
  background-color: rgba(255, 255, 255, 0.3);
}

.start-button {
  background-color: #28a745;
  border-color: #28a745;
}

.start-button:hover {
  background-color: #218838;
}

.end-button {
  background-color: #17a2b8;
  border-color: #17a2b8;
}

.end-button:hover {
  background-color: #138496;
}

.book-button {
  background-color: #6f42c1;
  border-color: #6f42c1;
}

.book-button:hover {
  background-color: #5a36a0;
}

.status-badge {
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 0.75rem;
  font-weight: bold;
  text-transform: uppercase;
  white-space: nowrap;
}

.status-scheduled { background-color: #17a2b8; color: white; }
.status-in-progress { background-color: #ffc107; color: #000; }
.status-completed { background-color: #28a745; color: white; }
.status-cancelled { background-color: #dc3545; color: white; }

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

.success-message-container {
  position: fixed;
  top: 20px;
  right: 20px;
  z-index: 1001;
  animation: slideInRight 0.3s ease-out;
}

.success-message {
  background: linear-gradient(135deg, #28a745 0%, #20c997 100%);
  color: white;
  padding: 15px 20px;
  border-radius: 8px;
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
</style>