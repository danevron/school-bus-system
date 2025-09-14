<template>
  <div v-if="stops && stops.length > 0" class="route-map">
    <div class="map-container">
      <div :id="uniqueMapId" class="map" :style="{ height: mapHeight }"></div>
    </div>
    
    <div class="map-legend">
      <div class="legend-item">
        <div class="legend-marker pickup"></div>
        <span>{{ $t('routeMap.pickupStop') }}</span>
      </div>
      <div class="legend-item">
        <div class="legend-marker dropoff"></div>
        <span>{{ $t('routeMap.dropoffStop') }}</span>
      </div>
      <div class="legend-item">
        <div class="legend-line"></div>
        <span>{{ $t('routeMap.drivingRoute') }}</span>
      </div>
    </div>
    
    <!-- Driving Instructions (only show if enabled and instructions exist) -->
    <div v-if="showDrivingInstructions && drivingInstructions.length > 0" class="map-driving-instructions">
      <div class="instructions-header">
        <h3>{{ $t('routeMap.drivingInstructions') }}</h3>
        <button @click="toggleInstructions" class="toggle-instructions-button">
          {{ showInstructions ? $t('routeMap.hideInstructions') : $t('routeMap.showInstructions') }}
          <span class="toggle-arrow" :class="{ 'expanded': showInstructions }">▼</span>
        </button>
      </div>
      <div v-show="showInstructions" class="instructions-content">
        <ol>
          <li v-for="instruction in drivingInstructions" :key="instruction.index">
            {{ instruction.text }}
            <span v-if="instruction.distance" class="instruction-distance">
              ({{ formatDistance(instruction.distance) }})
            </span>
          </li>
        </ol>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, onMounted, onUnmounted, watch, nextTick, computed } from 'vue'
import { useI18n } from 'vue-i18n'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
import 'leaflet-routing-machine'

export default {
  name: 'RouteMap',
  props: {
    stops: {
      type: Array,
      required: true,
      default: () => []
    },
    studentAssignments: {
      type: Array,
      default: () => []
    },
    showDrivingInstructions: {
      type: Boolean,
      default: true
    },
    showDrivingRoute: {
      type: Boolean,
      default: true
    },
    mapHeight: {
      type: String,
      default: '800px'
    },
    mapId: {
      type: String,
      default: 'route-map'
    },
    showDetailedPopups: {
      type: Boolean,
      default: false
    },
    formatTime: {
      type: Function,
      default: null
    }
  },
  emits: ['route-updated'],
  setup(props, { emit }) {
    const { t } = useI18n()
    
    const map = ref(null)
    const mapMarkers = ref([])
    const routingControl = ref(null)
    const drivingInstructions = ref([])
    const showInstructions = ref(false)
    
    const uniqueMapId = computed(() => {
      return props.mapId + '-' + Math.random().toString(36).substr(2, 9)
    })
    
    const initializeMap = () => {
      if (!props.stops || props.stops.length === 0) {
        console.warn('No stops provided for map initialization')
        return
      }
      
      const mapContainer = document.getElementById(uniqueMapId.value)
      if (!mapContainer) {
        console.error('Map container not found:', uniqueMapId.value)
        return
      }
      
      // Calculate center point from all stops
      const lats = props.stops.map(stop => stop.coordinates.latitude)
      const lngs = props.stops.map(stop => stop.coordinates.longitude)
      const centerLat = (Math.min(...lats) + Math.max(...lats)) / 2
      const centerLng = (Math.min(...lngs) + Math.max(...lngs)) / 2
      
      try {
        // Initialize map
        map.value = L.map(uniqueMapId.value).setView([centerLat, centerLng], 13)
        
        // Add OpenStreetMap tiles
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
          attribution: '© OpenStreetMap contributors',
          maxZoom: 19,
        }).addTo(map.value)
        
        // Add markers for stops
        addStopMarkers()
        
        // Draw route line if enabled
        if (props.showDrivingRoute) {
          drawRouteLine()
        }
        
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
      if (!map.value || !props.stops) return
      
      mapMarkers.value = []
      
      props.stops.forEach((stop, index) => {
        // Create custom icon based on stop type
        const icon = L.divIcon({
          className: `custom-marker ${stop.type}-marker`,
          html: `
            <div class="marker-content">
              <div class="marker-number">${index + 1}</div>
            </div>
          `,
          iconSize: [30, 30],
          iconAnchor: [15, 15]
        })
        
        // Create marker
        const marker = L.marker(
          [stop.coordinates.latitude, stop.coordinates.longitude],
          { icon }
        ).addTo(map.value)
        
        // Create popup content based on showDetailedPopups prop
        let popupContent = `
          <div class="stop-popup">
            <h4>${stop.name}</h4>
            <div class="popup-type">
              <span class="type-badge ${stop.type}">
                ${ t('routeMap.' + stop.type) }
              </span>
            </div>
        `
        
        if (props.showDetailedPopups) {
          // Route manager style - show detailed stop info
          popupContent += `
            <div class="popup-details">
              ${ stop.address || t('routeMap.noAddressProvided')}<br><br>
            </div>
          `
        } else {
          // Line view style - show student assignments
          if (props.studentAssignments && props.studentAssignments.length > 0) {
            const assignedStudents = props.studentAssignments.filter(assignment => 
              (assignment.pickupStopDetails && assignment.pickupStopDetails.stopId === stop.stopId) ||
              (assignment.dropoffStopDetails && assignment.dropoffStopDetails.stopId === stop.stopId)
            )
            
            if (assignedStudents.length > 0) {
              const pickupStudents = assignedStudents.filter(assignment => 
                assignment.pickupStopDetails && assignment.pickupStopDetails.stopId === stop.stopId
              )
              const dropoffStudents = assignedStudents.filter(assignment => 
                assignment.dropoffStopDetails && assignment.dropoffStopDetails.stopId === stop.stopId
              )
              
              popupContent += `<div class="popup-students">`
              
              if (pickupStudents.length > 0) {
                popupContent += `<div><strong> ${t('routeMap.pickup')} (${pickupStudents.length})</strong></div>`
                pickupStudents.forEach(assignment => {
                  popupContent += `<div>• ${assignment.student.firstName} ${assignment.student.lastName}</div>`
                })
              }
              
              if (dropoffStudents.length > 0) {
                if (pickupStudents.length > 0) popupContent += `<br>`
                popupContent += `<div><strong>${t('routeMap.dropoff')} (${dropoffStudents.length})</strong></div>`
                dropoffStudents.forEach(assignment => {
                  popupContent += `<div>• ${assignment.student.firstName} ${assignment.student.lastName}</div>`
                })
              }
              
              popupContent += `</div>`
            } else {
              popupContent += `<div class="popup-students"><em>No students assigned</em></div>`
            }
          }
        }
        
        popupContent += `</div>`
        
        marker.bindPopup(popupContent)
        mapMarkers.value.push(marker)
      })
    }
    
    const drawRouteLine = () => {
      if (!map.value || !props.stops || props.stops.length < 2) return
      
      // Remove previous route if exists
      if (routingControl.value) {
        map.value.removeControl(routingControl.value)
        routingControl.value = null
      }
      
      const waypoints = props.stops.map(stop =>
        L.latLng(stop.coordinates.latitude, stop.coordinates.longitude)
      )
      
      routingControl.value = L.Routing.control({
        waypoints,
        lineOptions: {
          styles: [{ color: '#007baa', weight: 4, opacity: 0.8 }]
        },
        routeWhileDragging: false,
        show: false,
        createMarker: () => null // Don't create route markers, we have our own
      }).on('routesfound', (e) => {
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
          
          // Emit route update event
          emit('route-updated', {
            totalDistance: Math.round(route.summary.totalDistance / 1000 * 10) / 10, // km
            estimatedDuration: Math.round(route.summary.totalTime / 60) // minutes
          })
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
    
    const toggleInstructions = () => {
      showInstructions.value = !showInstructions.value
    }
    
    const formatDistance = (distance) => {
      if (distance < 1000) {
        return `${Math.round(distance)}m`
      }
      return `${Math.round(distance / 100) / 10}km`
    }
    
    const updateMap = () => {
      if (map.value) {
        // Clear existing markers
        mapMarkers.value.forEach(marker => {
          map.value.removeLayer(marker)
        })
        mapMarkers.value = []
        
        // Remove existing route
        if (routingControl.value) {
          map.value.removeControl(routingControl.value)
          routingControl.value = null
        }
        
        // Re-add markers and route
        if (props.stops && props.stops.length > 0) {
          addStopMarkers()
          
          if (props.showDrivingRoute) {
            drawRouteLine()
          }
          
          // Fit map to show all markers
          if (mapMarkers.value.length > 0) {
            const group = new L.featureGroup(mapMarkers.value)
            map.value.fitBounds(group.getBounds().pad(0.1))
          }
        }
      }
    }
    
    // Watch for stops changes
    watch(() => props.stops, () => {
      updateMap()
    }, { deep: true })
    
    // Watch for student assignments changes
    watch(() => props.studentAssignments, () => {
      updateMap()
    }, { deep: true })
    
    onMounted(async () => {
      await nextTick()
      setTimeout(() => {
        initializeMap()
      }, 100)
    })
    
    onUnmounted(() => {
      // Clean up map resources
      if (map.value) {
        map.value.remove()
        map.value = null
      }
      mapMarkers.value = []
      routingControl.value = null
    })
    
    return {
      uniqueMapId,
      drivingInstructions,
      showInstructions,
      toggleInstructions,
      formatDistance
    }
  }
}
</script>

<style scoped>
.route-map {
  background: white;
  border-radius: 8px;
  padding: 30px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
}

.map-container {
  margin-bottom: 20px;
}

.map {
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
  width: 12px;
  height: 12px;
  border-radius: 50%;
}

.legend-marker.pickup {
  background-color: #28a745;
}

.legend-marker.dropoff {
  background-color: #dc3545;
}

.legend-line {
  width: 20px;
  height: 3px;
  background-color: #007baa;
  border-radius: 2px;
}

/* Map Driving Instructions Styles */
.map-driving-instructions {
  margin-top: 30px;
  padding-top: 30px;
  border-top: 2px solid #e9ecef;
}

.instructions-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.instructions-header h3 {
  margin: 0;
  color: #333;
  font-size: 1.2rem;
}

.toggle-instructions-button {
  background: #f8f9fa;
  border: 1px solid #dee2e6;
  padding: 8px 16px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.9rem;
  color: #495057;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  gap: 8px;
}

.toggle-instructions-button:hover {
  background-color: #e2e6ea;
  border-color: #adb5bd;
}

.toggle-arrow {
  transition: transform 0.2s;
  font-size: 0.8rem;
}

.toggle-arrow.expanded {
  transform: rotate(180deg);
}

.instructions-content {
  background-color: #f8f9fa;
  padding: 20px;
  border-radius: 6px;
  border: 1px solid #e9ecef;
}

.map-driving-instructions ol {
  padding-left: 20px;
  margin: 0;
}

.map-driving-instructions li {
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

/* Custom marker styles */
:global(.custom-marker) {
  background: transparent;
  border: none;
}

:global(.marker-content) {
  width: 30px;
  height: 30px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-weight: bold;
  font-size: 12px;
  border: 2px solid white;
  box-shadow: 0 2px 6px rgba(0,0,0,0.3);
}

:global(.pickup-marker .marker-content) {
  background-color: #28a745;
}

:global(.dropoff-marker .marker-content) {
  background-color: #dc3545;
}

/* Popup styles */
:global(.stop-popup) {
  min-width: 200px;
}

:global(.stop-popup h4) {
  margin: 0 0 8px 0;
  color: #333;
}

:global(.popup-type) {
  margin-bottom: 12px;
}

:global(.type-badge) {
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 0.75rem;
  font-weight: 500;
  text-transform: uppercase;
}

:global(.type-badge.pickup) {
  background-color: #d4edda;
  color: #155724;
}

:global(.type-badge.dropoff) {
  background-color: #f8d7da;
  color: #721c24;
}

:global(.popup-students) {
  font-size: 0.9rem;
  line-height: 1.4;
}

:global(.popup-students div) {
  margin-bottom: 4px;
}

@media (max-width: 768px) {
  .route-map {
    padding: 20px;
  }
  
  .map {
    height: 400px;
  }
  
  .map-legend {
    flex-direction: column;
    gap: 15px;
  }
  
  .legend-item {
    justify-content: center;
  }
  
  .instructions-header {
    flex-direction: column;
    gap: 12px;
    align-items: stretch;
  }
}
</style>