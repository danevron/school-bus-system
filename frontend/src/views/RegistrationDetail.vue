<template>
  <AppLayout 
    :page-title="$t('registrations.detail.title')" 
    :show-action-bar="true"
    :breadcrumbs="breadcrumbItems"
  >
    <template #actions>
      <div class="action-buttons">
        <Button 
          :label="$t('common.back')" 
          icon="pi pi-arrow-left"
          severity="secondary"
          outlined
          @click="goBack"
        />
        <Button 
          :label="$t('common.refresh')" 
          icon="pi pi-refresh"
          severity="info"
          outlined
          @click="refreshData"
          :loading="loading"
        />
      </div>
    </template>

    <!-- Loading State -->
    <div v-if="loading" class="loading-container">
      <div class="loading-content">
        <i class="pi pi-spin pi-spinner loading-spinner"></i>
        <span>{{ $t('registrations.detail.loading') }}</span>
      </div>
    </div>

    <div v-else class="registration-detail">
      <!-- Registration Info Card -->
      <Card class="registration-info-card mb-4">
        <template #title>
          <div class="card-title-header">
            <h3>{{ registration?.title }}</h3>
            <Tag 
              :value="$t(`registrations.types.${registration?.type}`)"
              :severity="registration?.type === 'pickup' ? 'success' : 'info'"
            />
          </div>
        </template>
        <template #content>
          <div class="registration-info">
            <div v-if="registration?.description" class="info-item">
              <span class="info-label">{{ $t('registrations.description') }}:</span>
              <span class="info-value">{{ registration.description }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">{{ $t('registrations.stops') }}:</span>
              <span class="info-value">
                {{ registration?.stops?.length || 0 }} {{ $t('registrations.stops').toLowerCase() }}
              </span>
            </div>
            <div class="info-item">
              <span class="info-label">{{ $t('registrations.detail.totalRequests') }}:</span>
              <span class="info-value">{{ requests.length }}</span>
            </div>
          </div>
        </template>
      </Card>

      <!-- Requests DataTable -->
      <Card class="requests-table-card">
        <template #title>
          <div class="card-title-header">
            <h3>{{ $t('registrations.detail.requestsList') }}</h3>
            <div class="table-actions">
              <IconField>
                <InputIcon>
                  <i class="pi pi-search" />
                </InputIcon>
                <InputText 
                  v-model="globalFilter" 
                  :placeholder="$t('registrations.detail.searchPlaceholder')"
                  size="small"
                />
              </IconField>
            </div>
          </div>
        </template>
        <template #content>
          <!-- Empty State -->
          <div v-if="requests.length === 0" class="empty-state">
            <i class="pi pi-inbox empty-icon"></i>
            <h4>{{ $t('registrations.detail.noRequests') }}</h4>
            <p>{{ $t('registrations.detail.noRequestsDescription') }}</p>
          </div>

          <!-- Data Table -->
          <DataTable 
            v-else
            :value="filteredRequests" 
            :paginator="true" 
            :rows="10"
            :rowsPerPageOptions="[5, 10, 20, 50]"
            :loading="loading"
            sortMode="multiple"
            removableSort
            filterDisplay="row"
            :paginatorTemplate="`{CurrentPageReport} {FirstPageLink} {PrevPageLink} {PageLinks} {NextPageLink} {LastPageLink} {RowsPerPageDropdown}`"
            :currentPageReportTemplate="$t('common.paginatorTemplate')"
            class="requests-datatable"
          >
            <!-- Student Name Column -->
            <Column 
              field="student" 
              :header="$t('registrations.detail.columns.student')"
              sortable
              style="min-width: 200px"
              filterField="student"
            >
              <template #body="{ data }">
                <div class="student-info">
                  <Avatar 
                    :label="getStudentInitials(data.student)"
                    size="normal"
                    :style="{ backgroundColor: getStudentColor(data.student._id), color: 'white' }"
                    class="mr-2"
                  />
                  <div class="student-details">
                    <span class="student-name">{{ data.student.firstName }} {{ data.student.lastName }}</span>
                    <span class="student-phone">{{ data.student.phone }}</span>
                  </div>
                </div>
              </template>
              <template #filter>
                <InputText 
                  v-model="localFilters.student" 
                  type="text" 
                  :placeholder="$t('registrations.detail.filters.searchStudent')"
                  size="small"
                />
              </template>
            </Column>

            <!-- Parent Column -->
            <Column 
              field="parent" 
              :header="$t('registrations.detail.columns.parent')"
              sortable
              style="min-width: 180px"
              filterField="parent"
            >
              <template #body="{ data }">
                <div v-if="data.parent" class="parent-info">
                  <span class="parent-name">{{ data.parent.firstName }} {{ data.parent.lastName }}</span>
                  <span class="parent-email">{{ data.parent.email }}</span>
                </div>
                <span v-else class="no-parent">{{ $t('registrations.detail.noParent') }}</span>
              </template>
              <template #filter>
                <InputText 
                  v-model="localFilters.parent" 
                  type="text" 
                  :placeholder="$t('registrations.detail.filters.searchParent')"
                  size="small"
                />
              </template>
            </Column>

            <!-- Selected Stop Column -->
            <Column 
              field="selectedStop" 
              :header="$t('registrations.detail.columns.selectedStop')"
              sortable
              style="min-width: 150px"
              filterField="selectedStop"
            >
              <template #body="{ data }">
                <div v-if="data.selectedStop" class="stop-info">
                  <i class="pi pi-map-marker text-primary mr-1"></i>
                  <span>{{ data.selectedStop.name }}</span>
                </div>
                <Tag v-else :value="$t('common.notSelected')" severity="secondary" size="small" />
              </template>
              <template #filter>
                <InputText 
                  v-model="localFilters.selectedStop" 
                  type="text" 
                  :placeholder="$t('registrations.detail.filters.searchStop')"
                  size="small"
                />
              </template>
            </Column>


            <!-- Comments Column -->
            <Column 
              field="comments" 
              :header="$t('registrations.detail.columns.comments')"
              style="min-width: 200px"
              filterField="comments"
            >
              <template #body="{ data }">
                <div v-if="data.comments" class="comments-cell">
                  <span class="comments-text">{{ data.comments }}</span>
                </div>
                <span v-else class="no-comments">{{ $t('registrations.detail.noComments') }}</span>
              </template>
              <template #filter>
                <InputText 
                  v-model="localFilters.comments" 
                  type="text" 
                  :placeholder="$t('registrations.detail.filters.searchComments')"
                  size="small"
                />
              </template>
            </Column>

            <!-- Created Date Column -->
            <Column 
              field="createdAt" 
              :header="$t('registrations.detail.columns.createdAt')"
              sortable
              style="min-width: 140px"
            >
              <template #body="{ data }">
                <div class="date-info">
                  <span class="date-text">{{ formatDate(data.createdAt) }}</span>
                  <span class="time-text">{{ formatTime(data.createdAt) }}</span>
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
import { ref, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useToast } from 'primevue/usetoast'
import { FilterMatchMode } from '@primevue/core/api'
import AppLayout from '../components/AppLayout.vue'
import apiService from '../services/api.js'

export default {
  name: 'RegistrationDetail',
  components: {
    AppLayout
  },
  setup() {
    const router = useRouter()
    const route = useRoute()
    const { t } = useI18n()
    const toast = useToast()
    
    // Reactive data
    const registration = ref(null)
    const requests = ref([])
    const loading = ref(true)
    const globalFilter = ref('')
    
    // Local filter values for custom filtering
    const localFilters = ref({
      student: '',
      parent: '',
      selectedStop: '',
      comments: ''
    })

    // Table filters - empty since we'll handle filtering manually
    const filters = ref({})
    
    const registrationId = computed(() => route.params.id)
    
    // Breadcrumb
    const breadcrumbItems = computed(() => [
      { label: t('navigation.dashboard'), path: '/home' },
      { label: t('registrations.title'), path: '/registrations' },
      { label: t('registrations.detail.title') }
    ])

    // Filtered requests with custom filtering
    const filteredRequests = computed(() => {
      let filtered = [...requests.value]
      
      // Apply student filter
      if (localFilters.value.student) {
        const studentFilter = localFilters.value.student.toLowerCase()
        filtered = filtered.filter(item => {
          if (!item.student) return false
          const fullName = `${item.student.firstName || ''} ${item.student.lastName || ''}`.toLowerCase()
          const phone = (item.student.phone || '').toLowerCase()
          return fullName.includes(studentFilter) || phone.includes(studentFilter)
        })
      }
      
      // Apply parent filter
      if (localFilters.value.parent) {
        const parentFilter = localFilters.value.parent.toLowerCase()
        filtered = filtered.filter(item => {
          if (!item.parent) return false
          const fullName = `${item.parent.firstName || ''} ${item.parent.lastName || ''}`.toLowerCase()
          const email = (item.parent.email || '').toLowerCase()
          return fullName.includes(parentFilter) || email.includes(parentFilter)
        })
      }
      
      // Apply selected stop filter
      if (localFilters.value.selectedStop) {
        const stopFilter = localFilters.value.selectedStop.toLowerCase()
        filtered = filtered.filter(item => {
          if (!item.selectedStop) return false
          const stopName = (item.selectedStop.name || '').toLowerCase()
          return stopName.includes(stopFilter)
        })
      }
      
      // Apply comments filter
      if (localFilters.value.comments) {
        const commentsFilter = localFilters.value.comments.toLowerCase()
        filtered = filtered.filter(item => {
          const comments = (item.comments || '').toLowerCase()
          return comments.includes(commentsFilter)
        })
      }
      
      // Apply global filter
      if (globalFilter.value) {
        const globalFilterValue = globalFilter.value.toLowerCase()
        filtered = filtered.filter(item => {
          const studentName = `${item.student?.firstName || ''} ${item.student?.lastName || ''}`.toLowerCase()
          const studentPhone = (item.student?.phone || '').toLowerCase()
          const parentName = `${item.parent?.firstName || ''} ${item.parent?.lastName || ''}`.toLowerCase()
          const parentEmail = (item.parent?.email || '').toLowerCase()
          const stopName = (item.selectedStop?.name || '').toLowerCase()
          const comments = (item.comments || '').toLowerCase()
          
          return studentName.includes(globalFilterValue) ||
                 studentPhone.includes(globalFilterValue) ||
                 parentName.includes(globalFilterValue) ||
                 parentEmail.includes(globalFilterValue) ||
                 stopName.includes(globalFilterValue) ||
                 comments.includes(globalFilterValue)
        })
      }
      
      return filtered
    })

    
    
    // Load data
    const loadData = async () => {
      loading.value = true
      
      try {
        const [registrationResponse, requestsResponse] = await Promise.all([
          apiService.get(`/registrations/${registrationId.value}`),
          apiService.get(`/registration-requests?registrationId=${registrationId.value}`)
        ])
        registration.value = registrationResponse.data.registration
        requests.value = requestsResponse.data.requests || []
        
      } catch (error) {
        console.error('Error loading data:', error)
        toast.add({
          severity: 'error',
          summary: t('common.error'),
          detail: t('registrations.detail.loadError'),
          life: 5000
        })
        // Redirect back if registration not found
        if (error.response?.status === 404) {
          router.push('/registrations')
        }
      } finally {
        loading.value = false
      }
    }
    
    const refreshData = async () => {
      await loadData()
      toast.add({
        severity: 'success',
        summary: t('common.success'),
        detail: t('registrations.detail.refreshed'),
        life: 2000
      })
    }
    
    // Utility functions
    const getStudentInitials = (student) => {
      if (!student?.firstName || !student?.lastName) return '??'
      return `${student.firstName.charAt(0)}${student.lastName.charAt(0)}`.toUpperCase()
    }
    
    const getStudentColor = (studentId) => {
      if (!studentId || typeof studentId !== 'string') {
        return '#FF6B6B' // Default color
      }
      const colors = [
        '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', 
        '#FFEAA7', '#DDA0DD', '#98D8C8', '#F7DC6F'
      ]
      const index = studentId.charCodeAt(studentId.length - 1) % colors.length
      return colors[index]
    }
    
    
    const formatDate = (dateString) => {
      const date = new Date(dateString)
      return date.toLocaleDateString('en-GB', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric'
      })
    }
    
    const formatTime = (dateString) => {
      const date = new Date(dateString)
      return date.toLocaleTimeString('en-GB', {
        hour: '2-digit',
        minute: '2-digit'
      })
    }
    
    // Navigation
    const goBack = () => {
      router.push('/registrations')
    }
    
    onMounted(() => {
      loadData()
    })
    
    return {
      registration,
      requests,
      loading,
      globalFilter,
      filters,
      localFilters,
      filteredRequests,
      breadcrumbItems,
      refreshData,
      getStudentInitials,
      getStudentColor,
      formatDate,
      formatTime,
      goBack
    }
  }
}
</script>

<style scoped>
/* Loading State */
.loading-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 400px;
}

.loading-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
  color: var(--p-text-muted-color);
}

.loading-spinner {
  font-size: 2rem;
}

/* Action Buttons */
.action-buttons {
  display: flex;
  gap: 1rem;
}

/* Registration Info Card */
.card-title-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
  flex-wrap: wrap;
  gap: 1rem;
}

.card-title-header h3 {
  margin: 0;
  font-size: 1.25rem;
  font-weight: 600;
  color: var(--p-text-color);
}

.registration-info {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.info-item {
  display: flex;
  gap: 0.5rem;
}

.info-label {
  font-weight: 600;
  color: var(--p-text-color);
  min-width: 120px;
}

.info-value {
  color: var(--p-text-muted-color);
}

/* Table Actions */
.table-actions {
  display: flex;
  gap: 1rem;
  align-items: center;
}

/* DataTable Styling */
.requests-datatable {
  border: 1px solid var(--p-surface-border);
  border-radius: var(--p-border-radius);
}

/* Student Info */
.student-info {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.student-details {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.student-name {
  font-weight: 600;
  color: var(--p-text-color);
  font-size: 0.9rem;
}

.student-phone {
  color: var(--p-text-muted-color);
  font-size: 0.8rem;
}

/* Parent Info */
.parent-info {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.parent-name {
  font-weight: 500;
  color: var(--p-text-color);
  font-size: 0.9rem;
}

.parent-email {
  color: var(--p-text-muted-color);
  font-size: 0.8rem;
}

/* Stop Info */
.stop-info {
  display: flex;
  align-items: center;
  gap: 0.25rem;
}

/* Comments */
.comments-cell {
  max-width: 300px;
}

.comments-text {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  line-height: 1.4;
  color: var(--p-text-color);
  font-size: 0.9rem;
}

.no-comments {
  color: var(--p-text-muted-color);
  font-style: italic;
  font-size: 0.85rem;
}

/* Date Info */
.date-info {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.date-text {
  font-weight: 500;
  color: var(--p-text-color);
  font-size: 0.9rem;
}

.time-text {
  color: var(--p-text-muted-color);
  font-size: 0.8rem;
}

/* Empty State */
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
  max-width: 400px;
  margin-left: auto;
  margin-right: auto;
  line-height: 1.5;
}

/* Responsive Design */
@media (max-width: 768px) {
  .action-buttons {
    flex-direction: column;
  }
  
  .card-title-header {
    flex-direction: column;
    align-items: stretch;
  }
  
  .table-actions {
    justify-content: center;
  }
  
  .registration-info {
    gap: 0.75rem;
  }
  
  .info-item {
    flex-direction: column;
    gap: 0.25rem;
  }
  
  .info-label {
    min-width: auto;
  }
}
</style>