<template>
  <div class="live-tracking-map">
    <div :id="uniqueMapId" :style="{ height: mapHeight }" class="map-container">
      <div v-if="!mapLoaded" class="map-loading">
        <div class="loading-spinner"></div>
        <span>Loading map...</span>
      </div>
      <div v-if="!busLocation && mapLoaded" class="no-location-overlay">
        <div class="no-location-content">
          <div class="no-location-icon">📍</div>
          <h4>No Live Location Data</h4>
          <p>The bus hasn't shared location data yet or GPS is not available.</p>
        </div>
      </div>
    </div>
    <div v-if="mapLoaded && busLocation" class="map-info">
      <div class="location-info">
        <span class="location-coords">
          📍 {{ Math.round(busLocation.latitude * 10000) / 10000 }}, 
          {{ Math.round(busLocation.longitude * 10000) / 10000 }}
        </span>
        <button @click="centerOnBus" class="center-bus-btn" title="Center on Bus">
          🎯 Center
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, onMounted, onUnmounted, watch, computed } from 'vue'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'

export default {
  name: 'LiveTrackingMap',
  props: {
    ride: {
      type: Object,
      required: true
    },
    rideProgress: {
      type: Object,
      default: null
    },
    busLocation: {
      type: Object,
      default: null // { latitude, longitude }
    },
    mapHeight: {
      type: String,
      default: '400px'
    },
    mapId: {
      type: String,
      default: 'live-tracking-map'
    }
  },
  setup(props) {
    const map = ref(null)
    const mapLoaded = ref(false)
    const busMarker = ref(null)
    const routePolyline = ref(null)
    const stopsMarkers = ref([])
    const locationTrail = ref([])
    const trailPolyline = ref(null)

    const uniqueMapId = computed(() => {
      return props.mapId + '-' + Math.random().toString(36).substr(2, 9)
    })

    const initializeMap = () => {
      const mapContainer = document.getElementById(uniqueMapId.value)
      if (!mapContainer) {
        console.error('Map container not found:', uniqueMapId.value)
        return
      }

      // Default center on ride route or general location
      let center = [32.0853, 34.7818] // Tel Aviv default
      
      if (props.ride?.route?.stops && props.ride.route.stops.length > 0) {
        const firstStop = props.ride.route.stops[0]
        if (firstStop.coordinates) {
          center = [firstStop.coordinates.latitude, firstStop.coordinates.longitude]
        }
      }

      try {
        // Initialize map with Leaflet
        map.value = L.map(uniqueMapId.value).setView(center, 13)
        
        // Add OpenStreetMap tiles
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
          attribution: '© OpenStreetMap contributors',
          maxZoom: 19,
        }).addTo(map.value)

        mapLoaded.value = true
        
        // Draw route and stops if available
        drawRoute()
        drawStops()
        
        // Draw bus location if available
        if (props.busLocation) {
          updateBusLocation(props.busLocation)
        }

        console.log('Live tracking map initialized successfully!')
      } catch (error) {
        console.error('Error initializing live tracking map:', error)
      }
    }

    const drawRoute = () => {
      if (!map.value || !props.ride?.route?.stops) return

      // Clear existing route
      if (routePolyline.value) {
        map.value.removeLayer(routePolyline.value)
        routePolyline.value = null
      }

      const stops = props.ride.route.stops
      const path = stops
        .filter(stop => stop.coordinates)
        .map(stop => [stop.coordinates.latitude, stop.coordinates.longitude])

      if (path.length < 2) return
    }

    const drawStops = () => {
      if (!map.value || !props.ride?.route?.stops) return

      // Clear existing stop markers
      stopsMarkers.value.forEach(marker => {
        map.value.removeLayer(marker)
      })
      stopsMarkers.value = []

      props.ride.route.stops.forEach((stop, index) => {
        if (!stop.coordinates) return

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
            <div class="popup-address">${stop.address || 'No address provided'}</div>
          </div>
        `

        marker.bindPopup(popupContent)
        stopsMarkers.value.push(marker)
      })
    }

    const updateBusLocation = (location) => {
      if (!map.value || !location) return

      const position = [location.latitude, location.longitude]

      // Create or update bus marker
      if (busMarker.value) {
        busMarker.value.setLatLng(position)
      } else {
        // Create custom bus icon
        const busIcon = L.divIcon({
          className: 'bus-marker',
          html: `
            <div class="bus-icon">
              <div class="bus-body">
                <div class="bus-windows">
                  <div class="window"></div>
                  <div class="window"></div>
                  <div class="window"></div>
                </div>
                <div class="bus-wheels">
                  <div class="wheel"></div>
                  <div class="wheel"></div>
                </div>
              </div>
              <div class="pulse-ring"></div>
            </div>
          `,
          iconSize: [40, 40],
          iconAnchor: [20, 20]
        })

        busMarker.value = L.marker(position, { 
          icon: busIcon,
          zIndexOffset: 1000 
        }).addTo(map.value)

        // Bus popup
        const busPopupContent = `
          <div class="bus-popup">
            <h4>🚌 School Bus</h4>
            <p><strong>Live Location</strong></p>
            <div class="coordinates">
              <div>Lat: ${location.latitude.toFixed(6)}</div>
              <div>Lng: ${location.longitude.toFixed(6)}</div>
            </div>
          </div>
        `

        busMarker.value.bindPopup(busPopupContent)
      }

      // Update location trail
      locationTrail.value.push(position)
      
      // Keep only last 50 points for performance
      if (locationTrail.value.length > 50) {
        locationTrail.value = locationTrail.value.slice(-50)
      }

      // Update trail polyline
      if (trailPolyline.value) {
        map.value.removeLayer(trailPolyline.value)
      }

      if (locationTrail.value.length > 1) {
        trailPolyline.value = L.polyline(locationTrail.value, {
          color: '#fd7e14',
          weight: 3,
          opacity: 0.8,
          dashArray: '10, 5' // Dashed line
        }).addTo(map.value)
      }
    }

    const centerOnBus = () => {
      if (!map.value || !props.busLocation) return
      
      map.value.setView([props.busLocation.latitude, props.busLocation.longitude], 16)
    }

    // Watch for bus location changes
    watch(() => props.busLocation, (newLocation) => {
      if (newLocation && mapLoaded.value) {
        updateBusLocation(newLocation)
      }
    }, { deep: true })

    // Watch for ride changes
    watch(() => props.ride, () => {
      if (mapLoaded.value) {
        drawRoute()
        drawStops()
      }
    }, { deep: true })

    onMounted(() => {
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
      stopsMarkers.value = []
      busMarker.value = null
      routePolyline.value = null
      trailPolyline.value = null
    })

    return {
      uniqueMapId,
      mapLoaded,
      centerOnBus
    }
  }
}
</script>

<style scoped>
.live-tracking-map {
  width: 100%;
  height: 100%;
  position: relative;
}

.map-container {
  width: 100%;
  position: relative;
  border-radius: 0 0 8px 8px;
  overflow: hidden;
  border: 1px solid #ddd;
}

.map-loading {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  background: #f8f9fa;
  color: #666;
  font-size: 1.1rem;
  gap: 15px;
  z-index: 10;
}

.loading-spinner {
  border: 3px solid #f3f3f3;
  border-top: 3px solid #007bff;
  border-radius: 50%;
  width: 30px;
  height: 30px;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.no-location-overlay {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(248, 249, 250, 0.95);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 5;
}

.no-location-content {
  text-align: center;
  padding: 20px;
  max-width: 300px;
}

.no-location-icon {
  font-size: 3rem;
  margin-bottom: 15px;
  opacity: 0.6;
}

.no-location-content h4 {
  color: #666;
  margin: 0 0 10px 0;
  font-size: 1.2rem;
}

.no-location-content p {
  color: #999;
  margin: 0;
  line-height: 1.5;
  font-size: 0.9rem;
}

.map-info {
  position: absolute;
  bottom: 10px;
  left: 10px;
  right: 10px;
  background: rgba(255, 255, 255, 0.95);
  border-radius: 6px;
  padding: 10px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
  z-index: 1000;
}

.location-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 10px;
}

.location-coords {
  font-size: 0.9rem;
  color: #333;
  font-family: monospace;
  font-weight: 500;
  flex: 1;
}

.center-bus-btn {
  background: linear-gradient(135deg, #fd7e14 0%, #e8690b 100%);
  color: white;
  border: none;
  padding: 6px 12px;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.85rem;
  font-weight: 500;
  transition: all 0.2s;
  white-space: nowrap;
}

.center-bus-btn:hover {
  background: linear-gradient(135deg, #e8690b 0%, #d45a00 100%);
  transform: translateY(-1px);
  box-shadow: 0 2px 6px rgba(232, 105, 11, 0.3);
}

/* Custom Leaflet marker styles */
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

/* Bus marker styles */
:global(.bus-marker) {
  background: transparent;
  border: none;
}

:global(.bus-icon) {
  position: relative;
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
}

:global(.bus-body) {
  width: 32px;
  height: 24px;
  background: linear-gradient(135deg, #FFA726 0%, #FFD54F 100%);
  border-radius: 4px;
  border: 2px solid #FF8F00;
  position: relative;
  z-index: 2;
}

:global(.bus-windows) {
  display: flex;
  justify-content: space-around;
  margin-top: 2px;
  gap: 1px;
}

:global(.window) {
  width: 4px;
  height: 3px;
  background: #81D4FA;
  border-radius: 1px;
}

:global(.bus-wheels) {
  position: absolute;
  bottom: -3px;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  justify-content: space-between;
  width: 24px;
}

:global(.wheel) {
  width: 6px;
  height: 6px;
  background: #424242;
  border-radius: 50%;
  border: 1px solid #616161;
}

:global(.pulse-ring) {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 60px;
  height: 60px;
  border: 2px solid #fd7e14;
  border-radius: 50%;
  animation: pulse 2s infinite;
  opacity: 0.6;
}

@keyframes pulse {
  0% {
    transform: translate(-50%, -50%) scale(0.8);
    opacity: 0.8;
  }
  50% {
    transform: translate(-50%, -50%) scale(1.1);
    opacity: 0.4;
  }
  100% {
    transform: translate(-50%, -50%) scale(1.3);
    opacity: 0;
  }
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
  margin-bottom: 8px;
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

:global(.popup-address) {
  color: #666;
  font-size: 0.9rem;
  margin-top: 8px;
}

:global(.bus-popup) {
  text-align: center;
  min-width: 150px;
}

:global(.bus-popup h4) {
  margin: 0 0 8px 0;
  color: #333;
}

:global(.coordinates) {
  font-family: monospace;
  font-size: 0.8rem;
  color: #666;
  margin-top: 8px;
}

:global(.coordinates div) {
  margin-bottom: 2px;
}

@media (max-width: 768px) {
  .location-info {
    flex-direction: column;
    gap: 8px;
  }
  
  .location-coords {
    font-size: 0.8rem;
    text-align: center;
  }
  
  .center-bus-btn {
    width: 100%;
  }
  
  .no-location-content {
    padding: 15px;
  }
  
  .no-location-icon {
    font-size: 2.5rem;
  }
  
  .no-location-content h4 {
    font-size: 1.1rem;
  }

  :global(.bus-icon) {
    width: 35px;
    height: 35px;
  }
  
  :global(.bus-body) {
    width: 28px;
    height: 20px;
  }
  
  :global(.pulse-ring) {
    width: 50px;
    height: 50px;
  }
}
</style>