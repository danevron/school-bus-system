<template>
  <AppLayout 
    :page-title="$t('rides.management')"
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
        @click="handleAddRide" 
        icon="pi pi-plus"
        :label="$t('rides.addNewRide')"
        severity="success"
      />
    </template>
    
    <div class="content-wrapper">
        <!-- Filter Section -->
        <Card class="filters-card">
          <template #content>
            <div class="filters-section">
              <div class="filter-group">
                <label for="status-filter">{{ $t('rides.status') }}:</label>
                <Select 
                  id="status-filter" 
                  v-model="selectedStatus" 
                  :options="statusOptions"
                  optionLabel="label"
                  optionValue="value"
                  :placeholder="$t('rides.allStatuses')"
                />
              </div>
              <div class="filter-group">
                <label for="line-filter">{{ $t('rides.line') }}:</label>
                <InputText 
                  id="line-filter" 
                  v-model="lineSearchText"
                  :placeholder="$t('rides.searchLines')"
                />
              </div>
              <div class="filter-group">
                <label for="date-filter">{{ $t('common.date') }}:</label>
                <Calendar 
                  id="date-filter" 
                  v-model="selectedDate"
                  dateFormat="yy-mm-dd"
                />
              </div>
              <Button 
                @click="clearFilters" 
                :label="$t('common.clearFilters')"
                severity="secondary"
                outlined
              />
            </div>
          </template>
        </Card>

        <!-- Rides List Section -->
        <Card class="rides-card">
          <template #content>
            <div v-if="loading" class="loading">{{ $t('common.loadingRides') }}</div>
            
            <div v-else-if="error" class="error">
              <h3>{{ $t('common.errorLoadingRides') }}</h3>
              <p>{{ error }}</p>
              <Button @click="loadRides" :label="$t('common.retry')" />
            </div>
            
            <div v-else-if="filteredRides.length === 0" class="no-rides">
              <div class="empty-state">
                <h3>{{ $t('rides.noRidesFound') }}</h3>
                <p v-if="hasActiveFilters">{{ $t('rides.tryAdjustingFilters') }}</p>
                <p v-else>{{ $t('rides.startByCreatingFirstRide') }}</p>
                <Button 
                  @click="handleAddRide" 
                  icon="pi pi-plus"
                  :label="$t('rides.createFirstRide')"
                  severity="success"
                  size="large"
                />
              </div>
            </div>

            <DataTable 
              v-else
              :value="filteredRides" 
              :paginator="true" 
              :rows="10"
              :rowsPerPageOptions="[5, 10, 25]"
              paginatorTemplate="FirstPageLink PrevPageLink PageLinks NextPageLink LastPageLink CurrentPageReport RowsPerPageDropdown"
              :currentPageReportTemplate="$t('common.paginatorTemplate')"
              class="rides-table"
              selectionMode="single"
              @row-click="onRowClick"
            >
              <Column field="route" :header="$t('rides.route')">
                <template #body="slotProps">
                  <div class="route-cell">
                    <strong>{{ slotProps.data.route?.name || $t('rides.unnamedRoute') }}</strong>
                    <div class="route-stops">{{ slotProps.data.route?.stops?.length || 0 }} {{ $t('rides.stops') }}</div>
                  </div>
                </template>
              </Column>
              
              <Column field="date" :header="$t('common.date')">
                <template #body="slotProps">
                  {{ formatDate(slotProps.data.date) }}
                </template>
              </Column>
              
              <Column field="startTime" :header="$t('rides.startTime')">
                <template #body="slotProps">
                  {{ formatTime(slotProps.data.startTime) }}
                </template>
              </Column>
              
              <Column field="driver" :header="$t('rides.driver')">
                <template #body="slotProps">
                  {{ getDriverName(slotProps.data.driver) }}
                </template>
              </Column>
              
              <Column field="seats" :header="$t('rides.seats')" class="seats-column">
                <template #body="slotProps">
                  <span class="seats-info">{{ slotProps.data.availableSeats }}/{{ slotProps.data.maxCapacity }}</span>
                </template>
              </Column>
              
              <Column field="status" :header="$t('rides.status')">
                <template #body="slotProps">
                  <Tag :value="getStatusLabel(slotProps.data.status)" :severity="getStatusTagSeverity(slotProps.data.status)" />
                </template>
              </Column>
              
              <Column field="line" :header="$t('rides.line')">
                <template #body="slotProps">
                  <Button 
                    v-if="slotProps.data.lineId"
                    @click="viewLine(slotProps.data.lineId._id)"
                    :label="slotProps.data.lineId.name"
                    link
                    :title="$t('rides.viewLine', { name: slotProps.data.lineId.name })"
                  />
                  <span v-else class="no-line">-</span>
                </template>
              </Column>
              
              <Column :header="$t('common.actions')" class="actions-column">
                <template #body="slotProps">
                  <div class="action-buttons">
                    <Button
                      v-if="slotProps.data.status === 'scheduled'"
                      rounded
                      variant="text"
                      @click="startRide(slotProps.data._id)"
                      icon="pi pi-play"
                      severity="success"
                      size="small"
                      :title="$t('rides.startRide')"
                    />
                    <Button 
                      v-if="slotProps.data.status === 'in_progress'" 
                      rounded
                      variant="text"
                      @click="endRide(slotProps.data._id)"
                      icon="pi pi-stop"
                      severity="info"
                      size="small"
                      :title="$t('rides.endRide')"
                    />
                    <Button 
                      v-if="['scheduled', 'in_progress'].includes(slotProps.data.status)" 
                      rounded
                      variant="text"
                      @click="cancelRide(slotProps.data._id)"
                      icon="pi pi-times"
                      severity="danger"
                      size="small"
                      :title="$t('rides.cancelRide')"
                    />
                  </div>
                </template>
              </Column>
            </DataTable>
          </template>
        </Card>
      </div>
    </AppLayout>
</template>

<script>
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import apiService from '../services/api.js'
import AppLayout from '../components/AppLayout.vue'

export default {
  name: 'RideList',
  components: {
    AppLayout
  },
  setup() {
    const router = useRouter()
    const { t } = useI18n()
    const rides = ref([])
    const loading = ref(true)
    const error = ref('')
    const selectedStatus = ref('')
    const selectedDate = ref('')
    const lineSearchText = ref('')
    
    const breadcrumbs = computed(() => [
      { label: t('navigation.dashboard'), path: '/home' },
      { label: t('rides.management') }
    ])
    
    const statusOptions = computed(() => [
      { label: t('rides.allStatuses'), value: '' },
      { label: t('rides.statusScheduled'), value: 'scheduled' },
      { label: t('rides.statusInProgress'), value: 'in_progress' },
      { label: t('rides.statusCompleted'), value: 'completed' },
      { label: t('rides.statusCancelled'), value: 'cancelled' }
    ])

    const filteredRides = computed(() => {
      let filtered = [...rides.value]
      
      if (selectedStatus.value) {
        filtered = filtered.filter(ride => ride.status === selectedStatus.value)
      }
      
      if (lineSearchText.value.trim()) {
        const searchTerm = lineSearchText.value.toLowerCase().trim()
        filtered = filtered.filter(ride => {
          const lineName = ride.lineId?.name || ''
          return lineName.toLowerCase().includes(searchTerm)
        })
      }
      
      if (selectedDate.value) {
        filtered = filtered.filter(ride => {
          const rideDate = new Date(ride.date).toISOString().split('T')[0]
          // Convert selectedDate to YYYY-MM-DD format avoiding timezone issues
          const year = selectedDate.value.getFullYear()
          const month = String(selectedDate.value.getMonth() + 1).padStart(2, '0')
          const day = String(selectedDate.value.getDate()).padStart(2, '0')
          const filterDate = `${year}-${month}-${day}`
          return rideDate === filterDate
        })
      }
      
      // Sort by date (newest first)
      return filtered.sort((a, b) => new Date(b.date) - new Date(a.date))
    })

    const hasActiveFilters = computed(() => {
      return selectedStatus.value || selectedDate.value || lineSearchText.value.trim()
    })

    const loadRides = async () => {
      try {
        loading.value = true
        error.value = ''
        const response = await apiService.get('/rides')
        rides.value = response.data.rides || []
      } catch (err) {
        console.error('Error loading rides:', err)
        error.value = err.response?.data?.message || t('common.failedToLoadRides')
      } finally {
        loading.value = false
      }
    }

    const clearFilters = () => {
      selectedStatus.value = ''
      selectedDate.value = ''
      lineSearchText.value = ''
    }

    const formatDate = (dateString) => {
      if (!dateString) return t('common.notSet')
      return new Date(dateString).toLocaleDateString()
    }

    const formatTime = (timeString) => {
      if (!timeString) return t('common.notSet')
      return new Date(timeString).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    }

    const getStatusTagSeverity = (status) => {
      const severities = {
        'scheduled': 'info',
        'in_progress': 'warn',
        'completed': 'success',
        'cancelled': 'danger'
      }
      return severities[status] || 'secondary'
    }

    const getStatusLabel = (status) => {
      const labels = {
        'scheduled': t('rides.statusScheduled'),
        'in_progress': t('rides.statusInProgress'),
        'completed': t('rides.statusCompleted'),
        'cancelled': t('rides.statusCancelled')
      }
      return labels[status] || status
    }

    const getDriverName = (driver) => {
      if (typeof driver === 'object' && driver) {
        return `${driver.firstName} ${driver.lastName}`
      }
      return t('common.loading')
    }


    const goBack = () => {
      router.push('/home')
    }

    const handleAddRide = () => {
      // TODO: Navigate to ride creation page when implemented
      alert(t('rides.rideCreationNotImplemented'))
    }

    const viewRide = (rideId) => {
      router.push(`/rides/${rideId}`)
    }

    const startRide = async (rideId) => {
      try {
        await apiService.post(`/rides/${rideId}/start`)
        await loadRides() // Reload data
      } catch (err) {
        alert(t('rides.errorStartingRide') + ': ' + (err.response?.data?.message || err.message))
      }
    }

    const endRide = async (rideId) => {
      try {
        await apiService.post(`/rides/${rideId}/end`)
        await loadRides() // Reload data
      } catch (err) {
        alert(t('rides.errorEndingRide') + ': ' + (err.response?.data?.message || err.message))
      }
    }

    const cancelRide = async (rideId) => {
      if (!confirm(t('rides.confirmCancelRide'))) return
      
      try {
        await apiService.delete(`/rides/${rideId}`)
        await loadRides() // Reload data
      } catch (err) {
        alert(t('rides.errorCancellingRide') + ': ' + (err.response?.data?.message || err.message))
      }
    }


    const viewLine = (lineId) => {
      router.push(`/lines/${lineId}`)
    }

    const onRowClick = (event) => {
      viewRide(event.data._id)
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
      lineSearchText,
      statusOptions,
      filteredRides,
      hasActiveFilters,
      breadcrumbs,
      loadRides,
      clearFilters,
      formatDate,
      formatTime,
      getStatusTagSeverity,
      getStatusLabel,
      getDriverName,
      goBack,
      handleAddRide,
      viewRide,
      startRide,
      endRide,
      cancelRide,
      viewLine,
      onRowClick
    }
  }
}
</script>

<style scoped>
/* Ride list specific styles */

.content-wrapper {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.filters-card {
  margin-bottom: 0;
}


.filter-group {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.filter-group label {
  font-weight: 500;
  color: var(--p-text-color);
}

.filters-section {
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
  color: var(--p-text-color);
}

.filters-section {
  display: flex;
  gap: 20px;
  align-items: end;
}

.loading, .error {
  text-align: center;
  padding: 40px;
}

.error {
  color: var(--p-red-500);
}

.no-rides {
  text-align: center;
  padding: 60px 20px;
}

.empty-state h3 {
  color: var(--p-text-color);
  margin-bottom: 10px;
}

.empty-state p {
  color: var(--p-text-muted-color);
  margin-bottom: 20px;
}

.route-cell strong {
  display: block;
  margin-bottom: 4px;
  color: var(--p-text-color);
}

.route-stops {
  font-size: 0.875rem;
  color: var(--p-text-muted-color);
}

.seats-info {
  font-weight: 500;
  color: var(--p-text-color);
}

.no-line {
  color: var(--p-text-muted-color);
  font-style: italic;
}

.action-buttons {
  display: flex;
  gap: 4px;
  flex-wrap: wrap;
}

.rides-table :deep(.p-datatable-tbody) > tr {
  cursor: pointer;
}

.rides-table :deep(.p-datatable-tbody) > tr:hover {
  background-color: var(--p-surface-hover) !important;
}

.table-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.table-title {
  margin: 0;
  color: var(--p-text-color);
  font-size: 1.25rem;
  font-weight: 600;
}


@media (max-width: 768px) {
  .filters-section {
    flex-direction: column;
    align-items: stretch;
  }
  
  .action-buttons {
    flex-direction: column;
    gap: 2px;
  }
}
</style>