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
                        icon="pi pi-route" 
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
              </div>
            </div>

            <!-- Parent View -->
            <div v-if="userRole === 'parent'">
              <!-- My Children Section -->
              <Card class="children-card mb-4">
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

              <!-- Quick Actions -->
              <div class="parent-actions-grid">
                <Card class="action-card">
                  <template #content>
                    <div class="action-content">
                      <Avatar 
                        icon="pi pi-calendar-plus" 
                        size="large" 
                        severity="success"
                        class="action-avatar"
                      />
                      <h4>{{ $t('home.parent.quickActions.registerForTransport') }}</h4>
                      <p>{{ $t('home.parent.quickActions.registerDescription') }}</p>
                      <Button 
                        @click="goToRegistrations"
                        :label="$t('home.parent.quickActions.viewRegistrations')"
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
                        icon="pi pi-list" 
                        size="large" 
                        severity="info"
                        class="action-avatar"
                      />
                      <h4>{{ $t('home.parent.quickActions.myRequests') }}</h4>
                      <p>{{ $t('home.parent.quickActions.requestsDescription') }}</p>
                      <Button 
                        @click="goToMyRequests"
                        :label="$t('home.parent.quickActions.viewRequests')"
                        severity="info"
                        class="action-button"
                      />
                    </div>
                  </template>
                </Card>
              </div>
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
        const response = await apiService.get('/auth/my-children')
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
        const response = await apiService.post('/auth/create-student', {
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
    
    const getChildColor = (childId) => {
      const colors = [
        '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', 
        '#FFEAA7', '#DDA0DD', '#98D8C8', '#F7DC6F'
      ]
      const index = childId.charCodeAt(childId.length - 1) % colors.length
      return colors[index]
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
    
    const goToRegistrations = () => {
      // TODO: Navigate to registration page
      console.log('Navigate to registrations')
    }
    
    const goToMyRequests = () => {
      // TODO: Navigate to my requests page
      console.log('Navigate to my requests')
    }
    
    onMounted(() => {
      loadChildren()
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
      getChildColor,
      goToUserManagement,
      goToLineManagement,
      goToRideManagement,
      goToRegistrations,
      goToMyRequests
    }
  }
}
</script>

<style scoped>
/* Dashboard specific styles */

/* Admin Dashboard Styles */

.admin-actions-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 1.5rem;
  margin-top: 1rem;
}

/* Parent Dashboard Styles */
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
  gap: 1rem;
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

/* Footer automatically styled by PrimeVue */
</style>