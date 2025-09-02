<template>
  <div v-if="isOpen" class="modal-overlay" @click.self="close">
    <div class="modal-content">
      <div class="modal-header">
        <h3>{{ student && student._isEditing ? 'Edit Pickup & Dropoff Stops' : 'Select Pickup & Dropoff Stops' }}</h3>
        <button @click="close" class="close-button">×</button>
      </div>

      <div class="modal-body">
        <div v-if="student" class="student-info">
          <h4>Assigning stops for:</h4>
          <div class="student-details">
            <strong>{{ student.firstName }} {{ student.lastName }}</strong>
            <span class="student-contact">{{ student.phone }}</span>
          </div>
        </div>

        <div v-if="!hasStops" class="no-stops-message">
          <div class="warning-icon">⚠️</div>
          <h4>No Stops Available</h4>
          <p>This route has no stops defined yet. You can still add the student to the line, but you'll need to add stops to the route first before assigning pickup and dropoff locations.</p>
        </div>

        <div v-else class="stop-selection">
          <!-- Pickup Stop Selection -->
          <div class="stop-section">
            <h4>🚏 Pickup Stop</h4>
            <p class="section-description">Select where {{ student?.firstName }} will be picked up</p>
            
            <div class="stops-grid">
              <div
                v-for="(stop, index) in pickupStops"
                :key="stop.stopId"
                @click="selectPickupStop(stop, index)"
                class="stop-card"
                :class="{ 
                  'selected': selectedPickupStop && selectedPickupStop.stopId === stop.stopId,
                  'pickup-stop': true 
                }"
              >
                <div class="stop-header">
                  <div class="stop-number">{{ index + 1 }}</div>
                  <div class="stop-type-icon">📍</div>
                </div>
                <div class="stop-details">
                  <div class="stop-name">{{ stop.name }}</div>
                  <div class="stop-address">{{ stop.address }}</div>
                  <div class="stop-time">{{ formatTime(stop.estimatedTime) }}</div>
                </div>
              </div>
            </div>
          </div>

          <!-- Dropoff Stop Selection -->
          <div class="stop-section">
            <h4>🏁 Dropoff Stop</h4>
            <p class="section-description">Select where {{ student?.firstName }} will be dropped off</p>
            
            <div class="stops-grid">
              <div
                v-for="(stop, index) in dropoffStops"
                :key="stop.stopId"
                @click="selectDropoffStop(stop, index)"
                class="stop-card"
                :class="{ 
                  'selected': selectedDropoffStop && selectedDropoffStop.stopId === stop.stopId,
                  'dropoff-stop': true 
                }"
              >
                <div class="stop-header">
                  <div class="stop-number">{{ pickupStops.length + index + 1 }}</div>
                  <div class="stop-type-icon">🏁</div>
                </div>
                <div class="stop-details">
                  <div class="stop-name">{{ stop.name }}</div>
                  <div class="stop-address">{{ stop.address }}</div>
                  <div class="stop-time">{{ formatTime(stop.estimatedTime) }}</div>
                </div>
              </div>
            </div>
          </div>

          <div v-if="hasStops" class="skip-option">
            <label class="skip-checkbox">
              <input v-model="skipStopSelection" type="checkbox">
              <span class="checkmark"></span>
              Skip stop selection for now (can be set later)
            </label>
          </div>
        </div>
      </div>

      <div class="modal-footer">
        <button @click="close" class="cancel-button">Cancel</button>
        <button 
          @click="saveAssignment" 
          :disabled="!canSave"
          class="save-button"
        >
          {{ student && student._isEditing ? 'Update Assignment' : (hasStops ? 'Add Student' : 'Add Student (No Stops)') }}
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, watch } from 'vue'

export default {
  name: 'StopSelectionDialog',
  props: {
    isOpen: {
      type: Boolean,
      default: false
    },
    student: {
      type: Object,
      default: null
    },
    stops: {
      type: Array,
      default: () => []
    }
  },
  emits: ['close', 'save'],
  setup(props, { emit }) {
    const selectedPickupStop = ref(null)
    const selectedDropoffStop = ref(null)
    const skipStopSelection = ref(false)

    const hasStops = computed(() => props.stops && props.stops.length > 0)

    const pickupStops = computed(() => 
      props.stops.filter(stop => stop.type === 'pickup')
    )

    const dropoffStops = computed(() => 
      props.stops.filter(stop => stop.type === 'dropoff')
    )

    const canSave = computed(() => {
      if (!hasStops.value) return true // Can save if no stops available
      if (skipStopSelection.value) return true // Can save if skipping selection
      return selectedPickupStop.value && selectedDropoffStop.value // Must select both stops
    })

    const selectPickupStop = (stop, index) => {
      selectedPickupStop.value = { ...stop, index: index }
    }

    const selectDropoffStop = (stop, index) => {
      selectedDropoffStop.value = { ...stop, index: pickupStops.value.length + index }
    }

    const formatTime = (minutes) => {
      const hours = Math.floor(minutes / 60)
      const mins = minutes % 60
      return `${hours.toString().padStart(2, '0')}:${mins.toString().padStart(2, '0')}`
    }

    const saveAssignment = () => {
      const assignment = {
        student: props.student,
        pickupStop: selectedPickupStop.value,
        dropoffStop: selectedDropoffStop.value,
        skipStops: skipStopSelection.value || !hasStops.value
      }
      
      emit('save', assignment)
    }

    const close = () => {
      // Reset selections
      selectedPickupStop.value = null
      selectedDropoffStop.value = null
      skipStopSelection.value = false
      emit('close')
    }

    // Reset selections when dialog opens/closes and handle pre-selection for editing
    watch(() => props.isOpen, (isOpen) => {
      if (!isOpen) {
        selectedPickupStop.value = null
        selectedDropoffStop.value = null
        skipStopSelection.value = false
      } else {
        // Pre-select current stops if editing
        if (props.student && props.student._isEditing) {
          const currentPickupStopId = props.student._currentPickupStop
          const currentDropoffStopId = props.student._currentDropoffStop
          
          if (currentPickupStopId) {
            const pickupStop = props.stops.find(stop => stop.stopId === currentPickupStopId && stop.type === 'pickup')
            if (pickupStop) {
              const pickupIndex = pickupStops.value.findIndex(stop => stop.stopId === currentPickupStopId)
              selectedPickupStop.value = { ...pickupStop, index: pickupIndex }
            }
          }
          
          if (currentDropoffStopId) {
            const dropoffStop = props.stops.find(stop => stop.stopId === currentDropoffStopId && stop.type === 'dropoff')
            if (dropoffStop) {
              const dropoffIndex = dropoffStops.value.findIndex(stop => stop.stopId === currentDropoffStopId)
              selectedDropoffStop.value = { ...dropoffStop, index: pickupStops.value.length + dropoffIndex }
            }
          }
        }
      }
    })

    return {
      selectedPickupStop,
      selectedDropoffStop,
      skipStopSelection,
      hasStops,
      pickupStops,
      dropoffStops,
      canSave,
      selectPickupStop,
      selectDropoffStop,
      formatTime,
      saveAssignment,
      close
    }
  }
}
</script>

<style scoped>
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.modal-content {
  background: white;
  border-radius: 12px;
  width: 90%;
  max-width: 800px;
  max-height: 85vh;
  overflow: hidden;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 30px;
  border-bottom: 1px solid #e5e7eb;
  background-color: #f8f9fa;
}

.modal-header h3 {
  margin: 0;
  color: #333;
  font-size: 1.25rem;
}

.close-button {
  background: none;
  border: none;
  font-size: 24px;
  color: #666;
  cursor: pointer;
  padding: 0;
  width: 30px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  transition: background-color 0.2s;
}

.close-button:hover {
  background-color: #e5e7eb;
}

.modal-body {
  padding: 30px;
  max-height: 60vh;
  overflow-y: auto;
}

.student-info {
  margin-bottom: 30px;
  padding: 20px;
  background-color: #f8f9fa;
  border-radius: 8px;
  border-left: 4px solid #007bff;
}

.student-info h4 {
  margin: 0 0 10px 0;
  color: #333;
  font-size: 0.9rem;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.student-details {
  display: flex;
  align-items: center;
  gap: 15px;
}

.student-details strong {
  color: #333;
  font-size: 1.1rem;
}

.student-contact {
  color: #666;
  font-size: 0.9rem;
}

.no-stops-message {
  text-align: center;
  padding: 40px 20px;
  background-color: #fff3cd;
  border-radius: 8px;
  border: 1px solid #ffeaa7;
}

.warning-icon {
  font-size: 3rem;
  margin-bottom: 15px;
}

.no-stops-message h4 {
  color: #856404;
  margin-bottom: 10px;
}

.no-stops-message p {
  color: #856404;
  line-height: 1.5;
}

.stop-selection {
  display: flex;
  flex-direction: column;
  gap: 30px;
}

.stop-section h4 {
  margin: 0 0 8px 0;
  color: #333;
  display: flex;
  align-items: center;
  gap: 8px;
}

.section-description {
  color: #666;
  font-size: 0.9rem;
  margin: 0 0 20px 0;
}

.stops-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 15px;
  margin-bottom: 20px;
}

.stop-card {
  border: 2px solid #e5e7eb;
  border-radius: 8px;
  padding: 16px;
  cursor: pointer;
  transition: all 0.2s;
  background-color: white;
  position: relative;
}

.stop-card:hover {
  border-color: #007bff;
  box-shadow: 0 2px 8px rgba(0, 123, 255, 0.1);
}

.stop-card.selected {
  border-color: #007bff;
  background-color: #e3f2fd;
  box-shadow: 0 0 0 2px rgba(0, 123, 255, 0.2);
}

.pickup-stop.selected {
  border-color: #17a2b8;
  background-color: #e0f7fa;
  box-shadow: 0 0 0 2px rgba(23, 162, 184, 0.2);
}

.dropoff-stop.selected {
  border-color: #ffc107;
  background-color: #fff8e1;
  box-shadow: 0 0 0 2px rgba(255, 193, 7, 0.2);
}

.stop-header {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 12px;
}

.stop-number {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background-color: #007bff;
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: bold;
  font-size: 0.9rem;
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

.stop-details {
  padding-left: 40px;
}

.stop-name {
  font-weight: 600;
  color: #333;
  margin-bottom: 4px;
}

.stop-address {
  color: #666;
  font-size: 0.85rem;
  margin-bottom: 4px;
  line-height: 1.3;
}

.stop-time {
  color: #007bff;
  font-weight: 500;
  font-size: 0.85rem;
}

.skip-option {
  margin-top: 20px;
  padding: 20px;
  background-color: #f8f9fa;
  border-radius: 8px;
  border: 1px solid #e9ecef;
}

.skip-checkbox {
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
  color: #333;
}

.skip-checkbox input[type="checkbox"] {
  appearance: none;
  width: 18px;
  height: 18px;
  border: 2px solid #dee2e6;
  border-radius: 3px;
  background-color: white;
  cursor: pointer;
  position: relative;
}

.skip-checkbox input[type="checkbox"]:checked {
  background-color: #007bff;
  border-color: #007bff;
}

.skip-checkbox input[type="checkbox"]:checked::after {
  content: '✓';
  position: absolute;
  top: -2px;
  left: 2px;
  color: white;
  font-size: 12px;
  font-weight: bold;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  padding: 20px 30px;
  border-top: 1px solid #e5e7eb;
  background-color: #f8f9fa;
}

.cancel-button, .save-button {
  padding: 12px 24px;
  border-radius: 6px;
  cursor: pointer;
  font-weight: 500;
  transition: all 0.2s;
  border: none;
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

@media (max-width: 768px) {
  .modal-content {
    width: 95%;
    margin: 20px;
  }
  
  .modal-header, .modal-body, .modal-footer {
    padding: 20px;
  }
  
  .stops-grid {
    grid-template-columns: 1fr;
  }
  
  .student-details {
    flex-direction: column;
    align-items: flex-start;
    gap: 5px;
  }
}
</style>