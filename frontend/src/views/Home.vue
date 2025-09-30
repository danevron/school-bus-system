<template>
  <AppLayout 
    :page-title="$t('navigation.dashboard')" 
    :show-action-bar="false"
  >
      <Card class="dashboard">
        <template #content>
          <!-- Universal Welcome Card -->
          <Card class="welcome-card mb-4">
            <template #header>
              <div class="welcome-header">
                <Avatar 
                  v-if="userRole === 'admin'"
                  icon="pi pi-cog" 
                  size="large" 
                  severity="warning"
                />
                <Avatar 
                  v-else-if="userRole === 'parent'"
                  icon="pi pi-heart" 
                  size="large" 
                  severity="info"
                />
                <Avatar 
                  v-else
                  icon="pi pi-user" 
                  size="large" 
                  severity="secondary"
                />
                <div class="welcome-text">
                  <h2>{{ $t('home.parent.welcome.greeting', { name: userName }) }}</h2>
                  <p>{{ $t('home.welcome') }}</p>
                </div>
              </div>
            </template>
          </Card>

          <div class="role-specific-content">
            <!-- Admin View -->
            <div v-if="userRole === 'admin'" class="admin-dashboard">

              <!-- Management Actions -->
              <div class="admin-actions-grid">
                <Card class="action-card">
                  <template #content>
                    <div class="action-content">
                      <Avatar 
                        icon="pi pi-directions" 
                        size="large" 
                        severity="primary"
                        class="action-avatar"
                      />
                      <h4>{{ $t('home.admin.linesManagement.title') }}</h4>
                      <p>{{ $t('home.admin.linesManagement.description') }}</p>
                      <Button 
                        @click="goToLineManagement"
                        :label="$t('home.admin.linesManagement.button')"
                        severity="primary"
                        class="action-button"
                      />
                    </div>
                  </template>
                </Card>
                
                <Card class="action-card">
                  <template #content>
                    <div class="action-content">
                      <Avatar 
                        icon="pi pi-users" 
                        size="large" 
                        severity="success"
                        class="action-avatar"
                      />
                      <h4>{{ $t('home.admin.usersManagement.title') }}</h4>
                      <p>{{ $t('home.admin.usersManagement.description') }}</p>
                      <Button 
                        @click="goToUserManagement"
                        :label="$t('home.admin.usersManagement.button')"
                        severity="success"
                        class="action-button"
                      />
                    </div>
                  </template>
                </Card>
                
                <Card class="action-card">
                  <template #content>
                    <div class="action-content">
                      <Avatar 
                        icon="pi pi-car" 
                        size="large" 
                        severity="info"
                        class="action-avatar"
                      />
                      <h4>{{ $t('home.admin.rideManagement.title') }}</h4>
                      <p>{{ $t('home.admin.rideManagement.description') }}</p>
                      <Button 
                        @click="goToRideManagement"
                        :label="$t('home.admin.rideManagement.button')"
                        severity="info"
                        class="action-button"
                      />
                    </div>
                  </template>
                </Card>
                
                <Card class="action-card">
                  <template #content>
                    <div class="action-content">
                      <Avatar 
                        icon="pi pi-address-book" 
                        size="large" 
                        severity="warning"
                        class="action-avatar"
                      />
                      <h4>{{ $t('home.admin.registrationManagement.title') }}</h4>
                      <p>{{ $t('home.admin.registrationManagement.description') }}</p>
                      <Button 
                        @click="goToRegistrationManagement"
                        :label="$t('home.admin.registrationManagement.button')"
                        severity="warning"
                        class="action-button"
                      />
                    </div>
                  </template>
                </Card>
              </div>
            </div>

            <!-- Parent View -->
            <div v-if="userRole === 'parent'" class="parent-dashboard">
              <!-- My Children Section -->
              <Card class="children-card">
                <template #title>
                  <div class="card-title-header">
                    <h3>{{ $t('home.parent.myChildren.title') }}</h3>
                    <Button 
                      @click="showAddChildDialog = true"
                      icon="pi pi-plus"
                      :label="$t('home.parent.myChildren.addChild')"
                      size="small"
                      outlined
                    />
                  </div>
                </template>
                <template #content>
                  <!-- Empty State -->
                  <div v-if="children.length === 0" class="empty-state">
                    <i class="pi pi-users empty-icon"></i>
                    <h4>{{ $t('home.parent.myChildren.noChildren') }}</h4>
                    <p>{{ $t('home.parent.myChildren.noChildrenDescription') }}</p>
                    <Button 
                      @click="showAddChildDialog = true"
                      icon="pi pi-plus"
                      :label="$t('home.parent.myChildren.addFirstChild')"
                      severity="success"
                    />
                  </div>

                  <!-- Children List -->
                  <div v-else class="children-list">
                    <div v-for="child in children" :key="child._id" class="child-item">
                      <Avatar 
                        :label="getChildInitials(child)"
                        size="large"
                        :style="{ backgroundColor: getChildColor(child._id), color: 'white' }"
                      />
                      <div class="child-info">
                        <h5>{{ child.firstName }} {{ child.lastName }}</h5>
                        <div class="child-phone">
                          <i class="pi pi-phone"></i>
                          <span>{{ child.phone }}</span>
                        </div>
                      </div>
                      <Button 
                        icon="pi pi-pencil"
                        severity="secondary"
                        text
                        rounded
                        @click="editChild(child)"
                      />
                    </div>
                  </div>
                </template>
              </Card>

              <!-- Available Registrations -->
              <Card class="registrations-card">
                <template #title>
                  <div class="card-title-header">
                    <h3>{{ $t('home.parent.availableRegistrations.title') }}</h3>
                    <Button 
                      @click="refreshRegistrations"
                      icon="pi pi-refresh"
                      :label="$t('common.refresh')"
                      size="small"
                      outlined
                      :loading="loadingRegistrations"
                    />
                  </div>
                </template>
                <template #content>
                  <!-- Loading State -->
                  <div v-if="loadingRegistrations" class="loading-state">
                    <i class="pi pi-spin pi-spinner loading-icon"></i>
                    <span>{{ $t('home.parent.availableRegistrations.loading') }}</span>
                  </div>

                  <!-- Empty State -->
                  <div v-else-if="availableRegistrations.length === 0" class="empty-state">
                    <i class="pi pi-calendar-times empty-icon"></i>
                    <h4>{{ $t('home.parent.availableRegistrations.noRegistrations') }}</h4>
                  </div>

                  <!-- Registrations List -->
                  <div v-else class="registrations-list">
                    <div 
                      v-for="registration in availableRegistrations" 
                      :key="registration._id" 
                      class="registration-item"
                    >
                      <div class="registration-header">
                        <div class="registration-info">
                          <h5>{{ registration.title }}</h5>
                          <p v-if="registration.description" class="registration-description">
                            {{ registration.description }}
                          </p>
                          <div class="registration-meta">
                            <Tag 
                              :value="$t(`registrations.types.${registration.type}`)"
                              :severity="registration.type === 'pickup' ? 'success' : 'info'"
                              size="small"
                            />
                            <span class="stops-count">
                              <i class="pi pi-map-marker"></i>
                              {{ registration.stops?.length || 0 }} {{ $t('registrations.stops').toLowerCase() }}
                            </span>
                          </div>
                        </div>
                        
                        <div class="registration-actions">
                          <Button 
                            :label="$t('home.parent.availableRegistrations.createRequest')"
                            icon="pi pi-plus"
                            severity="success"
                            size="small"
                            @click="createRequest(registration)"
                          />
                        </div>
                      </div>
                      
                      <!-- Registration Requests for this Registration -->
                      <div 
                        v-if="getRequestsForRegistration(registration._id).length > 0" 
                        class="registration-requests-section"
                      >
                        <div class="requests-header">
                          <h6>{{ $t('home.parent.registrationRequests.title') }}</h6>
                          <span class="requests-count">
                            {{ getRequestsForRegistration(registration._id).length }}
                            {{ getRequestsForRegistration(registration._id).length === 1 
                                ? $t('home.parent.registrationRequests.request') 
                                : $t('home.parent.registrationRequests.requests') }}
                          </span>
                        </div>
                        
                        <div class="requests-list">
                          <div 
                            v-for="request in getRequestsForRegistration(registration._id)" 
                            :key="request._id"
                            class="request-item"
                          >
                            <div class="request-info">
                              <div class="request-child">
                                <Avatar 
                                  :label="getRequestChildInitials(request)"
                                  size="normal"
                                  :style="{ backgroundColor: getChildColor(request._id), color: 'white' }"
                                />
                                <div class="child-details">
                                  <span class="child-name">{{ request.student.firstName }} {{ request.student.lastName }}</span>
                                  <span class="selected-stop">
                                    <i class="pi pi-map-marker"></i>
                                    {{ request.selectedStop?.name || $t('common.notSelected') }}
                                  </span>
                                </div>
                              </div>
                            </div>
                            <div v-if="request.comments" class="request-comments">
                              <small class="comments-text">{{ request.comments }}</small>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </template>
              </Card>
            </div>

          </div>
        </template>
      </Card>

      <!-- Add Child Dialog -->
      <Dialog 
        v-model:visible="showAddChildDialog" 
        modal 
        :header="$t('home.parent.addChild.title')"
        :style="{ width: '450px' }"
        position="center"
        :draggable="false"
        :closable="true"
        class="add-child-dialog"
      >
        <template #header>
          <div class="dialog-header">
            <Avatar 
              icon="pi pi-user-plus" 
              size="small" 
              severity="success"
              class="mr-3"
            />
            <span class="dialog-title">{{ $t('home.parent.addChild.title') }}</span>
          </div>
        </template>

        <div class="dialog-content">
          <form class="add-child-form" @submit.prevent="saveChild">
            <div class="field">
              <label for="firstName" class="font-semibold">{{ $t('home.parent.addChild.firstName') }}</label>
              <IconField>
                <InputIcon>
                  <i class="pi pi-user" />
                </InputIcon>
                <InputText 
                  id="firstName"
                  v-model="newChild.firstName" 
                  fluid
                  :placeholder="$t('home.parent.addChild.firstNamePlaceholder')"
                  :invalid="!newChild.firstName.trim() && newChild.firstName !== ''"
                />
              </IconField>
            </div>
            
            <div class="field">
              <label for="lastName" class="font-semibold">{{ $t('home.parent.addChild.lastName') }}</label>
              <IconField>
                <InputIcon>
                  <i class="pi pi-user" />
                </InputIcon>
                <InputText 
                  id="lastName"
                  v-model="newChild.lastName" 
                  fluid
                  :placeholder="$t('home.parent.addChild.lastNamePlaceholder')"
                  :invalid="!newChild.lastName.trim() && newChild.lastName !== ''"
                />
              </IconField>
            </div>
            
            <div class="field">
              <label for="phone" class="font-semibold">{{ $t('home.parent.addChild.phone') }}</label>
              <IconField>
                <InputIcon>
                  <i class="pi pi-phone" />
                </InputIcon>
                <InputMask 
                  id="phone"
                  v-model="newChild.phone" 
                  mask="999-9999999"
                  fluid
                  placeholder="052-1234567"
                  :invalid="!newChild.phone.trim() && newChild.phone !== ''"
                />
              </IconField>
            </div>
          </form>
        </div>
        
        <template #footer>
          <Button 
            :label="$t('common.cancel')" 
            icon="pi pi-times"
            text
            severity="secondary"
            @click="cancelAddChild"
            :disabled="saving"
          />
          <Button 
            :label="$t('home.parent.addChild.save')" 
            icon="pi pi-check"
            severity="success"
            @click="saveChild"
            :loading="saving"
            :disabled="!isFormValid"
            autofocus
          />
        </template>
      </Dialog>
  </AppLayout>
</template>

<script>
import { inject, computed, ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useToast } from 'primevue/usetoast'
import AppLayout from '../components/AppLayout.vue'
import apiService from '../services/api.js'

export default {
  name: 'Home',
  components: {
    AppLayout
  },
  setup() {
    const authStore = inject('authStore')
    const router = useRouter()
    const toast = useToast()
    
    // Reactive data
    const children = ref([])
    const showAddChildDialog = ref(false)
    const saving = ref(false)
    const newChild = ref({
      firstName: '',
      lastName: '',
      phone: ''
    })
    
    // Registration data
    const availableRegistrations = ref([])
    const loadingRegistrations = ref(false)
    const userRequests = ref([])
    
    const userRole = computed(() => {
      return authStore.user?.role || 'Unknown'
    })
    
    const userName = computed(() => {
      return authStore.user?.firstName || 'User'
    })
    
    const isFormValid = computed(() => {
      return newChild.value.firstName.trim() && 
             newChild.value.lastName.trim() && 
             newChild.value.phone.trim()
    })
    
    // Load children for parents
    const loadChildren = async () => {
      if (userRole.value !== 'parent') return
      
      try {
        const response = await apiService.get('/auth/my-students')
        children.value = response.data.children || []
      } catch (error) {
        console.error('Error loading children:', error)
        // Add mock data for preview
      }
    }
    
    // Child management functions
    const saveChild = async () => {
      if (!isFormValid.value) return
      
      saving.value = true
      try {
        const response = await apiService.post('/auth/my-students', {
          firstName: newChild.value.firstName.trim(),
          lastName: newChild.value.lastName.trim(),
          phone: newChild.value.phone.trim()
        })
        
        children.value.push(response.data.student)
        toast.add({
          severity: 'success',
          summary: 'Success',
          detail: 'Child added successfully',
          life: 3000
        })
        cancelAddChild()
      } catch (error) {
        console.error('Error saving child:', error)
        toast.add({
          severity: 'error',
          summary: 'Error',
          detail: error.response?.data?.message || 'Failed to add child',
          life: 5000
        })
      } finally {
        saving.value = false
      }
    }
    
    const cancelAddChild = () => {
      showAddChildDialog.value = false
      newChild.value = {
        firstName: '',
        lastName: '',
        phone: ''
      }
    }
    
    const editChild = (child) => {
      // TODO: Implement edit functionality
      console.log('Edit child:', child)
    }
    
    // Utility functions
    const getChildInitials = (child) => {
      return `${child.firstName.charAt(0)}${child.lastName.charAt(0)}`.toUpperCase()
    }
    
    const getRequestChildInitials = (request) => {
      return `${request.student.firstName.charAt(0)}${request.student.lastName.charAt(0)}`.toUpperCase()
    }
    
    const getChildColor = (childId) => {
      if (!childId || typeof childId !== 'string') {
        return '#FF6B6B' // Default color
      }
      const colors = [
        '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', 
        '#FFEAA7', '#DDA0DD', '#98D8C8', '#F7DC6F'
      ]
      const index = childId.charCodeAt(childId.length - 1) % colors.length
      return colors[index]
    }
    
    // Registration management functions
    const loadRegistrations = async () => {
      if (userRole.value !== 'parent') return
      
      loadingRegistrations.value = true
      try {
        const [registrationsResponse, requestsResponse] = await Promise.all([
          apiService.get('/registrations?status=active'),
          apiService.get('/registration-requests/my-requests')
        ])
        
        availableRegistrations.value = registrationsResponse.data.registrations || []
        userRequests.value = requestsResponse.data.requests || []
      } catch (error) {
        console.error('Error loading registrations:', error)
        toast.add({
          severity: 'error',
          summary: 'Error',
          detail: 'Failed to load registrations',
          life: 5000
        })
      } finally {
        loadingRegistrations.value = false
      }
    }
    
    const refreshRegistrations = async () => {
      await loadRegistrations()
      toast.add({
        severity: 'success',
        summary: 'Refreshed',
        detail: 'Registration data updated',
        life: 2000
      })
    }
    
    const getRequestsForRegistration = (registrationId) => {
      return userRequests.value.filter(request => request.registration._id === registrationId)
    }
    
    const getStatusSeverity = (status) => {
      const severityMap = {
        'pending': 'warning',
        'approved': 'success',
        'rejected': 'danger',
        'cancelled': 'secondary'
      }
      return severityMap[status] || 'info'
    }
    
    const createRequest = (registration) => {
      router.push({
        name: 'RegistrationRequestCreate',
        params: { registrationId: registration._id }
      })
    }
    
    // Navigation functions
    const goToUserManagement = () => {
      router.push('/user-management')
    }
    
    const goToLineManagement = () => {
      router.push('/lines')
    }
    
    const goToRideManagement = () => {
      router.push('/rides')
    }
    
    const goToRegistrationManagement = () => {
      router.push('/registrations')
    }
    
    onMounted(() => {
      loadChildren()
      loadRegistrations()
    })
    
    return {
      userRole,
      userName,
      children,
      showAddChildDialog,
      saving,
      newChild,
      isFormValid,
      saveChild,
      cancelAddChild,
      editChild,
      getChildInitials,
      getRequestChildInitials,
      getChildColor,
      // Registration management
      availableRegistrations,
      loadingRegistrations,
      refreshRegistrations,
      getRequestsForRegistration,
      getStatusSeverity,
      createRequest,
      // Navigation
      goToUserManagement,
      goToLineManagement,
      goToRideManagement,
      goToRegistrationManagement
    }
  }
}
</script>

<style scoped>
/* Dashboard specific styles */

/* Role-specific content spacing */
.role-specific-content {
  margin-top: 1.5rem;
}

/* Admin Dashboard Styles */

.admin-actions-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 1.5rem;
  margin-top: 1rem;
}

@media (min-width: 768px) {
  .admin-actions-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

/* Parent Dashboard Styles */
.parent-dashboard {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.parent-actions-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 1.5rem;
  margin-top: 1rem;
}

/* Welcome Card */
.welcome-card .welcome-header {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1.5rem;
}

.welcome-text h2 {
  margin: 0 0 0.5rem 0;
  color: var(--p-text-color);
  font-size: 1.5rem;
  font-weight: 600;
}

.welcome-text p {
  margin: 0;
  color: var(--p-text-muted-color);
  font-size: 1rem;
}

/* Children Card */
.card-title-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
}

.card-title-header h3 {
  margin: 0;
  font-size: 1.25rem;
  font-weight: 600;
  color: var(--p-text-color);
}

/* Empty State */
.empty-state {
  text-align: center;
  padding: 3rem 1rem;
}

.empty-state .empty-icon {
  font-size: 3rem;
  color: var(--p-text-muted-color);
  margin-bottom: 1rem;
}

.empty-state h4 {
  margin: 0 0 1rem 0;
  color: var(--p-text-color);
  font-size: 1.25rem;
  font-weight: 600;
}

.empty-state p {
  margin: 0 0 2rem 0;
  color: var(--p-text-muted-color);
  max-width: 400px;
  margin-left: auto;
  margin-right: auto;
  line-height: 1.5;
}

/* Children List */
.children-list {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.child-item {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1rem;
  border: 1px solid var(--p-surface-border);
  border-radius: var(--p-border-radius);
  transition: all 0.2s;
}

.child-item:hover {
  background-color: var(--p-surface-hover);
}

.child-info {
  flex: 1;
}

.child-info h5 {
  margin: 0 0 0.5rem 0;
  color: var(--p-text-color);
  font-size: 1rem;
  font-weight: 600;
}

.child-phone {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  color: var(--p-text-muted-color);
  font-size: 0.875rem;
}

.child-phone i {
  color: var(--p-primary-color);
}

/* Actions Grid */
.actions-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 1.5rem;
}

/* Registration Card Styles */
.registrations-card .card-title-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 1rem;
}

.registrations-card .card-title-header h3 {
  margin: 0;
  color: var(--p-text-color);
}

.registrations-list {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.registration-item {
  border: 1px solid var(--p-surface-border);
  border-radius: var(--p-border-radius);
  padding: 1.5rem;
  transition: all 0.2s;
}

.registration-item:hover {
  border-color: var(--p-primary-color);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.registration-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 1rem;
}

.registration-info {
  flex: 1;
  min-width: 0;
}

.registration-info h5 {
  margin: 0 0 0.5rem 0;
  color: var(--p-text-color);
  font-size: 1.125rem;
  font-weight: 600;
}

.registration-description {
  margin: 0 0 1rem 0;
  color: var(--p-text-muted-color);
  line-height: 1.5;
}

.registration-meta {
  display: flex;
  align-items: center;
  gap: 1rem;
  flex-wrap: wrap;
}

.stops-count {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  color: var(--p-text-muted-color);
  font-size: 0.875rem;
}

.stops-count i {
  color: var(--p-primary-color);
}

.registration-actions {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 0.5rem;
}

.existing-request-actions {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 0.5rem;
}

/* Responsive adjustments for registrations */
@media (max-width: 768px) {
  .registration-header {
    flex-direction: column;
    align-items: stretch;
  }
  
  .registration-actions,
  .existing-request-actions {
    flex-direction: row;
    justify-content: flex-start;
    align-items: center;
  }
  
  .registrations-card .card-title-header {
    flex-direction: column;
    align-items: stretch;
  }
}

.action-card .action-content {
  text-align: center;
  padding: 1rem;
}

.action-content .action-avatar {
  margin-bottom: 1.5rem;
}

.action-content h4 {
  margin: 0 0 1rem 0;
  color: var(--p-text-color);
  font-size: 1.125rem;
  font-weight: 600;
}

.action-content p {
  margin: 0 0 1.5rem 0;
  color: var(--p-text-muted-color);
  line-height: 1.5;
}

.action-content .action-button {
  width: 100%;
}

/* Dialog Styles */
.add-child-dialog {
  font-family: var(--p-font-family);
}

.dialog-header {
  display: flex;
  align-items: center;
  font-size: 1.25rem;
  font-weight: 600;
  color: var(--p-text-color);
}

.dialog-title {
  color: var(--p-text-color);
}

.dialog-content {
  padding: 0;
}

/* Form Styles */
.add-child-form {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

.add-child-form .field {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.add-child-form .field label {
  font-weight: 600;
  color: var(--p-text-color);
  margin-bottom: 0.25rem;
}

/* Registration Requests Section */
.registration-requests-section {
  margin-top: 1rem;
  padding-top: 1rem;
  border-top: 1px solid var(--p-surface-border);
}

.requests-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.requests-header h6 {
  margin: 0;
  font-size: 1rem;
  font-weight: 600;
  color: var(--p-text-color);
}

.requests-count {
  color: var(--p-text-muted-color);
  font-size: 0.875rem;
}

.requests-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.request-item {
  background: var(--p-surface-50);
  border: 1px solid var(--p-surface-border);
  border-radius: var(--p-border-radius);
  padding: 1rem;
  transition: all 0.2s;
}

.request-item:hover {
  border-color: var(--p-primary-300);
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.1);
}

.request-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1rem;
}

.request-child {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  flex: 1;
}

.child-details {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.child-name {
  font-weight: 600;
  color: var(--p-text-color);
  font-size: 0.9rem;
}

.selected-stop {
  display: flex;
  align-items: center;
  gap: 0.25rem;
  color: var(--p-text-muted-color);
  font-size: 0.8rem;
}

.selected-stop i {
  color: var(--p-primary-color);
}

.request-status {
  flex-shrink: 0;
}

.request-comments {
  margin-top: 0.75rem;
  padding-top: 0.75rem;
  border-top: 1px solid var(--p-surface-border);
}

.comments-text {
  color: var(--p-text-muted-color);
  font-style: italic;
  line-height: 1.4;
}

/* Responsive adjustments for requests */
@media (max-width: 640px) {
  .request-info {
    flex-direction: column;
    align-items: stretch;
    gap: 0.75rem;
  }
  
  .request-status {
    align-self: flex-start;
  }
}

/* Footer automatically styled by PrimeVue */
</style>