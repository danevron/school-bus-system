<template>
  <AppLayout 
    :page-title="$t('registrations.title')" 
    :show-action-bar="true"
    :breadcrumbs="breadcrumbItems"
  >
    <template #actions>
      <Button 
        :label="$t('registrations.addNew')" 
        icon="pi pi-plus"
        severity="success"
        @click="goToCreateRegistration"
      />
    </template>

    <Card>
      <template #content>
        <!-- Filters Section -->
        <div class="filters-section mb-4">
          <div class="filter-controls">
            <div class="filter-row">
              <div class="filter-group">
                <label for="globalFilter" class="filter-label">{{ $t('common.search') }}</label>
                <IconField>
                  <InputIcon>
                    <i class="pi pi-search" />
                  </InputIcon>
                  <InputText 
                    id="globalFilter"
                    v-model="filters.global.value" 
                    :placeholder="$t('registrations.searchPlaceholder')"
                    fluid
                  />
                </IconField>
              </div>
              
              <div class="filter-group">
                <label for="statusFilter" class="filter-label">{{ $t('common.status') }}</label>
                <Select 
                  id="statusFilter"
                  v-model="filters.status.value" 
                  :options="statusOptions"
                  option-label="label"
                  option-value="value"
                  :placeholder="$t('registrations.allStatus')"
                  show-clear
                  fluid
                />
              </div>
              
              <div class="filter-group">
                <label for="typeFilter" class="filter-label">{{ $t('registrations.type') }}</label>
                <Select 
                  id="typeFilter"
                  v-model="filters.type.value" 
                  :options="typeOptions"
                  option-label="label"
                  option-value="value"
                  :placeholder="$t('registrations.allTypes')"
                  show-clear
                  fluid
                />
              </div>
            </div>
            
            <div class="filter-actions">
              <Button 
                :label="$t('common.clearFilters')"
                icon="pi pi-filter-slash"
                text
                @click="clearFilters"
              />
            </div>
          </div>
        </div>

        <!-- Data Table -->
        <DataTable 
          :value="registrations" 
          :loading="loading"
          :filters="filters"
          filter-display="row"
          paginator 
          :rows="10"
          :rows-per-page-options="[5, 10, 20, 50]"
          paginator-template="RowsPerPageDropdown FirstPageLink PrevPageLink CurrentPageReport NextPageLink LastPageLink"
          :current-page-report-template="$t('common.paginatorTemplate')"
          selection-mode="single"
          @row-select="onRowSelect"
          responsive-layout="scroll"
          class="registrations-table"
        >
          <template #empty>
            <div class="empty-state">
              <i class="pi pi-clipboard-text empty-icon"></i>
              <h4>{{ $t('registrations.noRegistrations') }}</h4>
              <p>{{ $t('registrations.noRegistrationsDescription') }}</p>
              <Button 
                :label="$t('registrations.createFirst')" 
                icon="pi pi-plus"
                severity="success"
                @click="goToCreateRegistration"
              />
            </div>
          </template>
          
          <template #loading>
            <div class="loading-state">
              <i class="pi pi-spin pi-spinner loading-icon"></i>
              <span>{{ $t('registrations.loading') }}</span>
            </div>
          </template>

          <Column 
            field="title" 
            :header="$t('registrations.title')"
            sortable
            class="title-column"
          >
            <template #body="{ data }">
              <div class="registration-title">
                <strong>{{ data.title }}</strong>
                <div class="registration-meta">
                  {{ data.description }}
                </div>
              </div>
            </template>
          </Column>

          <Column 
            field="type" 
            :header="$t('registrations.type')"
            sortable
            class="type-column"
          >
            <template #body="{ data }">
              <p>{{ $t(`registrations.types.${data.type}`) }}</p>
            </template>
          </Column>

          <Column 
            field="status" 
            :header="$t('common.status')"
            sortable
            class="status-column"
          >
            <template #body="{ data }">
              <Tag 
                :value="$t(`registrations.statuses.${data.status}`)"
                :severity="getStatusSeverity(data.status)"
              />
            </template>
          </Column>

          <Column 
            field="stopsCount" 
            :header="$t('registrations.stops')"
            sortable
            class="stops-column"
          >
            <template #body="{ data }">
              <div class="stops-info">
                <i class="pi pi-map-marker"></i>
                <span>{{ data.stops?.length || 0 }} {{ $t('registrations.stops').toLowerCase() }}</span>
              </div>
            </template>
          </Column>

          <Column 
            field="createdAt" 
            :header="$t('common.created')"
            sortable
            class="date-column"
          >
            <template #body="{ data }">
              <div class="date-info">
                <div class="date-text">{{ formatDate(data.createdAt) }}</div>
                <div class="time-text">{{ formatTime(data.createdAt) }}</div>
              </div>
            </template>
          </Column>

          <Column class="actions-column">
            <template #body="{ data }">
              <div class="action-buttons">
                <Button 
                  icon="pi pi-eye"
                  severity="info"
                  text
                  rounded
                  @click="viewRegistration(data)"
                  v-tooltip="$t('common.view')"
                />
                <Button 
                  icon="pi pi-pencil"
                  severity="secondary"
                  text
                  rounded
                  @click="editRegistration(data)"
                  v-tooltip="$t('common.edit')"
                  :disabled="data.status !== 'draft'"
                />
                <Button 
                  v-if="data.status === 'draft'"
                  icon="pi pi-play"
                  severity="success"
                  text
                  rounded
                  @click="showActivateDialog(data)"
                  v-tooltip="$t('registrations.activate')"
                />
              </div>
            </template>
          </Column>
        </DataTable>
      </template>
    </Card>
  </AppLayout>

  <!-- Activate Registration Dialog -->
  <Dialog 
    v-model:visible="activateDialogVisible"
    :header="$t('registrations.activateDialog.title')"
    modal
    :style="{ width: '450px' }"
    :breakpoints="{ '960px': '75vw', '641px': '90vw' }"
  >
    <div class="activate-dialog-content">
      <div class="dialog-icon">
        <i class="pi pi-exclamation-triangle"></i>
      </div>
      <div class="dialog-message">
        <p>{{ $t('registrations.activateDialog.message') }}</p>
        <p class="warning-text">{{ $t('registrations.activateDialog.warning') }}</p>
      </div>
    </div>
    
    <template #footer>
      <div class="dialog-footer">
        <Button 
          :label="$t('common.cancel')" 
          icon="pi pi-times"
          severity="secondary"
          outlined
          @click="hideActivateDialog"
        />
        <Button 
          :label="$t('registrations.activateDialog.confirm')" 
          icon="pi pi-play"
          severity="success"
          @click="confirmActivateRegistration"
          :loading="activating"
        />
      </div>
    </template>
  </Dialog>
</template>

<script>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { FilterMatchMode } from '@primevue/core/api'
import AppLayout from '../components/AppLayout.vue'
import apiService from '../services/api.js'

export default {
  name: 'Registrations',
  components: {
    AppLayout
  },
  setup() {
    const router = useRouter()
    const { t } = useI18n()
    
    // Reactive data
    const registrations = ref([])
    const loading = ref(false)
    const activateDialogVisible = ref(false)
    const selectedRegistration = ref(null)
    const activating = ref(false)
    
    // Filters
    const filters = ref({
      global: { value: null, matchMode: FilterMatchMode.CONTAINS },
      status: { value: null, matchMode: FilterMatchMode.EQUALS },
      type: { value: null, matchMode: FilterMatchMode.EQUALS }
    })
    
    // Filter options
    const statusOptions = computed(() => [
      { label: t('registrations.statuses.draft'), value: 'draft' },
      { label: t('registrations.statuses.active'), value: 'active' },
      { label: t('registrations.statuses.closed'), value: 'closed' }
    ])
    
    const typeOptions = computed(() => [
      { label: t('registrations.types.pickup'), value: 'pickup' },
      { label: t('registrations.types.return'), value: 'return' }
    ])
    
    // Breadcrumb
    const breadcrumbItems = computed(() => [
      { label: t('navigation.dashboard'), path: '/home' },
      { label: t('registrations.title') }
    ])
    
    // Methods
    const loadRegistrations = async () => {
      loading.value = true
      try {
        const response = await apiService.get('/registrations')
        registrations.value = response.data.registrations || []
      } catch (error) {
        console.error('Error loading registrations:', error)
        // Add mock data for development
        registrations.value = [
          {
            _id: '1',
            title: 'Morning Pickup Registration',
            description: 'Registration for morning pickup routes',
            type: 'pickup',
            status: 'active',
            stops: [
              { address: '123 Main St', coordinates: { lat: 32.0853, lng: 34.7818 } },
              { address: '456 Oak Ave', coordinates: { lat: 32.0854, lng: 34.7819 } }
            ],
            createdAt: new Date('2024-01-15T08:00:00'),
            updatedAt: new Date('2024-01-15T08:00:00')
          },
          {
            _id: '2',
            title: 'Afternoon Return Registration',
            description: 'Registration for afternoon return routes',
            type: 'return',
            status: 'draft',
            stops: [
              { address: '789 Pine St', coordinates: { lat: 32.0855, lng: 34.7820 } }
            ],
            createdAt: new Date('2024-01-14T14:30:00'),
            updatedAt: new Date('2024-01-14T14:30:00')
          },
          {
            _id: '3',
            title: 'Special Event Transportation',
            description: 'Transportation for special school events',
            type: 'pickup',
            status: 'closed',
            stops: [],
            createdAt: new Date('2024-01-10T10:15:00'),
            updatedAt: new Date('2024-01-12T16:45:00')
          }
        ]
      } finally {
        loading.value = false
      }
    }
    
    const clearFilters = () => {
      filters.value.global.value = null
      filters.value.status.value = null
      filters.value.type.value = null
    }
    
    const getStatusSeverity = (status) => {
      switch (status) {
        case 'active': return 'success'
        case 'draft': return 'warning'
        case 'closed': return 'danger'
        default: return 'info'
      }
    }
    
    const formatDate = (date) => {
      return new Date(date).toLocaleDateString()
    }
    
    const formatTime = (date) => {
      return new Date(date).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    }
    
    // Navigation methods
    const goToCreateRegistration = () => {
      router.push('/registrations/create')
    }
    
    const viewRegistration = (registration) => {
      router.push(`/registrations/${registration._id}/detail`)
    }
    
    const editRegistration = (registration) => {
      router.push(`/registrations/${registration._id}/edit`)
    }
    
    const onRowSelect = (event) => {
      viewRegistration(event.data)
    }
    
    // Activate registration methods
    const showActivateDialog = (registration) => {
      selectedRegistration.value = registration
      activateDialogVisible.value = true
    }
    
    const hideActivateDialog = () => {
      activateDialogVisible.value = false
      selectedRegistration.value = null
    }
    
    const confirmActivateRegistration = async () => {
      if (!selectedRegistration.value) return
      
      activating.value = true
      
      try {
        await apiService.post(`/registrations/${selectedRegistration.value._id}/activate`)
        
        // Update the registration in the list
        const index = registrations.value.findIndex(r => r._id === selectedRegistration.value._id)
        if (index !== -1) {
          registrations.value[index].status = 'active'
          registrations.value[index].activatedAt = new Date()
        }
        
        hideActivateDialog()
        
      } catch (error) {
        console.error('Error activating registration:', error)
        // Handle error (could add toast notification here)
      } finally {
        activating.value = false
      }
    }
    
    onMounted(() => {
      loadRegistrations()
    })
    
    return {
      registrations,
      loading,
      filters,
      statusOptions,
      typeOptions,
      breadcrumbItems,
      loadRegistrations,
      clearFilters,
      getStatusSeverity,
      formatDate,
      formatTime,
      goToCreateRegistration,
      viewRegistration,
      editRegistration,
      onRowSelect,
      activateDialogVisible,
      selectedRegistration,
      activating,
      showActivateDialog,
      hideActivateDialog,
      confirmActivateRegistration
    }
  }
}
</script>

<style scoped>
/* Filters Section */
.filters-section {
  background-color: var(--p-surface-50);
  padding: 1.5rem;
  border-radius: var(--p-border-radius);
  border: 1px solid var(--p-surface-border);
}

.filter-controls {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.filter-row {
  display: grid;
  grid-template-columns: 2fr 1fr 1fr;
  gap: 1rem;
  align-items: end;
}

@media (max-width: 768px) {
  .filter-row {
    grid-template-columns: 1fr;
  }
}

.filter-group {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.filter-label {
  font-weight: 600;
  color: var(--p-text-color);
  font-size: 0.875rem;
}

.filter-actions {
  display: flex;
  justify-content: flex-end;
}

/* Table Styles */
.registrations-table {
  margin-top: 1rem;
}

.title-column {
  min-width: 250px;
}

.registration-title strong {
  color: var(--p-text-color);
  font-size: 1rem;
}

.registration-meta {
  color: var(--p-text-muted-color);
  font-size: 0.875rem;
  margin-top: 0.25rem;
}

.type-column,
.status-column {
  width: 120px;
  text-align: center;
}

.stops-column {
  width: 100px;
}

.stops-info {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  color: var(--p-text-muted-color);
  font-size: 0.875rem;
}

.date-column {
  width: 150px;
}

.date-info {
  display: flex;
  flex-direction: column;
  gap: 0.125rem;
}

.date-text {
  font-weight: 600;
  color: var(--p-text-color);
  font-size: 0.875rem;
}

.time-text {
  color: var(--p-text-muted-color);
  font-size: 0.75rem;
}

.actions-column {
  width: 100px;
  text-align: center;
}

.action-buttons {
  display: flex;
  justify-content: center;
  gap: 0.25rem;
}

/* Empty and Loading States */
.empty-state {
  text-align: center;
  padding: 3rem 1rem;
}

.empty-icon {
  font-size: 3rem;
  color: var(--p-text-muted-color);
  margin-bottom: 1rem;
}

.empty-state h4 {
  color: var(--p-text-color);
  margin-bottom: 1rem;
  font-size: 1.25rem;
}

.empty-state p {
  color: var(--p-text-muted-color);
  margin-bottom: 2rem;
  max-width: 400px;
  margin-left: auto;
  margin-right: auto;
}

.loading-state {
  text-align: center;
  padding: 2rem;
  color: var(--p-text-muted-color);
}

.loading-icon {
  font-size: 2rem;
  margin-bottom: 1rem;
}

/* Activate Dialog */
.activate-dialog-content {
  display: flex;
  gap: 1rem;
  margin-bottom: 1.5rem;
}

.dialog-icon {
  flex-shrink: 0;
}

.dialog-icon i {
  font-size: 2rem;
  color: var(--p-orange-500);
}

.dialog-message {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.dialog-message p {
  margin: 0;
  line-height: 1.5;
}

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 0.75rem;
}
</style>