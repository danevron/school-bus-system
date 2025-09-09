<template>
  <div class="ride-list-container">
    <header class="header">
      <div class="header-content">
        <h1>Ride Management</h1>
        <div class="header-actions">
          <button @click="goBack" class="back-button">← Back to Dashboard</button>
          <button @click="handleAddRide" class="add-ride-button">+ Add New Ride</button>
        </div>
      </div>
    </header>

    <main class="main-content">
      <div class="content-wrapper">
        <!-- Filter Section -->
        <div class="filters-section">
          <div class="filter-group">
            <label for="status-filter">Status:</label>
            <select id="status-filter" v-model="selectedStatus" @change="filterRides">
              <option value="">All Statuses</option>
              <option value="scheduled">Scheduled</option>
              <option value="in_progress">In Progress</option>
              <option value="completed">Completed</option>
              <option value="cancelled">Cancelled</option>
            </select>
          </div>
          <div class="filter-group">
            <label for="date-filter">Date:</label>
            <input 
              type="date" 
              id="date-filter" 
              v-model="selectedDate" 
              @change="filterRides"
            />
          </div>
          <button @click="clearFilters" class="clear-filters-button">Clear Filters</button>
        </div>

        <!-- Rides List Section -->
        <div class="rides-section">
          <div v-if="loading" class="loading">Loading rides...</div>
          
          <div v-else-if="error" class="error">
            <h3>Error loading rides</h3>
            <p>{{ error }}</p>
            <button @click="loadRides" class="retry-button">Retry</button>
          </div>
          
          <div v-else-if="filteredRides.length === 0" class="no-rides">
            <div class="empty-state">
              <h3>No rides found</h3>
              <p v-if="hasActiveFilters">Try adjusting your filters or create a new ride.</p>
              <p v-else>Start by creating your first ride.</p>
              <button @click="handleAddRide" class="add-ride-button-large">
                + Create First Ride
              </button>
            </div>
          </div>

          <div v-else class="rides-table-container">
            <table class="rides-table">
              <thead>
                <tr>
                  <th>Route</th>
                  <th>Date</th>
                  <th>Start Time</th>
                  <th>Driver</th>
                  <th>Vehicle</th>
                  <th>Seats</th>
                  <th>Status</th>
                  <th>Line</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr 
                  v-for="ride in filteredRides" 
                  :key="ride._id" 
                  class="ride-row"
                  @click="viewRide(ride._id)"
                >
                  <td class="route-cell">
                    <strong>{{ ride.route?.name || 'Unnamed Route' }}</strong>
                    <div class="route-stops">{{ ride.route?.stops?.length || 0 }} stops</div>
                  </td>
                  <td>{{ formatDate(ride.date) }}</td>
                  <td>{{ formatTime(ride.startTime) }}</td>
                  <td>{{ getDriverName(ride.driver) }}</td>
                  <td class="vehicle-cell">
                    <div>{{ getVehicleName(ride.vehicle) }}</div>
                  </td>
                  <td class="seats-cell">
                    <span class="seats-info">{{ ride.availableSeats }}/{{ ride.maxCapacity }}</span>
                  </td>
                  <td>
                    <span class="status-badge" :class="getStatusClass(ride.status)">
                      {{ getStatusLabel(ride.status) }}
                    </span>
                  </td>
                  <td>
                    <button 
                      v-if="ride.lineId"
                      @click.stop="viewLine(ride.lineId._id)"
                      class="line-link-button"
                      :title="`View line: ${ride.lineId.name}`"
                    >
                      {{ ride.lineId.name }}
                    </button>
                    <span v-else class="no-line">-</span>
                  </td>
                  <td class="actions-cell" @click.stop>
                    <div class="action-buttons">
                      <button 
                        v-if="ride.status === 'scheduled'" 
                        @click="startRide(ride._id)"
                        class="action-button start-button"
                        title="Start Ride"
                      >
                        Start
                      </button>
                      <button 
                        v-if="ride.status === 'in_progress'" 
                        @click="endRide(ride._id)"
                        class="action-button end-button"
                        title="End Ride"
                      >
                        End
                      </button>
                      <button 
                        v-if="['scheduled', 'in_progress'].includes(ride.status)" 
                        @click="cancelRide(ride._id)"
                        class="action-button cancel-button"
                        title="Cancel Ride"
                      >
                        Cancel
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<script>
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import apiService from '../services/api.js'

export default {
  name: 'RideList',
  setup() {
    const router = useRouter()
    const rides = ref([])
    const loading = ref(true)
    const error = ref('')
    const selectedStatus = ref('')
    const selectedDate = ref('')

    const filteredRides = computed(() => {
      let filtered = [...rides.value]
      
      if (selectedStatus.value) {
        filtered = filtered.filter(ride => ride.status === selectedStatus.value)
      }
      
      if (selectedDate.value) {
        filtered = filtered.filter(ride => {
          const rideDate = new Date(ride.date).toISOString().split('T')[0]
          return rideDate === selectedDate.value
        })
      }
      
      // Sort by date (newest first)
      return filtered.sort((a, b) => new Date(b.date) - new Date(a.date))
    })

    const hasActiveFilters = computed(() => {
      return selectedStatus.value || selectedDate.value
    })

    const loadRides = async () => {
      try {
        loading.value = true
        error.value = ''
        const response = await apiService.get('/rides')
        rides.value = response.data.rides || []
      } catch (err) {
        console.error('Error loading rides:', err)
        error.value = err.response?.data?.message || 'Failed to load rides'
      } finally {
        loading.value = false
      }
    }

    const filterRides = () => {
      // Filtering is handled by computed property
    }

    const clearFilters = () => {
      selectedStatus.value = ''
      selectedDate.value = ''
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

    const goBack = () => {
      router.push('/home')
    }

    const handleAddRide = () => {
      // TODO: Navigate to ride creation page when implemented
      alert('Ride creation page not yet implemented')
    }

    const viewRide = (rideId) => {
      router.push(`/rides/${rideId}`)
    }

    const startRide = async (rideId) => {
      try {
        await apiService.post(`/rides/${rideId}/start`)
        await loadRides() // Reload data
      } catch (err) {
        alert('Error starting ride: ' + (err.response?.data?.message || err.message))
      }
    }

    const endRide = async (rideId) => {
      try {
        await apiService.post(`/rides/${rideId}/end`)
        await loadRides() // Reload data
      } catch (err) {
        alert('Error ending ride: ' + (err.response?.data?.message || err.message))
      }
    }

    const cancelRide = async (rideId) => {
      if (!confirm('Are you sure you want to cancel this ride?')) return
      
      try {
        await apiService.delete(`/rides/${rideId}`)
        await loadRides() // Reload data
      } catch (err) {
        alert('Error cancelling ride: ' + (err.response?.data?.message || err.message))
      }
    }


    const viewLine = (lineId) => {
      router.push(`/lines/${lineId}`)
    }

    onMounted(() => {
      loadRides()
    })

    return {
      rides,
      loading,
      error,
      selectedStatus,
      selectedDate,
      filteredRides,
      hasActiveFilters,
      loadRides,
      filterRides,
      clearFilters,
      formatDate,
      formatTime,
      getStatusClass,
      getStatusLabel,
      getDriverName,
      getVehicleName,
      goBack,
      handleAddRide,
      viewRide,
      startRide,
      endRide,
      cancelRide,
      viewLine
    }
  }
}
</script>

<style scoped>
.ride-list-container {
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

.header h1 {
  margin: 0;
  font-size: 1.8rem;
}

.header-actions {
  display: flex;
  gap: 15px;
}

.back-button, .add-ride-button {
  background-color: rgba(255, 255, 255, 0.2);
  color: white;
  border: 1px solid rgba(255, 255, 255, 0.3);
  padding: 8px 16px;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.2s;
}

.back-button:hover, .add-ride-button:hover {
  background-color: rgba(255, 255, 255, 0.3);
}

.add-ride-button {
  background-color: #28a745;
  border-color: #28a745;
}

.add-ride-button:hover {
  background-color: #218838;
}

.main-content {
  max-width: 1200px;
  margin: 0 auto;
  padding: 30px 20px;
}

.filters-section {
  background: white;
  border-radius: 8px;
  padding: 20px;
  margin-bottom: 20px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  display: flex;
  gap: 20px;
  align-items: end;
}

.filter-group {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.filter-group label {
  font-weight: 500;
  color: #333;
}

.filter-group select,
.filter-group input {
  padding: 8px 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
}

.clear-filters-button {
  background-color: #6c757d;
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: 4px;
  cursor: pointer;
  transition: background-color 0.2s;
}

.clear-filters-button:hover {
  background-color: #545b62;
}

.rides-section {
  background: white;
  border-radius: 8px;
  padding: 30px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.loading, .error {
  text-align: center;
  padding: 40px;
}

.error {
  color: #dc3545;
}

.retry-button {
  background-color: #007bff;
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: 4px;
  cursor: pointer;
  margin-top: 10px;
}

.no-rides {
  text-align: center;
  padding: 60px 20px;
}

.empty-state h3 {
  color: #666;
  margin-bottom: 10px;
}

.empty-state p {
  color: #999;
  margin-bottom: 20px;
}

.add-ride-button-large {
  background-color: #28a745;
  color: white;
  border: none;
  padding: 12px 24px;
  border-radius: 4px;
  cursor: pointer;
  font-size: 16px;
  transition: background-color 0.2s;
}

.add-ride-button-large:hover {
  background-color: #218838;
}

.rides-table-container {
  overflow-x: auto;
}

.rides-table {
  width: 100%;
  border-collapse: collapse;
  background: white;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
}

.rides-table th {
  background-color: #f8f9fa;
  padding: 16px 12px;
  text-align: left;
  font-weight: 600;
  color: #495057;
  border-bottom: 2px solid #dee2e6;
  white-space: nowrap;
}

.rides-table td {
  padding: 16px 12px;
  border-bottom: 1px solid #dee2e6;
  vertical-align: top;
}

.ride-row {
  cursor: pointer;
  transition: background-color 0.2s;
}

.ride-row:hover {
  background-color: #f8f9fa;
}

.route-cell {
  min-width: 180px;
}

.route-cell strong {
  display: block;
  margin-bottom: 4px;
  color: #333;
}

.route-stops {
  font-size: 0.875rem;
  color: #6c757d;
}

.vehicle-cell {
  min-width: 200px;
  font-size: 0.875rem;
}

.seats-cell {
  text-align: center;
}

.seats-info {
  font-weight: 500;
  color: #495057;
}

.status-badge {
  padding: 4px 8px;
  border-radius: 12px;
  font-size: 0.75rem;
  font-weight: 600;
  text-transform: uppercase;
  white-space: nowrap;
  display: inline-block;
}

.status-scheduled { background-color: #17a2b8; color: white; }
.status-in-progress { background-color: #ffc107; color: #000; }
.status-completed { background-color: #28a745; color: white; }
.status-cancelled { background-color: #dc3545; color: white; }

.no-line {
  color: #6c757d;
  font-style: italic;
}

.actions-cell {
  min-width: 120px;
}

.action-buttons {
  display: flex;
  gap: 4px;
  flex-wrap: wrap;
}

.action-button {
  padding: 6px 12px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.8rem;
  transition: all 0.2s;
}

.start-button {
  background-color: #28a745;
  color: white;
}

.start-button:hover {
  background-color: #218838;
}

.end-button {
  background-color: #17a2b8;
  color: white;
}

.end-button:hover {
  background-color: #138496;
}

.cancel-button {
  background-color: #dc3545;
  color: white;
}

.cancel-button:hover {
  background-color: #c82333;
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

@media (max-width: 768px) {
  .filters-section {
    flex-direction: column;
    align-items: stretch;
  }
  
  .header-content {
    flex-direction: column;
    gap: 15px;
    text-align: center;
  }
  
  .header-actions {
    justify-content: center;
  }
  
  .rides-table-container {
    overflow-x: auto;
    -webkit-overflow-scrolling: touch;
  }
  
  .rides-table {
    min-width: 800px;
  }
  
  .rides-table th,
  .rides-table td {
    padding: 12px 8px;
    font-size: 0.875rem;
  }
  
  .action-buttons {
    flex-direction: column;
    gap: 2px;
  }
  
  .action-button {
    padding: 4px 8px;
    font-size: 0.75rem;
  }
}
</style>