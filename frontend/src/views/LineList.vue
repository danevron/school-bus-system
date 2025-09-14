<template>
  <AppLayout 
    :page-title="$t('lines.title')"
    :breadcrumbs="breadcrumbs"
  >
    <template #actions>
      <Button 
        @click="goBack" 
        icon="pi pi-arrow-left"
        :label="$t('navigation.backToDashboard')"
        severity="secondary"
        outlined
      />
      <Button 
        @click="handleAddLine" 
        icon="pi pi-plus"
        :label="$t('lines.addNewLine')"
        severity="success"
      />
    </template>
    
    <div class="content-wrapper">
        <!-- Lines List Section -->
        <Card class="lines-section">
          <template #content>
            <div v-if="loading" class="loading">{{ $t('common.loading') }}</div>
            
            <div v-else-if="lines.length === 0" class="no-lines">
              <div class="empty-state">
                <h3>{{ $t('lines.noLinesFound') }}</h3>
                <p>{{ $t('lines.startCreateFirst') }}</p>
                <Button 
                  @click="handleAddLine" 
                  icon="pi pi-plus"
                  :label="$t('lines.createFirstLine')"
                  severity="success"
                  size="large"
                />
              </div>
            </div>

            <div v-else class="lines-grid">
              <Card 
                v-for="line in lines" 
                :key="line._id" 
                class="line-card"
                @click="viewLine(line._id)"
              >
                <template #header>
                  <div class="line-header">
                    <h3 class="line-name">{{ line.name }}</h3>
                    <div class="status-container">
                      <i 
                        :class="line.isActive ? 'pi pi-check-circle' : 'pi pi-times-circle'"
                        :style="{ color: line.isActive ? 'var(--p-green-500)' : 'var(--p-red-500)' }"
                      ></i>
                      <span class="status-text" :class="line.isActive ? 'active' : 'inactive'">
                        {{ line.isActive ? $t('lines.active') : $t('lines.inactive') }}
                      </span>
                    </div>
                  </div>
                </template>
                
                <template #content>
                  <div class="line-info">
                    <div class="line-stats">
                      <div class="stat-item">
                        <span class="stat-label">{{ $t('lines.route') }}:</span>
                        <span class="stat-value">{{ line.route?.name || $t('lines.noRoute') }}</span>
                      </div>
                      <div class="stat-item">
                        <span class="stat-label">{{ $t('lines.vehicle') }}:</span>
                        <span class="stat-value">{{ line.vehicle?.licensePlate || $t('lines.noVehicle') }}</span>
                      </div>
                      <div class="stat-item">
                        <span class="stat-label">{{ $t('lines.driver') }}:</span>
                        <span class="stat-value">{{ getDriverName(line.driver) }}</span>
                      </div>
                    </div>

                    <div class="line-details">
                      <div class="detail-item">
                        <i class="pi pi-clock detail-icon"></i>
                        <strong>{{ $t('lines.startTime') }}:</strong>
                        <span class="start-time">{{ formatTime(line.rideStartTime) }}</span>
                      </div>
                      <div class="detail-item">
                        <i class="pi pi-calendar detail-icon"></i>
                        <strong>{{ $t('lines.duration') }}:</strong>
                        <span class="schedule-duration">{{ formatScheduleDuration(line.schedule) }}</span>
                      </div>
                      <div class="detail-item">
                        <i class="pi pi-calendar-times detail-icon"></i>
                        <strong>{{ $t('lines.operatingDays') }}:</strong>
                        <span class="schedule-days">{{ formatScheduleDays(line.schedule) }}</span>
                      </div>
                      <div class="detail-item">
                        <i class="pi pi-users detail-icon"></i>
                        <strong>{{ $t('lines.students') }}:</strong>
                        <span class="student-count">{{ line.students?.length || 0 }} {{ $t('lines.assigned') }}</span>
                      </div>
                    </div>
                  </div>
                </template>
                
                <template #footer>
                  <div class="line-meta">
                    <div class="line-dates">
                      <i class="pi pi-info-circle"></i>
                      {{ $t('lines.created') }}: {{ formatDate(line.createdAt) }}
                    </div>
                    <div class="line-capacity" v-if="line.vehicle">
                      <i class="pi pi-users"></i>
                      {{ $t('lines.capacity') }}: {{ line.students?.length || 0 }}/{{ line.vehicle.capacity }}
                    </div>
                  </div>
                </template>
              </Card>
            </div>
          </template>
        </Card>
      </div>
    </AppLayout>
</template>

<script>
import { ref, inject, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import apiService from '../services/api'
import AppLayout from '../components/AppLayout.vue'

export default {
  name: 'LineList',
  components: {
    AppLayout
  },
  setup() {
    const authStore = inject('authStore')
    const router = useRouter()
    const { t } = useI18n()
    
    const breadcrumbs = ref([
      { label: t('navigation.dashboard'), path: '/home' },
      { label: t('lines.title') }
    ])
    
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
      if (!timeString) return t('lines.notSet')
      
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
      if (!driver) return t('lines.noDriver')
      if (typeof driver === 'string') return t('lines.driverAssigned')
      return `${driver.firstName || ''} ${driver.lastName || ''}`.trim() || t('lines.driverAssigned')
    }
    
    const formatScheduleDuration = (schedule) => {
      if (!schedule || !schedule.startDate) {
        return t('lines.noScheduleSet')
      }
      
      const start = new Date(schedule.startDate)
      const end = schedule.endDate ? new Date(schedule.endDate) : null
      
      if (!end) {
        return `${start.toLocaleDateString()}`
      }
      
      const diffTime = Math.abs(end - start)
      const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24)) + 1
      
      const startStr = start.toLocaleDateString()
      const endStr = end.toLocaleDateString()
      
      if (diffDays === 1) {
        return `${startStr} (1 ${t('common.day')})`
      } else if (diffDays < 30) {
        return `${startStr} - ${endStr} (${diffDays} ${t('lines.days')})`
      } else if (diffDays < 365) {
        const weeks = Math.floor(diffDays / 7)
        return `${startStr} - ${endStr} (${weeks} ${weeks > 1 ? t('lines.weeks') : t('common.week')})`
      } else {
        const years = Math.floor(diffDays / 365)
        return `${startStr} - ${endStr} (${years} ${years > 1 ? t('lines.years') : t('common.year')})`
      }
    }
    
    const formatScheduleDays = (schedule) => {
      if (!schedule || !schedule.daysOfWeek || schedule.daysOfWeek.length === 0) {
        return t('lines.noDaysSelected')
      }
      
      const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
      const selectedDays = schedule.daysOfWeek
        .sort((a, b) => a - b) // Sort to ensure correct order
        .map(dayNum => dayNames[dayNum])
      
      // Check for common patterns
      if (selectedDays.length === 7) {
        return t('lines.everyDay')
      } else if (selectedDays.length === 5 && 
                 schedule.daysOfWeek.includes(0) && 
                 schedule.daysOfWeek.includes(1) && 
                 schedule.daysOfWeek.includes(2) && 
                 schedule.daysOfWeek.includes(3) && 
                 schedule.daysOfWeek.includes(4)) {
        return t('lines.weekdays')
      } else if (selectedDays.length === 2 && 
                 schedule.daysOfWeek.includes(0) && 
                 schedule.daysOfWeek.includes(6)) {
        return t('lines.weekends')
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
      breadcrumbs,
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
/* Line list specific styles */

.content-wrapper {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.loading {
  text-align: center;
  color: var(--p-text-muted-color);
  padding: 40px;
  font-size: 1.1rem;
}

.no-lines {
  text-align: center;
  padding: 60px 20px;
}

.empty-state h3 {
  color: var(--p-text-color);
  margin-bottom: 10px;
}

.empty-state p {
  color: var(--p-text-muted-color);
  margin-bottom: 30px;
}

.lines-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(400px, 1fr));
  gap: 20px;
}

.line-card {
  transition: all 0.2s;
  cursor: pointer;
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
  padding: 1.25rem 1.25rem 0 1.25rem;
}

.line-name {
  margin: 0;
  color: var(--p-text-color);
  font-size: 1.25rem;
  font-weight: 600;
}

.status-container {
  display: flex;
  align-items: center;
  gap: 6px;
}

.status-text {
  font-size: 0.875rem;
  font-weight: 500;
  text-transform: uppercase;
}

.status-text.active {
  color: var(--p-green-500);
}

.status-text.inactive {
  color: var(--p-red-500);
}

.line-stats {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 10px;
  margin-bottom: 15px;
  padding: 10px;
  background-color: var(--p-surface-50);
  border-radius: var(--p-border-radius);
}

.stat-item {
  text-align: center;
}

.stat-label {
  display: block;
  font-size: 0.8rem;
  color: var(--p-text-muted-color);
  margin-bottom: 2px;
}

.stat-value {
  display: block;
  font-weight: 600;
  color: var(--p-text-color);
  font-size: 0.9rem;
}

.line-details {
  margin-bottom: 15px;
}

.detail-item {
  display: flex;
  align-items: center;
  font-size: 0.9rem;
  margin-bottom: 8px;
  gap: 8px;
}

.detail-icon {
  color: var(--p-primary-color);
  font-size: 0.875rem;
}

.start-time {
  color: var(--p-green-500);
  font-weight: 500;
}

.schedule-duration {
  color: var(--p-primary-color);
  font-weight: 500;
}

.schedule-days {
  color: var(--p-green-500);
  font-weight: 500;
}

.student-count {
  color: var(--p-text-muted-color);
  font-weight: 500;
}

.line-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.8rem;
  color: var(--p-text-muted-color);
}

.line-dates,
.line-capacity {
  display: flex;
  align-items: center;
  gap: 4px;
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