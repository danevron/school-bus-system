<template>
  <div v-if="isOpen" class="dialog-overlay" @click="handleOverlayClick">
    <div class="dialog-container" @click.stop>
      <div class="dialog-header">
        <h3>{{ $t('stopCreation.title') }}</h3>
        <button @click="closeDialog" class="close-button">×</button>
      </div>
      
      <div class="dialog-content">
        <!-- Address Search Section -->
        <div class="address-search-section">
          <div class="search-header">
            <h4>{{ $t('stopCreation.findLocation') }}</h4>
            <p>{{ $t('stopCreation.searchInstructions') }}</p>
          </div>
          <div class="search-form">
            <div class="search-input-group">
              <input 
                v-model="addressSearch"
                type="text" 
                :placeholder="$t('stopCreation.addressPlaceholder')"
                class="address-search-input"
                @keyup.enter="searchAddress"
              />
              <button 
                @click="searchAddress"
                :disabled="!addressSearch.trim() || searchLoading"
                class="search-button"
              >
                <span v-if="searchLoading" class="loading-spinner small"></span>
                <span v-else>🔍</span>
              </button>
            </div>
            <div v-if="searchError" class="search-error">
              <span class="error-icon">⚠️</span>
              <span>{{ searchError }}</span>
            </div>
          </div>
        </div>

        <!-- Map Section -->
        <div class="map-section">
          <div class="map-instructions">
            <div v-if="selectedCoordinates" class="coordinates-display">
              <span class="coord-label">{{ $t('stopCreation.selectedLocation') }}:</span>
              <span class="coordinates">
                {{ selectedCoordinates.lat.toFixed(6) }}, {{ selectedCoordinates.lng.toFixed(6) }}
              </span>
              <div v-if="addressLoading" class="address-loading">
                <span class="loading-spinner"></span>
                <span>{{ $t('stopCreation.lookingUpAddress') }}</span>
              </div>
              <div v-else-if="lookupError" class="address-error">
                <span class="error-icon">⚠️</span>
                <span>{{ $t('stopCreation.couldNotFindAddress') }}</span>
              </div>
            </div>
          </div>
          <div id="stop-creation-map" class="stop-creation-map"></div>
        </div>
        
        <!-- Stop Details Form -->
        <div v-if="selectedCoordinates" class="stop-form-section">
          <div class="form-group">
            <label for="stop-name">{{ $t('stopCreation.stopName') }} *</label>
            <input 
              id="stop-name"
              v-model="stopForm.name" 
              type="text" 
              :placeholder="$t('stopCreation.stopNamePlaceholder')"
              required
            />
          </div>
          
          <div class="form-group">
            <label for="stop-address">{{ $t('stopCreation.address') }}</label>
            <input 
              id="stop-address"
              v-model="stopForm.address" 
              type="text" 
              :placeholder="addressLoading ? $t('stopCreation.loadingAddress') : $t('stopCreation.addressAutoFillHint')"
              :readonly="addressLoading"
            />
            <div class="address-hint">
              {{ $t('stopCreation.addressHint') }}
            </div>
          </div>
          
          <div class="form-group">
            <label for="stop-type">{{ $t('stopCreation.stopType') }} *</label>
            <select id="stop-type" v-model="stopForm.type" required>
              <option value="">{{ $t('stopCreation.selectType') }}</option>
              <option value="pickup">{{ $t('stopCreation.pickup') }}</option>
              <option value="dropoff">{{ $t('stopCreation.dropoff') }}</option>
            </select>
          </div>
          
        </div>
      </div>
      
      <div class="dialog-actions">
        <button @click="closeDialog" class="cancel-button">{{ $t('common.cancel') }}</button>
        <button 
          @click="saveStop" 
          :disabled="!canSave"
          class="save-button"
        >
          {{ $t('stopCreation.addStop') }}
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, watch, nextTick } from 'vue'
import { useI18n } from 'vue-i18n'
import L from 'leaflet'

export default {
  name: 'StopCreationDialog',
  props: {
    isOpen: {
      type: Boolean,
      default: false
    }
  },
  emits: ['close', 'save'],
  setup(props, { emit }) {
    const { t } = useI18n()
    
    const map = ref(null)
    const selectedMarker = ref(null)
    const selectedCoordinates = ref(null)
    const addressLoading = ref(false)
    const lookupError = ref(false)
    const addressSearch = ref('')
    const searchLoading = ref(false)
    const searchError = ref('')
    
    const stopForm = ref({
      name: '',
      address: '',
      type: ''
    })
    
    const canSave = computed(() => {
      return selectedCoordinates.value && 
             stopForm.value.name.trim() && 
             stopForm.value.type
    })
    
    const initializeMap = () => {
      nextTick(() => {
        const mapContainer = document.getElementById('stop-creation-map')
        if (!mapContainer) {
          console.error('Stop creation map container not found')
          return
        }
        
        // Default center: Ramat Gan, Israel
        const defaultLat = 32.0853
        const defaultLng = 34.8169
        
        map.value = L.map('stop-creation-map').setView([defaultLat, defaultLng], 14)
        
        // Add OpenStreetMap tiles
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
          attribution: '© OpenStreetMap contributors',
          maxZoom: 19,
        }).addTo(map.value)
        
        // Add click event to map
        map.value.on('click', handleMapClick)
        
        console.log('Stop creation map initialized')
      })
    }
    
    const reverseGeocode = async (lat, lng) => {
      try {
        addressLoading.value = true
        lookupError.value = false
        
        const response = await fetch(
          `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}&addressdetails=1`
        )
        
        if (!response.ok) {
          throw new Error('Geocoding request failed')
        }
        
        const data = await response.json()
        
        if (data && data.display_name) {
          // Format the address nicely
          const address = data.address
          let formattedAddress = data.display_name
          
          // Try to create a shorter, more readable address
          if (address) {
            const parts = []
            if (address.house_number) parts.push(address.house_number)
            if (address.road) parts.push(address.road)
            if (address.neighbourhood || address.suburb) parts.push(address.neighbourhood || address.suburb)
            if (address.city || address.town || address.village) parts.push(address.city || address.town || address.village)
            if (address.state) parts.push(address.state)
            
            if (parts.length > 0) {
              formattedAddress = parts.join(', ')
            }
          }
          
          stopForm.value.address = formattedAddress
        } else {
          throw new Error('No address found')
        }
      } catch (error) {
        console.error('Reverse geocoding failed:', error)
        lookupError.value = true
        stopForm.value.address = ''
      } finally {
        addressLoading.value = false
      }
    }

    const searchAddress = async () => {
      if (!addressSearch.value.trim()) return
      
      try {
        searchLoading.value = true
        searchError.value = ''
        
        // Add "Israel" to search if not present for better results
        let searchQuery = addressSearch.value.trim()
        if (!searchQuery.toLowerCase().includes('israel')) {
          searchQuery += ', Israel'
        }
        
        const response = await fetch(
          `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(searchQuery)}&limit=1&addressdetails=1`
        )
        
        if (!response.ok) {
          throw new Error('Search request failed')
        }
        
        const data = await response.json()
        
        if (data && data.length > 0) {
          const result = data[0]
          const lat = parseFloat(result.lat)
          const lng = parseFloat(result.lon)
          
          // Remove existing marker if any
          if (selectedMarker.value) {
            map.value.removeLayer(selectedMarker.value)
          }
          
          // Create new marker
          selectedMarker.value = L.marker([lat, lng], {
            icon: L.divIcon({
              className: 'new-stop-marker',
              html: `
                <div class="marker-content">
                  <div class="marker-icon">📍</div>
                </div>
              `,
              iconSize: [30, 40],
              iconAnchor: [15, 40],
              popupAnchor: [0, -40]
            })
          }).addTo(map.value)
          
          // Store coordinates
          selectedCoordinates.value = { lat, lng }
          
          // Center map on found location
          map.value.setView([lat, lng], 16)
          
          // Auto-fill address from search result
          stopForm.value.address = result.display_name
          
          // Add popup to marker
          selectedMarker.value.bindPopup('Found Location').openPopup()
          
        } else {
          throw new Error('Address not found')
        }
      } catch (error) {
        console.error('Address search failed:', error)
        searchError.value = error.message || 'Could not find the address'
      } finally {
        searchLoading.value = false
      }
    }

    const handleMapClick = async (e) => {
      const { lat, lng } = e.latlng
      
      // Remove existing marker if any
      if (selectedMarker.value) {
        map.value.removeLayer(selectedMarker.value)
      }
      
      // Create new marker
      selectedMarker.value = L.marker([lat, lng], {
        icon: L.divIcon({
          className: 'new-stop-marker',
          html: `
            <div class="marker-content">
              <div class="marker-icon">📍</div>
            </div>
          `,
          iconSize: [30, 40],
          iconAnchor: [15, 40],
          popupAnchor: [0, -40]
        })
      }).addTo(map.value)
      
      // Store coordinates
      selectedCoordinates.value = { lat, lng }
      
      // Add popup to marker
      selectedMarker.value.bindPopup('New Stop Location').openPopup()
      
      // Perform reverse geocoding to get address
      await reverseGeocode(lat, lng)
    }
    
    const handleOverlayClick = (e) => {
      if (e.target === e.currentTarget) {
        closeDialog()
      }
    }
    
    const closeDialog = () => {
      resetForm()
      emit('close')
    }
    
    const saveStop = () => {
      if (!canSave.value) return
      
      const newStop = {
        name: stopForm.value.name.trim(),
        address: stopForm.value.address.trim(),
        coordinates: {
          latitude: selectedCoordinates.value.lat,
          longitude: selectedCoordinates.value.lng
        },
        type: stopForm.value.type,
        estimatedTime: 0
      }
      
      emit('save', newStop)
      resetForm()
    }
    
    const resetForm = () => {
      stopForm.value = {
        name: '',
        address: '',
        type: ''
      }
      selectedCoordinates.value = null
      addressLoading.value = false
      lookupError.value = false
      addressSearch.value = ''
      searchLoading.value = false
      searchError.value = ''
      
      if (selectedMarker.value && map.value) {
        map.value.removeLayer(selectedMarker.value)
        selectedMarker.value = null
      }
      
      if (map.value) {
        map.value.remove()
        map.value = null
      }
    }
    
    // Watch for dialog open/close
    watch(() => props.isOpen, (newValue) => {
      if (newValue) {
        setTimeout(initializeMap, 100) // Small delay to ensure DOM is ready
      } else {
        resetForm()
      }
    })
    
    return {
      selectedCoordinates,
      addressLoading,
      lookupError,
      addressSearch,
      searchLoading,
      searchError,
      stopForm,
      canSave,
      searchAddress,
      handleOverlayClick,
      closeDialog,
      saveStop
    }
  }
}
</script>

<style scoped>
.dialog-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 20px;
}

.dialog-container {
  background: white;
  border-radius: 12px;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.3);
  width: 95%;
  max-width: 1000px;
  max-height: 95vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.dialog-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 25px;
  border-bottom: 1px solid #e9ecef;
  background-color: #f8f9fa;
}

.dialog-header h3 {
  margin: 0;
  color: #333;
  font-size: 1.2rem;
}

.close-button {
  background: none;
  border: none;
  font-size: 24px;
  cursor: pointer;
  color: #666;
  width: 30px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  transition: background-color 0.2s;
}

.close-button:hover {
  background-color: #e9ecef;
  color: #333;
}

.dialog-content {
  flex: 1;
  overflow-y: auto;
  padding: 25px;
  display: flex;
  flex-direction: column;
  gap: 25px;
}

.map-section {
  flex: 1;
}

.map-instructions {
  margin-bottom: 15px;
}

.map-instructions p {
  margin: 0 0 10px 0;
  color: #666;
  font-size: 0.9rem;
}

.coordinates-display {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  background-color: #e3f2fd;
  border-radius: 4px;
  font-size: 0.85rem;
}

.coord-label {
  font-weight: bold;
  color: #1976d2;
}

.coordinates {
  font-family: monospace;
  color: #424242;
}

.address-loading,
.address-error {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 8px;
  padding: 6px 10px;
  border-radius: 4px;
  font-size: 0.8rem;
}

.address-loading {
  background-color: #e3f2fd;
  color: #1976d2;
}

.address-error {
  background-color: #ffebee;
  color: #c62828;
}

.loading-spinner {
  width: 12px;
  height: 12px;
  border: 2px solid transparent;
  border-top: 2px solid #1976d2;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.error-icon {
  font-size: 14px;
}

.address-search-section {
  background-color: #f8f9fa;
  border-radius: 8px;
  padding: 20px;
  border: 1px solid #e9ecef;
}

.search-header h4 {
  margin: 0 0 8px 0;
  color: #333;
  font-size: 1.1rem;
}

.search-header p {
  margin: 0 0 15px 0;
  color: #666;
  font-size: 0.9rem;
}

.search-input-group {
  display: flex;
  gap: 10px;
  margin-bottom: 10px;
}

.address-search-input {
  flex: 1;
  padding: 10px 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
  transition: border-color 0.2s;
}

.address-search-input:focus {
  outline: none;
  border-color: #007bff;
  box-shadow: 0 0 0 2px rgba(0, 123, 255, 0.25);
}

.search-button {
  background-color: #007bff;
  color: white;
  border: none;
  padding: 10px 16px;
  border-radius: 4px;
  cursor: pointer;
  font-size: 16px;
  transition: background-color 0.2s;
  min-width: 48px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.search-button:hover:not(:disabled) {
  background-color: #0056b3;
}

.search-button:disabled {
  background-color: #ccc;
  cursor: not-allowed;
}

.search-error {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  background-color: #ffebee;
  color: #c62828;
  border-radius: 4px;
  font-size: 0.85rem;
}

.loading-spinner.small {
  width: 14px;
  height: 14px;
  border: 2px solid transparent;
  border-top: 2px solid white;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

.stop-creation-map {
  height: 400px;
  width: 100%;
  border-radius: 8px;
  border: 1px solid #ddd;
}

.stop-form-section {
  background-color: #f8f9fa;
  border-radius: 8px;
  padding: 20px;
  border: 1px solid #e9ecef;
}

.form-group {
  margin-bottom: 15px;
}

.form-group:last-child {
  margin-bottom: 0;
}

.form-group label {
  display: block;
  margin-bottom: 5px;
  color: #333;
  font-weight: bold;
  font-size: 0.9rem;
}

.form-group input,
.form-group select {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
  transition: border-color 0.2s;
}

.form-group input:focus,
.form-group select:focus {
  outline: none;
  border-color: #007bff;
  box-shadow: 0 0 0 2px rgba(0, 123, 255, 0.25);
}

.form-group input[readonly] {
  background-color: #f8f9fa;
  cursor: not-allowed;
}

.address-hint {
  font-size: 0.75rem;
  color: #666;
  margin-top: 4px;
  font-style: italic;
}

.dialog-actions {
  display: flex;
  gap: 10px;
  justify-content: flex-end;
  padding: 20px 25px;
  border-top: 1px solid #e9ecef;
  background-color: #f8f9fa;
}

.cancel-button,
.save-button {
  padding: 10px 20px;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 500;
  transition: background-color 0.2s;
}

.cancel-button {
  background-color: #6c757d;
  color: white;
}

.cancel-button:hover {
  background-color: #545b62;
}

.save-button {
  background-color: #28a745;
  color: white;
}

.save-button:hover:not(:disabled) {
  background-color: #218838;
}

.save-button:disabled {
  background-color: #ccc;
  cursor: not-allowed;
}

/* Custom marker styles */
:deep(.new-stop-marker) {
  background: none;
  border: none;
}

:deep(.new-stop-marker .marker-content) {
  background-color: #28a745;
  color: white;
  border-radius: 50%;
  width: 30px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 3px solid white;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.3);
}

:deep(.new-stop-marker .marker-icon) {
  font-size: 16px;
}

@media (max-width: 768px) {
  .dialog-container {
    width: 98%;
    margin: 5px;
    max-height: 98vh;
  }
  
  .dialog-content {
    padding: 15px;
    gap: 20px;
  }
  
  .stop-creation-map {
    height: 300px;
  }
  
  .dialog-actions {
    padding: 15px 20px;
  }
  
  .search-input-group {
    flex-direction: column;
  }
  
  .address-search-input {
    margin-bottom: 10px;
  }
  
  .search-button {
    align-self: flex-start;
    min-width: 100px;
  }
}
</style>