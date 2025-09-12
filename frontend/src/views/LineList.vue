<template>
  <div class="line-list-container">
    <header class="header">
      <div class="header-content">
        <h1>Line Management</h1>
        <div class="header-actions">
          <button @click="goBack" class="back-button">← Back to Dashboard</button>
          <button @click="handleAddLine" class="add-line-button">+ Add New Line</button>
        </div>
      </div>
    </header>

    <main class="main-content">
      <div class="content-wrapper">
        <!-- Lines List Section -->
        <div class="lines-section">
          <div v-if="loading" class="loading">Loading lines...</div>
          
          <div v-else-if="lines.length === 0" class="no-lines">
            <div class="empty-state">
              <h3>No lines found</h3>
              <p>Start by creating your first transportation line.</p>
              <button @click="handleAddLine" class="add-line-button-large">
                + Create First Line
              </button>
            </div>
          </div>

          <div v-else class="lines-grid">
            <div 
              v-for="line in lines" 
              :key="line._id" 
              class="line-card"
              @click="viewLine(line._id)"
            >
              <div class="line-header">
                <h3 class="line-name">{{ line.name }}</h3>
                <span class="status-badge" :class="line.isActive ? 'active' : 'inactive'">
                  {{ line.isActive ? 'Active' : 'Inactive' }}
                </span>
              </div>

              <div class="line-info">
                <div class="line-stats">
                  <div class="stat-item">
                    <span class="stat-label">Route:</span>
                    <span class="stat-value">{{ line.route?.name || 'No Route' }}</span>
                  </div>
                  <div class="stat-item">
                    <span class="stat-label">Vehicle:</span>
                    <span class="stat-value">{{ line.vehicle?.licensePlate || 'No Vehicle' }}</span>
                  </div>
                  <div class="stat-item">
                    <span class="stat-label">Driver:</span>
                    <span class="stat-value">{{ getDriverName(line.driver) }}</span>
                  </div>
                </div>

                <div class="line-details">
                  <div class="detail-item">
                    <strong>Start Time:</strong>
                    <span class="start-time">{{ formatTime(line.rideStartTime) }}</span>
                  </div>
                  <div class="detail-item">
                    <strong>Duration:</strong>
                    <span class="schedule-duration">{{ formatScheduleDuration(line.schedule) }}</span>
                  </div>
                  <div class="detail-item">
                    <strong>Operating Days:</strong>
                    <span class="schedule-days">{{ formatScheduleDays(line.schedule) }}</span>
                  </div>
                  <div class="detail-item">
                    <strong>Students:</strong>
                    <span class="student-count">{{ line.students?.length || 0 }} assigned</span>
                  </div>
                </div>

                <div class="line-meta">
                  <div class="line-dates">
                    Created: {{ formatDate(line.createdAt) }}
                  </div>
                  <div class="line-capacity" v-if="line.vehicle">
                    Capacity: {{ line.students?.length || 0 }}/{{ line.vehicle.capacity }}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<script>
import { ref, inject, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import apiService from '../services/api'

export default {
  name: 'LineList',
  setup() {
    const authStore = inject('authStore')
    const router = useRouter()
    
    const loading = ref(false)
    const lines = ref([])
    
    const fetchLines = async () => {
      try {
        loading.value = true
        const response = await apiService.get('/lines')
        const fetchedLines = response.lines || response.data || []
        
        // Sort lines by creation date (newest first)
        lines.value = fetchedLines.sort((a, b) => {
          return new Date(b.createdAt) - new Date(a.createdAt)
        })
      } catch (error) {
        console.error('Failed to fetch lines:', error)
      } finally {
        loading.value = false
      }
    }
    
    const viewLine = (lineId) => {
      router.push(`/lines/${lineId}`)
    }
    
    const handleAddLine = () => {
      router.push('/lines/create')
    }
    
    const formatDate = (dateString) => {
      return new Date(dateString).toLocaleDateString()
    }
    
    const formatTime = (timeString) => {
      if (!timeString) return 'Not set'
      
      // Handle HH:MM format
      const [hours, minutes] = timeString.split(':')
      const hour12 = hours % 12 || 12
      const ampm = hours < 12 ? 'AM' : 'PM'
      return `${hour12}:${minutes} ${ampm}`
    }
    
    const formatScheduleType = (scheduleType) => {
      const typeMap = {
        daily: 'Daily',
        weekdays: 'Weekdays',
        weekends: 'Weekends',
        custom: 'Custom'
      }
      return typeMap[scheduleType] || scheduleType
    }
    
    const getDriverName = (driver) => {
      if (!driver) return 'No Driver'
      if (typeof driver === 'string') return 'Driver Assigned'
      return `${driver.firstName || ''} ${driver.lastName || ''}`.trim() || 'Driver Assigned'
    }
    
    const formatScheduleDuration = (schedule) => {
      if (!schedule || !schedule.startDate) {
        return 'No schedule set'
      }
      
      const start = new Date(schedule.startDate)
      const end = schedule.endDate ? new Date(schedule.endDate) : null
      
      if (!end) {
        return `From ${start.toLocaleDateString()}`
      }
      
      const diffTime = Math.abs(end - start)
      const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24)) + 1
      
      const startStr = start.toLocaleDateString()
      const endStr = end.toLocaleDateString()
      
      if (diffDays === 1) {
        return `${startStr} (1 day)`
      } else if (diffDays < 30) {
        return `${startStr} - ${endStr} (${diffDays} days)`
      } else if (diffDays < 365) {
        const weeks = Math.floor(diffDays / 7)
        return `${startStr} - ${endStr} (${weeks} week${weeks > 1 ? 's' : ''})`
      } else {
        const years = Math.floor(diffDays / 365)
        return `${startStr} - ${endStr} (${years} year${years > 1 ? 's' : ''})`
      }
    }
    
    const formatScheduleDays = (schedule) => {
      if (!schedule || !schedule.daysOfWeek || schedule.daysOfWeek.length === 0) {
        return 'No days selected'
      }
      
      const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
      const selectedDays = schedule.daysOfWeek
        .sort((a, b) => a - b) // Sort to ensure correct order
        .map(dayNum => dayNames[dayNum])
      
      // Check for common patterns
      if (selectedDays.length === 7) {
        return 'Every day'
      } else if (selectedDays.length === 5 && 
                 schedule.daysOfWeek.includes(0) && 
                 schedule.daysOfWeek.includes(1) && 
                 schedule.daysOfWeek.includes(2) && 
                 schedule.daysOfWeek.includes(3) && 
                 schedule.daysOfWeek.includes(4)) {
        return 'Sun-Thu (Weekdays)'
      } else if (selectedDays.length === 2 && 
                 schedule.daysOfWeek.includes(0) && 
                 schedule.daysOfWeek.includes(6)) {
        return 'Sat-Sun (Weekends)'
      } else {
        return selectedDays.join(', ')
      }
    }
    
    const goBack = () => {
      router.push('/home')
    }
    
    onMounted(async () => {
      await fetchLines()
    })
    
    return {
      loading,
      lines,
      fetchLines,
      viewLine,
      handleAddLine,
      formatDate,
      formatScheduleType,
      formatScheduleDuration,
      formatScheduleDays,
      formatTime,
      getDriverName,
      goBack
    }
  }
}
</script>

<style scoped>
.line-list-container {
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
}

.header-actions {
  display: flex;
  gap: 12px;
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

.add-line-button {
  background-color: #28a745;
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: 4px;
  cursor: pointer;
  transition: background-color 0.2s;
  font-weight: 500;
}

.add-line-button:hover {
  background-color: #218838;
}

.main-content {
  max-width: 1200px;
  margin: 0 auto;
  padding: 30px 20px;
}

.content-wrapper {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.lines-section {
  background: white;
  border-radius: 8px;
  padding: 30px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
}

.loading {
  text-align: center;
  color: #666;
  padding: 40px;
  font-size: 1.1rem;
}

.no-lines {
  text-align: center;
  padding: 60px 20px;
}

.empty-state h3 {
  color: #333;
  margin-bottom: 10px;
}

.empty-state p {
  color: #666;
  margin-bottom: 30px;
}

.add-line-button-large {
  background-color: #28a745;
  color: white;
  border: none;
  padding: 12px 24px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 1rem;
  font-weight: 500;
  transition: background-color 0.2s;
}

.add-line-button-large:hover {
  background-color: #218838;
}

.lines-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(400px, 1fr));
  gap: 20px;
}

.line-card {
  border: 1px solid #ddd;
  border-radius: 8px;
  padding: 20px;
  transition: all 0.2s;
  cursor: pointer;
  background: white;
}

.line-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  transform: translateY(-2px);
}

.line-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 15px;
}

.line-name {
  margin: 0;
  color: #333;
  font-size: 1.25rem;
  font-weight: 600;
}

.status-badge {
  padding: 4px 8px;
  border-radius: 12px;
  font-size: 0.75rem;
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

.line-stats {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 10px;
  margin-bottom: 15px;
  padding: 10px;
  background-color: #f8f9fa;
  border-radius: 4px;
}

.stat-item {
  text-align: center;
}

.stat-label {
  display: block;
  font-size: 0.8rem;
  color: #666;
  margin-bottom: 2px;
}

.stat-value {
  display: block;
  font-weight: 600;
  color: #333;
  font-size: 0.9rem;
}

.line-details {
  margin-bottom: 15px;
}

.detail-item {
  font-size: 0.9rem;
  margin-bottom: 5px;
}

.schedule-type {
  color: #007bff;
  font-weight: 500;
  margin-left: 8px;
}

.start-time {
  color: #28a745;
  font-weight: 500;
  margin-left: 8px;
}

.schedule-duration {
  color: #007bff;
  font-weight: 500;
  margin-left: 8px;
}

.schedule-days {
  color: #28a745;
  font-weight: 500;
  margin-left: 8px;
}

.student-count {
  color: #666;
  margin-left: 8px;
}

.line-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.8rem;
  color: #666;
}

.line-capacity {
  font-weight: 500;
}

@media (max-width: 768px) {
  .header-content {
    flex-direction: column;
    gap: 15px;
    text-align: center;
  }
  
  .header-actions {
    justify-content: center;
  }
  
  .lines-grid {
    grid-template-columns: 1fr;
  }
  
  .line-stats {
    grid-template-columns: 1fr;
    gap: 8px;
  }
  
  .line-meta {
    flex-direction: column;
    gap: 8px;
    align-items: flex-start;
  }
}
</style>