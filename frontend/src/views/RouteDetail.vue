<template>
  <div class="route-detail-container">
    <header class="header">
      <div class="header-content">
        <div class="header-info">
          <h1 v-if="route">{{ route.name }}</h1>
          <h1 v-else>Route Details</h1>
          <div v-if="route" class="route-status">
            <span class="status-badge" :class="route.isActive ? 'active' : 'inactive'">
              {{ route.isActive ? 'Active' : 'Inactive' }}
            </span>
          </div>
        </div>
        <div class="header-actions">
          <button @click="goBack" class="back-button">← Back to Routes</button>
        </div>
      </div>
    </header>

    <main class="main-content">
      <div v-if="loading" class="loading">
        <div class="loading-spinner"></div>
        Loading route details...
      </div>

      <div v-else-if="error" class="error-state">
        <div class="error-message">
          <h3>Route Not Found</h3>
          <p>{{ error }}</p>
          <button @click="goBack" class="back-button-large">
            ← Return to Routes
          </button>
        </div>
      </div>

      <div v-else-if="route" class="content-wrapper">
        <!-- Route Overview -->
        <div class="route-overview">
          <div class="overview-grid">
            <div class="overview-item">
              <h3>Description</h3>
              <p v-if="route.description">{{ route.description }}</p>
              <p v-else class="no-description">No description provided</p>
            </div>
            
            <div class="overview-stats">
              <div class="stat-card">
                <div class="stat-value">{{ route.stops.length }}</div>
                <div class="stat-label">Total Stops</div>
              </div>
              <div class="stat-card">
                <div class="stat-value">{{ route.totalDistance }} km</div>
                <div class="stat-label">Total Distance</div>
              </div>
              <div class="stat-card">
                <div class="stat-value">{{ formatDuration(route.estimatedDuration) }}</div>
                <div class="stat-label">Est. Duration</div>
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
          
          <div v-if="route.stops.length === 0" class="no-stops">
            <p>No stops have been defined for this route.</p>
          </div>

          <div v-else class="stops-timeline">
            <div 
              v-for="(stop, index) in route.stops" 
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
                  <span v-else">🏁</span>
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
                        v-if="index < route.stops.length - 1"
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
                        :disabled="loading"
                        title="Delete stop"
                      >
                        🗑️
                      </button>
                    </div>
                  </div>
                </div>

                <div class="stop-details">
                  <div class="stop-address">
                    <strong>Address:</strong> {{ stop.address }}
                  </div>
                  <div class="stop-coordinates">
                    <strong>Coordinates:</strong> 
                    {{ stop.coordinates.latitude.toFixed(6) }}, 
                    {{ stop.coordinates.longitude.toFixed(6) }}
                  </div>
                  <div class="stop-time">
                    <strong>Estimated Time:</strong> {{ stop.estimatedTime }} minutes from start
                  </div>
                </div>
              </div>

              <div v-if="index < route.stops.length - 1" class="route-connector"></div>
            </div>
          </div>
        </div>

        <!-- Route Map -->
        <div class="route-map" v-if="route.stops.length > 0">
          <h2>Route Map</h2>
          <div class="map-container">
            <div id="route-map" class="map"></div>
          </div>
          <div class="map-legend">
            <div class="legend-item">
              <div class="legend-marker pickup"></div>
              <span>Pickup Stop</span>
            </div>
            <div class="legend-item">
              <div class="legend-marker dropoff"></div>
              <span>Dropoff Stop</span>
            </div>
            <div class="legend-item">
              <div class="legend-line"></div>
              <span>Route Path</span>
            </div>
          </div>
        </div>

        <!-- Driving Instructions -->
        <div v-if="drivingInstructions.length > 0" class="driving-instructions">
          <h2>Driving Instructions</h2>
          <ol>
            <li v-for="instruction in drivingInstructions" :key="instruction.index">
              {{ instruction.text }}
              <span v-if="instruction.distance > 0" class="instruction-distance">
                ({{ formatDistance(instruction.distance) }})
              </span>
            </li>
          </ol>
          <div class="instructions-summary">
            <strong>Total Distance:</strong> {{ formatTotalDistance() }} | 
            <strong>Estimated Time:</strong> {{ formatTotalTime() }}
          </div>
        </div>

        <!-- Route Summary -->
        <div class="route-summary">
          <h2>Route Summary</h2>
          <div class="summary-grid">
            <div class="summary-item">
              <h4>Stop Types</h4>
              <div class="type-breakdown">
                <div class="type-count">
                  <span class="type-badge pickup">pickup</span>
                  <span class="count">{{ getStopsByType('pickup').length }}</span>
                </div>
                <div class="type-count">
                  <span class="type-badge dropoff">dropoff</span>
                  <span class="count">{{ getStopsByType('dropoff').length }}</span>
                </div>
              </div>
            </div>

            <div class="summary-item">
              <h4>Route Timeline</h4>
              <div class="timeline-info">
                <div v-if="route.stops.length > 0">
                  <div><strong>Start:</strong> {{ route.stops[0].name }}</div>
                  <div><strong>End:</strong> {{ route.stops[route.stops.length - 1].name }}</div>
                  <div><strong>Total Duration:</strong> {{ formatDuration(route.estimatedDuration) }}</div>
                </div>
                <div v-else class="no-timeline">
                  No stops defined
                </div>
              </div>
            </div>

            <div class="summary-item">
              <h4>Route Metadata</h4>
              <div class="metadata-info">
                <div><strong>Created:</strong> {{ formatDate(route.createdAt) }}</div>
                <div><strong>Last Updated:</strong> {{ formatDate(route.updatedAt) }}</div>
                <div><strong>Status:</strong> 
                  <span :class="route.isActive ? 'text-success' : 'text-warning'">
                    {{ route.isActive ? 'Active' : 'Inactive' }}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>
    
    <!-- Stop Creation Dialog -->
    <StopCreationDialog 
      :isOpen="showStopDialog"
      @close="showStopDialog = false"
      @save="handleAddStopFromDialog"
    />
  </div>
</template>

<script>
import { ref, inject, onMounted, onUnmounted, nextTick, watch, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import apiService from '../services/api'
import L from 'leaflet'
import 'leaflet-routing-machine'
import 'leaflet/dist/leaflet.css'
import StopCreationDialog from '../components/StopCreationDialog.vue'

export default {
  name: 'RouteDetail',
  components: {
    StopCreationDialog
  },
  setup() {
    const authStore = inject('authStore')
    const router = useRouter()
    const route = useRoute()
    
    const loading = ref(false)
    const error = ref('')
    const routeData = ref(null)
    const map = ref(null)
    const mapMarkers = ref([])
    const routeLine = ref(null)
    const routingControl = ref(null)
    const showStopDialog = ref(false)
    const drivingInstructions = ref([])
    
    const fetchRoute = async () => {
      try {
        loading.value = true
        error.value = ''
        
        const routeId = route.params.id
        const response = await apiService.get(`/routes/${routeId}`)
        routeData.value = response.route
      } catch (err) {
        console.error('Failed to fetch route:', err)
        if (err.response?.status === 404) {
          error.value = 'Route not found. It may have been deleted or the ID is invalid.'
        } else {
          error.value = 'Failed to load route details. Please try again.'
        }
      } finally {
        loading.value = false
      }
      
      // Initialize map after loading is complete and DOM is updated
      if (routeData.value && routeData.value.stops.length > 0) {
        await nextTick()
        setTimeout(() => {
          initializeMap()
        }, 100) // Small delay to ensure DOM is fully rendered
      }
    }
    
    const formatDate = (dateString) => {
      return new Date(dateString).toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      })
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
      return routeData.value?.stops.filter(stop => stop.type === type) || []
    }
    
    const initializeMap = () => {
      console.log('Attempting to initialize map...')
      const mapContainer = document.getElementById('route-map')
      
      if (!mapContainer) {
        console.error('Map container not found in DOM')
        return
      }
      
      if (!routeData.value || routeData.value.stops.length === 0) {
        console.error('No route data or stops available')
        return
      }
      
      console.log('Map container found, initializing map with', routeData.value.stops.length, 'stops')

      // Calculate center point from all stops
      const lats = routeData.value.stops.map(stop => stop.coordinates.latitude)
      const lngs = routeData.value.stops.map(stop => stop.coordinates.longitude)
      const centerLat = (Math.min(...lats) + Math.max(...lats)) / 2
      const centerLng = (Math.min(...lngs) + Math.max(...lngs)) / 2

      try {
        // Initialize map
        map.value = L.map('route-map').setView([centerLat, centerLng], 13)

        // Add OpenStreetMap tiles
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
          attribution: '© OpenStreetMap contributors',
          maxZoom: 19,
        }).addTo(map.value)

        // Add markers for stops
        addStopMarkers()
        
        // Draw route line
        drawRouteLine()
        
        // Fit map to show all markers
        if (mapMarkers.value.length > 0) {
          const group = new L.featureGroup(mapMarkers.value)
          map.value.fitBounds(group.getBounds().pad(0.1))
        }
        
        console.log('Map initialized successfully!')
      } catch (mapError) {
        console.error('Error initializing map:', mapError)
      }
    }

    const addStopMarkers = () => {
      if (!map.value || !routeData.value) return

      mapMarkers.value = []
      
      routeData.value.stops.forEach((stop, index) => {
        const isPickup = stop.type === 'pickup'
        
        // Create custom icon based on stop type
        const icon = L.divIcon({
          className: `custom-marker ${stop.type}-marker`,
          html: `
            <div class="marker-content">
              <div class="marker-number">${index + 1}</div>
              <div class="marker-icon">${isPickup ? '📍' : '🏁'}</div>
            </div>
          `,
          iconSize: [40, 50],
          iconAnchor: [20, 50],
          popupAnchor: [0, -50]
        })

        // Create marker
        const marker = L.marker(
          [stop.coordinates.latitude, stop.coordinates.longitude],
          { icon }
        ).addTo(map.value)

        // Create popup content
        const popupContent = `
          <div class="stop-popup">
            <h4>${stop.name}</h4>
            <div class="popup-type">
              <span class="type-badge ${stop.type}">${stop.type}</span>
            </div>
            <div class="popup-details">
              <strong>Address:</strong><br>
              ${stop.address}<br><br>
              <strong>Coordinates:</strong><br>
              ${stop.coordinates.latitude.toFixed(6)}, ${stop.coordinates.longitude.toFixed(6)}<br><br>
              <strong>Time:</strong> ${formatTime(stop.estimatedTime)} (${stop.estimatedTime} min from start)
            </div>
          </div>
        `

        marker.bindPopup(popupContent)
        mapMarkers.value.push(marker)
      })
    }

    const drawRouteLine = (updateServerWithTimeAndDistance = false) => {
      if (!map.value || !routeData.value || routeData.value.stops.length < 2) return

      // Remove previous route if exists
      if (routingControl.value) {
        map.value.removeControl(routingControl.value)
        routingControl.value = null
      }

      const waypoints = routeData.value.stops.map(stop =>
        L.latLng(stop.coordinates.latitude, stop.coordinates.longitude)
      )

      routingControl.value = L.Routing.control({
        waypoints,
        lineOptions: {
          styles: [{ color: '#007baa', weight: 4, opacity: 0.8 }]
        },
        routeWhileDragging: false,
        show: false,
        addWaypoints: false,
        draggableWaypoints: false,
        fitSelectedRoutes: true,
        createMarker: () => null, // We already add custom markers
        router: L.Routing.osrmv1({
          serviceUrl: 'https://router.project-osrm.org/route/v1'
        }),
        formatter: new L.Routing.Formatter()
      }).on('routesfound', function(e) {
        // Extract driving instructions when route is found
        const routes = e.routes
        if (routes && routes.length > 0) {
          const route = routes[0]
          drivingInstructions.value = route.instructions.map((instruction, index) => ({
            index: index + 1,
            text: instruction.text,
            distance: instruction.distance,
            time: instruction.time,
            type: instruction.type
          }))
          
          // Update route data with actual driving route information
          if (updateServerWithTimeAndDistance) {
            updateRouteWithDrivingData(route)
          } 
        }
      }).addTo(map.value)

      // Hide the routing instructions panel from the map
      setTimeout(() => {
        const routingContainer = document.querySelector('.leaflet-routing-container')
        if (routingContainer) {
          routingContainer.style.display = 'none'
        }
      }, 100)
    }
    
    const handleAddStopFromDialog = async (newStop) => {
      try {
        loading.value = true
        
        await apiService.post(`/routes/${route.params.id}/stops`, { stop: newStop })
        
        // Refresh route data
        await fetchRoute()
        
        // In order to update the server with the total distance and estimated duration
        nextTick(() => {
          drawRouteLine(true)
        })

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
      
      const stops = [...routeData.value.stops]
      const temp = stops[index]
      stops[index] = stops[index - 1]
      stops[index - 1] = temp
      
      await updateRouteStops(stops)
    }
    
    const moveStopDown = async (index) => {
      if (index >= routeData.value.stops.length - 1) return
      
      const stops = [...routeData.value.stops]
      const temp = stops[index]
      stops[index] = stops[index + 1]
      stops[index + 1] = temp
      
      await updateRouteStops(stops)
    }
    
    const deleteStop = async (index) => {
      if (!confirm('Are you sure you want to delete this stop?')) return
      
      try {
        loading.value = true
        await apiService.delete(`/routes/${route.params.id}/stops/${index}`)
        await fetchRoute()

        // In order to update the server with the total distance and estimated duration
        nextTick(() => {
          drawRouteLine(true)
        })
      } catch (error) {
        console.error('Failed to delete stop:', error)
        alert(error.response?.data?.message || 'Failed to delete stop')
      } finally {
        loading.value = false
      }
    }
    
    const updateRouteStops = async (stops) => {
      try {
        loading.value = true
        await apiService.put(`/routes/${route.params.id}/stops`, { stops })
        await fetchRoute()

        // In order to update the server with the total distance and estimated duration
        nextTick(() => {
          drawRouteLine(true)
        })
      } catch (error) {
        console.error('Failed to reorder stops:', error)
        alert(error.response?.data?.message || 'Failed to reorder stops')
      } finally {
        loading.value = false
      }
    }
    
    const goBack = () => {
      router.push('/routes')
    }
    
    const formatDistance = (distanceInMeters) => {
      if (distanceInMeters < 1000) {
        return `${Math.round(distanceInMeters)} m`
      } else {
        return `${(distanceInMeters / 1000).toFixed(1)} km`
      }
    }
    
    const formatTotalDistance = () => {
      const totalDistance = drivingInstructions.value.reduce((sum, instruction) => sum + instruction.distance, 0)
      return formatDistance(totalDistance)
    }
    
    const formatTotalTime = () => {
      const totalTime = drivingInstructions.value.reduce((sum, instruction) => sum + instruction.time, 0)
      const hours = Math.floor(totalTime / 3600)
      const minutes = Math.floor((totalTime % 3600) / 60)
      
      if (hours > 0) {
        return `${hours}h ${minutes}m`
      } else {
        return `${minutes}m`
      }
    }
    
    const updateRouteWithDrivingData = (drivingRoute) => {
      if (!routeData.value || !drivingRoute) return
      
      // Update total distance (convert meters to kilometers)
      const totalDistanceKm = (drivingRoute.summary.totalDistance / 1000).toFixed(1)
      routeData.value.totalDistance = parseFloat(totalDistanceKm)
      
      // Update estimated duration (convert seconds to minutes)
      const totalDurationMinutes = Math.round(drivingRoute.summary.totalTime / 60)
      routeData.value.estimatedDuration = totalDurationMinutes
      
      apiService.put(`/routes/${routeData.value._id}`, {
        totalDistance: routeData.value.totalDistance,
        estimatedDuration: routeData.value.estimatedDuration
      }).catch(err => {
        console.error('Failed to update route with driving data:', err)
      })
    }
    
    // Watch for when route data is loaded and loading is complete
    watch([routeData, loading], ([route, isLoading]) => {
      if (route && route.stops && route.stops.length > 0 && !isLoading && !map.value) {
        nextTick(() => {
          setTimeout(() => {
            initializeMap()
          }, 100)
        })
      }
    })
    
    onMounted(async () => {
      await fetchRoute()
    })
    
    onUnmounted(() => {
      // Clean up map resources
      if (map.value) {
        map.value.remove()
        map.value = null
      }
      mapMarkers.value = []
      routeLine.value = null
    })
    
    return {
      loading,
      error,
      route: routeData,
      showStopDialog,
      drivingInstructions,
      handleAddStopFromDialog,
      moveStopUp,
      moveStopDown,
      deleteStop,
      formatDuration,
      formatTime,
      formatDate,
      formatDistance,
      formatTotalDistance,
      formatTotalTime,
      getStopsByType,
      goBack
    }
  }
}
</script>

<style scoped>
.route-detail-container {
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

.status-badge {
  padding: 4px 12px;
  border-radius: 12px;
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

.error-message h3 {
  color: #dc3545;
  margin-bottom: 10px;
}

.error-message p {
  color: #666;
  margin-bottom: 30px;
}

.back-button-large {
  background-color: #007bff;
  color: white;
  border: none;
  padding: 12px 24px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 1rem;
  transition: background-color 0.2s;
}

.back-button-large:hover {
  background-color: #0056b3;
}

.content-wrapper {
  display: flex;
  flex-direction: column;
  gap: 30px;
}

.route-overview,
.route-stops,
.route-map,
.route-summary {
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
.route-map h2,
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

.no-description {
  font-style: italic;
  color: #999;
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

.text-success {
  color: #28a745;
  font-weight: bold;
}

.text-warning {
  color: #ffc107;
  font-weight: bold;
}

/* Map Styles */
.map-container {
  margin-bottom: 20px;
}

.map {
  height: 800px;
  width: 100%;
  border-radius: 8px;
  border: 1px solid #ddd;
}

.map-legend {
  display: flex;
  justify-content: center;
  gap: 30px;
  padding: 15px;
  background-color: #f8f9fa;
  border-radius: 8px;
  border: 1px solid #e9ecef;
}

.legend-item {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 0.9rem;
  color: #666;
}

.legend-marker {
  width: 20px;
  height: 20px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.8rem;
  font-weight: bold;
  color: white;
}

.legend-marker.pickup {
  background-color: #17a2b8;
}

.legend-marker.dropoff {
  background-color: #ffc107;
  color: #000;
}

.legend-line {
  width: 30px;
  height: 4px;
  background-color: #007bff;
  border-radius: 2px;
  position: relative;
}

.legend-line::after {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-image: repeating-linear-gradient(
    90deg,
    transparent,
    transparent 5px,
    white 5px,
    white 10px
  );
}

/* Custom Leaflet Marker Styles */
:deep(.custom-marker) {
  background: transparent;
  border: none;
}

:deep(.marker-content) {
  display: flex;
  flex-direction: column;
  align-items: center;
  position: relative;
}

:deep(.marker-number) {
  background-color: #fff;
  border: 2px solid #333;
  border-radius: 50%;
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.8rem;
  font-weight: bold;
  color: #333;
  margin-bottom: 2px;
  position: relative;
  z-index: 2;
}

:deep(.marker-icon) {
  font-size: 1.2rem;
  text-shadow: 1px 1px 2px rgba(0,0,0,0.5);
}

:deep(.pickup-marker .marker-number) {
  border-color: #17a2b8;
  background-color: #17a2b8;
  color: white;
}

:deep(.dropoff-marker .marker-number) {
  border-color: #ffc107;
  background-color: #ffc107;
  color: #000;
}

/* Custom Popup Styles */
:deep(.leaflet-popup-content-wrapper) {
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
}

:deep(.stop-popup) {
  min-width: 200px;
}

:deep(.stop-popup h4) {
  margin: 0 0 10px 0;
  color: #333;
  font-size: 1.1rem;
}

:deep(.popup-type) {
  margin-bottom: 10px;
}

:deep(.popup-details) {
  font-size: 0.85rem;
  line-height: 1.4;
  color: #666;
}

:deep(.popup-type .type-badge) {
  padding: 3px 8px;
  border-radius: 12px;
  font-size: 0.7rem;
  font-weight: bold;
  text-transform: uppercase;
}

:deep(.popup-type .type-badge.pickup) {
  background-color: #17a2b8;
  color: white;
}

:deep(.popup-type .type-badge.dropoff) {
  background-color: #ffc107;
  color: #000;
}

/* Hide the Leaflet Routing Machine control panel */
:deep(.leaflet-routing-container) {
  display: none !important;
}

:deep(.leaflet-routing-alternatives-container) {
  display: none !important;
}

.driving-instructions {
  background: #fff;
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.08);
  padding: 30px;
  margin-top: 20px;
}
.driving-instructions h2 {
  margin-bottom: 16px;
  color: #333;
}
.driving-instructions ol {
  padding-left: 20px;
}
.driving-instructions li {
  margin-bottom: 10px;
  color: #555;
  font-size: 1rem;
  line-height: 1.4;
}

.instruction-distance {
  color: #888;
  font-size: 0.9rem;
  font-weight: normal;
}

.instructions-summary {
  margin-top: 20px;
  padding: 15px;
  background-color: #f8f9fa;
  border-radius: 6px;
  border-left: 4px solid #007bff;
  font-size: 1rem;
  color: #333;
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
  
  .map-legend {
    flex-direction: column;
    gap: 15px;
  }
  
  .legend-item {
    justify-content: center;
  }
}
</style>