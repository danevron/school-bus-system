<template>
  <div v-if="isOpen" class="modal-overlay" @click.self="close">
    <div class="modal-content">
      <div class="modal-header">
        <h3>Add Student to Line</h3>
        <button @click="close" class="close-button">×</button>
      </div>

      <div class="modal-body">
        <div v-if="loading" class="loading-state">
          <div class="loading-spinner"></div>
          <p>Loading students...</p>
        </div>

        <div v-else-if="error" class="error-state">
          <p class="error-message">{{ error }}</p>
          <button @click="fetchStudents" class="retry-button">Try Again</button>
        </div>

        <div v-else class="student-selection">
          <div class="search-container">
            <input
              v-model="searchTerm"
              type="text"
              placeholder="Search students by name..."
              class="search-input"
            >
          </div>

          <div v-if="filteredStudents.length === 0" class="no-students">
            <p>No available students found.</p>
          </div>

          <div v-else class="students-list">
            <div
              v-for="student in filteredStudents"
              :key="student._id"
              @click="selectStudent(student)"
              class="student-item"
              :class="{ 'selected': selectedStudent && selectedStudent._id === student._id }"
            >
              <div class="student-info">
                <div class="student-name">{{ student.firstName }} {{ student.lastName }}</div>
                <div class="student-email">{{ student.email || 'No email' }}</div>
                <div class="student-phone">{{ student.phone }}</div>
              </div>
              <div class="student-status">
                <span v-if="student.isAssigned" class="assigned-badge">Already Assigned</span>
                <span v-else class="available-badge">Available</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="modal-footer">
        <button @click="close" class="cancel-button">Cancel</button>
        <button 
          @click="addStudent" 
          :disabled="!selectedStudent || selectedStudent.isAssigned"
          class="add-button"
        >
          Add Student
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, watch, onMounted } from 'vue'
import apiService from '../services/api'

export default {
  name: 'StudentSelectionDialog',
  props: {
    isOpen: {
      type: Boolean,
      default: false
    },
    lineId: {
      type: String,
      required: true
    },
    assignedStudents: {
      type: Array,
      default: () => []
    }
  },
  emits: ['close', 'student-selected'],
  setup(props, { emit }) {
    const loading = ref(false)
    const error = ref('')
    const students = ref([])
    const selectedStudent = ref(null)
    const searchTerm = ref('')

    const filteredStudents = computed(() => {
      if (!searchTerm.value) return students.value
      
      const term = searchTerm.value.toLowerCase()
      return students.value.filter(student => 
        `${student.firstName} ${student.lastName}`.toLowerCase().includes(term) ||
        student.email?.toLowerCase().includes(term)
      )
    })

    const fetchStudents = async () => {
      try {
        loading.value = true
        error.value = ''

        const response = await apiService.get('/auth/users?role=student&isActive=true')

        // Mark students as assigned if they're already in the line
        const assignedIds = props.assignedStudents.map(s => s._id || s)
        students.value = (response.users || response.data || []).map(student => ({
          ...student,
          isAssigned: assignedIds.includes(student._id)
        }))
        
      } catch (err) {
        console.error('Failed to fetch students:', err)
        error.value = 'Failed to load students. Please try again.'
      } finally {
        loading.value = false
      }
    }

    const selectStudent = (student) => {
      if (student.isAssigned) return
      selectedStudent.value = student
    }

    const addStudent = () => {
      if (!selectedStudent.value || selectedStudent.value.isAssigned) return
      emit('student-selected', selectedStudent.value)
    }

    const close = () => {
      selectedStudent.value = null
      searchTerm.value = ''
      emit('close')
    }

    // Fetch students when dialog opens
    watch(() => props.isOpen, (isOpen) => {
      if (isOpen) {
        fetchStudents()
      }
    })

    return {
      loading,
      error,
      students,
      selectedStudent,
      searchTerm,
      filteredStudents,
      fetchStudents,
      selectStudent,
      addStudent,
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
  max-width: 600px;
  max-height: 80vh;
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
  max-height: 50vh;
  overflow-y: auto;
}

.loading-state, .error-state {
  text-align: center;
  padding: 40px 20px;
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

.error-message {
  color: #dc3545;
  margin-bottom: 20px;
}

.retry-button {
  background-color: #007bff;
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 6px;
  cursor: pointer;
  transition: background-color 0.2s;
}

.retry-button:hover {
  background-color: #0056b3;
}

.search-container {
  margin-bottom: 20px;
}

.search-input {
  width: 100%;
  padding: 12px 16px;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  font-size: 14px;
  transition: border-color 0.2s;
}

.search-input:focus {
  outline: none;
  border-color: #007bff;
  box-shadow: 0 0 0 3px rgba(0, 123, 255, 0.1);
}

.no-students {
  text-align: center;
  color: #666;
  font-style: italic;
  padding: 40px 20px;
}

.students-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  max-height: 300px;
  overflow-y: auto;
}

.student-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s;
  background-color: white;
}

.student-item:hover:not(.selected) {
  border-color: #007bff;
  background-color: #f8f9ff;
}

.student-item.selected {
  border-color: #007bff;
  background-color: #e3f2fd;
  box-shadow: 0 0 0 2px rgba(0, 123, 255, 0.1);
}

.student-item.selected .student-item:has(.assigned-badge) {
  cursor: not-allowed;
  opacity: 0.6;
}

.student-info {
  flex: 1;
}

.student-name {
  font-weight: 600;
  color: #333;
  margin-bottom: 4px;
}

.student-email, .student-phone {
  font-size: 0.85rem;
  color: #666;
  margin-bottom: 2px;
}

.student-status {
  display: flex;
  align-items: center;
}

.assigned-badge, .available-badge {
  padding: 4px 12px;
  border-radius: 16px;
  font-size: 0.75rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.assigned-badge {
  background-color: #fef3c7;
  color: #92400e;
}

.available-badge {
  background-color: #d1fae5;
  color: #065f46;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  padding: 20px 30px;
  border-top: 1px solid #e5e7eb;
  background-color: #f8f9fa;
}

.cancel-button, .add-button {
  padding: 10px 24px;
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

.add-button {
  background-color: #28a745;
  color: white;
}

.add-button:hover:not(:disabled) {
  background-color: #218838;
}

.add-button:disabled {
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
  
  .student-item {
    flex-direction: column;
    align-items: flex-start;
    gap: 10px;
  }
  
  .student-status {
    align-self: flex-end;
  }
}
</style>