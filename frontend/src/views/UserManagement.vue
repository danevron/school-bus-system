<template>
  <AppLayout 
    :page-title="$t('users.title')"
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
    </template>
    
    <div class="content-wrapper">
        <!-- Create Student Section -->
        <Card class="student-section">
          <template #header>
            <div class="section-header-card">
              <h2><i class="pi pi-user-plus"></i>{{ $t('users.createStudent') }}</h2>
            </div>
          </template>
          <template #content>
            <form @submit.prevent="handleCreateStudent" class="student-form">
              <div class="form-row">
                <div class="form-group">
                  <label for="studentFirstName">{{ $t('login.firstName') }}</label>
                  <IconField>
                    <InputIcon>
                      <i class="pi pi-user" />
                    </InputIcon>
                    <InputText 
                      id="studentFirstName"
                      type="text"
                      v-model="studentForm.firstName" 
                      :placeholder="$t('login.placeholders.firstName')"
                      required 
                      fluid
                      :disabled="loading"
                    />
                  </IconField>
                </div>
                
                <div class="form-group">
                  <label for="studentLastName">{{ $t('login.lastName') }}</label>
                  <IconField>
                    <InputIcon class="pi pi-user" />
                    <InputText 
                      id="studentLastName"
                      v-model="studentForm.lastName" 
                      :placeholder="$t('login.placeholders.lastName')"
                      required 
                      :disabled="loading"
                    />
                  </IconField>
                </div>
                
                <div class="form-group">
                  <label for="studentPhone">{{ $t('login.phone') }}</label>
                  <IconField>
                    <InputIcon class="pi pi-phone" />
                    <InputMask 
                      id="studentPhone"
                      v-model="studentForm.phone" 
                      mask="999-9999999"
                      :placeholder="$t('login.placeholders.phone')"
                      required 
                      :disabled="loading"
                    />
                  </IconField>
                </div>
              </div>
              
              <Button 
                type="submit" 
                :loading="loading"
                loadingIcon="pi pi-spin pi-spinner"
                :label="loading ? $t('users.creating') : $t('users.createStudent')"
                icon="pi pi-plus"
                severity="info"
                :disabled="loading"
              />
            </form>
            
            <div v-if="studentMessage" class="message-container">
              <Card :class="`message-card ${studentMessageType}`">
                <template #content>
                  <div class="message-content">
                    <i :class="studentMessageType === 'success' ? 'pi pi-check-circle' : 'pi pi-exclamation-triangle'"></i>
                    <span>{{ studentMessage }}</span>
                  </div>
                </template>
              </Card>
            </div>
          </template>
        </Card>

        <!-- Connect Student to Parents Section -->
        <Card class="parent-student-section">
          <template #header>
            <div class="section-header-card">
              <h2><i class="pi pi-link"></i>{{ $t('users.connectStudentToParents') }}</h2>
            </div>
          </template>
          <template #content>
            <form @submit.prevent="handleConnectStudentToParents" class="parent-student-form">
              <div class="form-row">
                <div class="form-group">
                  <label for="studentSelect">{{ $t('users.student') }}</label>
                  <Select 
                    id="studentSelect"
                    v-model="parentStudentForm.studentId"
                    :options="availableStudents"
                    optionLabel="displayName"
                    optionValue="_id"
                    :placeholder="$t('users.selectStudent')"
                    :loading="loadingStudents"
                    :disabled="loading || loadingStudents"
                    showClear
                  />
                </div>
                
                <div class="form-group">
                  <label for="parentSelect1">{{ $t('users.primaryParent') }}</label>
                  <Select 
                    id="parentSelect1"
                    v-model="parentStudentForm.parentId1"
                    :options="availableParents"
                    optionLabel="displayName"
                    optionValue="_id"
                    :placeholder="$t('users.selectPrimaryParent')"
                    :loading="loadingParents"
                    :disabled="loading || loadingParents"
                    showClear
                  />
                </div>
                
                <div class="form-group">
                  <label for="parentSelect2">{{ $t('users.secondaryParent') }}</label>
                  <Select 
                    id="parentSelect2"
                    v-model="parentStudentForm.parentId2"
                    :options="filteredSecondaryParents"
                    optionLabel="displayName"
                    optionValue="_id"
                    :placeholder="$t('users.selectSecondaryParent')"
                    :loading="loadingParents"
                    :disabled="loading || loadingParents"
                    showClear
                  />
                </div>
              </div>
              
              <Button 
                type="submit" 
                :loading="loading"
                loadingIcon="pi pi-spin pi-spinner"
                :label="loading ? $t('users.connecting') : $t('users.connectToParents')"
                icon="pi pi-link"
                severity="warning"
                :disabled="loading || !parentStudentForm.studentId || !parentStudentForm.parentId1"
              />
            </form>
            
            <div v-if="parentStudentMessage" class="message-container">
              <Card :class="`message-card ${parentStudentMessageType}`">
                <template #content>
                  <div class="message-content">
                    <i :class="parentStudentMessageType === 'success' ? 'pi pi-check-circle' : 'pi pi-exclamation-triangle'"></i>
                    <span>{{ parentStudentMessage }}</span>
                  </div>
                </template>
              </Card>
            </div>
          </template>
        </Card>

        <!-- Invite User Section -->
        <Card class="invite-section">
          <template #header>
            <div class="section-header-card">
              <h2><i class="pi pi-send"></i>{{ $t('users.inviteNewUser') }}</h2>
            </div>
          </template>
          <template #content>
            <form @submit.prevent="handleInvite" class="invite-form">
              <div class="form-row">
                <div class="form-group">
                  <label for="email">{{ $t('login.email') }}</label>
                  <IconField>
                    <InputIcon class="pi pi-envelope" />
                    <InputText 
                      id="email"
                      type="email"
                      v-model="inviteForm.email" 
                      :placeholder="$t('login.placeholders.email')"
                      required 
                      :disabled="loading"
                    />
                  </IconField>
                </div>
                
                <div class="form-group">
                  <label for="phone">{{ $t('login.phone') }}</label>
                  <IconField>
                    <InputIcon class="pi pi-phone" />
                    <InputMask 
                      id="phone"
                      v-model="inviteForm.phone" 
                      mask="999-9999999"
                      :placeholder="$t('login.placeholders.phone')"
                      required 
                      :disabled="loading"
                    />
                  </IconField>
                </div>
                
                <div class="form-group">
                  <label for="role">{{ $t('users.role') }}</label>
                  <Select 
                    id="role"
                    v-model="inviteForm.role" 
                    :options="roleFilterOptions"
                    optionLabel="label"
                    optionValue="value"
                    :placeholder="$t('users.selectRole')"
                    required 
                    :disabled="loading"
                  />
                </div>
              </div>
              
              <Button 
                type="submit" 
                :loading="loading"
                loadingIcon="pi pi-spin pi-spinner"
                :label="loading ? $t('users.sending') : $t('users.sendInvitation')"
                icon="pi pi-send"
                severity="success"
                :disabled="loading"
              />
            </form>
            
            <div v-if="message" class="message-container">
              <Card :class="`message-card ${messageType}`">
                <template #content>
                  <div class="message-content">
                    <i :class="messageType === 'success' ? 'pi pi-check-circle' : 'pi pi-exclamation-triangle'"></i>
                    <span>{{ message }}</span>
                  </div>
                </template>
              </Card>
            </div>
          </template>
        </Card>

        <!-- Users List Section -->
        <Card class="users-section">
          <template #header>
            <div class="section-header-card">
              <h2><i class="pi pi-users"></i>{{ $t('users.allUsers') }}</h2>
            </div>
          </template>
          <template #content>
            <div class="table-filters">
              <div class="filter-row">
                <div class="filter-group">
                  <label for="searchUsers">{{ $t('common.search') }}</label>
                  <IconField>
                    <InputIcon class="pi pi-search" />
                    <InputText 
                      id="searchUsers"
                      v-model="userSearchFilter" 
                      :placeholder="searchUsersPlaceholder"
                    />
                  </IconField>
                </div>
                <div class="filter-group">
                  <label for="roleFilter">{{ $t('users.role') }}</label>
                  <Select 
                    id="roleFilter"
                    v-model="userFilter.role" 
                    :options="roleFilterOptions"
                    optionLabel="label"
                    optionValue="value"
                    :placeholder="$t('users.allRoles')"
                    showClear
                    @change="fetchUsers"
                  />
                </div>
                <div class="filter-group">
                  <label for="statusFilter">{{ $t('common.status') }}</label>
                  <Select 
                    id="statusFilter"
                    v-model="userFilter.isActive" 
                    :options="statusFilterOptions"
                    optionLabel="label"
                    optionValue="value"
                    :placeholder="$t('users.allStatus')"
                    showClear
                    @change="fetchUsers"
                  />
                </div>
              </div>
            </div>
            
            <DataTable 
              :value="filteredUsers" 
              :loading="loadingUsers"
              paginator 
              :rows="10" 
              :rowsPerPageOptions="[5, 10, 20, 50]"
              paginatorTemplate="RowsPerPageDropdown FirstPageLink PrevPageLink CurrentPageReport NextPageLink LastPageLink"
              :currentPageReportTemplate="usersPageReportTemplate"
              stripedRows
              removableSort
              sortMode="multiple"
              class="users-table"
            >
              <template #empty>
                <div class="empty-state">
                  <i class="pi pi-users" style="font-size: 3rem; color: var(--p-text-muted-color);"></i>
                  <p>{{ $t('users.noUsers') }}</p>
                </div>
              </template>
              
              <Column field="user" :header="$t('common.name')" sortable>
                <template #body="slotProps">
                  <div class="user-info-cell">
                    <Avatar 
                      :label="getUserInitials(slotProps.data)"
                      size="medium"
                      shape="circle"
                    />
                    <div class="user-details">
                      <div class="user-name">{{ slotProps.data.firstName }} {{ slotProps.data.lastName }}</div>
                      <div class="user-contact">
                        <i class="pi pi-envelope"></i>
                        {{ slotProps.data.email }}
                      </div>
                      <div class="user-contact">
                        <i class="pi pi-phone"></i>
                        {{ slotProps.data.phone }}
                      </div>
                    </div>
                  </div>
                </template>
              </Column>
              
              <Column field="role" :header="$t('users.role')" sortable>
                <template #body="slotProps">
                  <div class="role-cell">
                    <i :class="getRoleIcon(slotProps.data.role)"></i>
                    <span class="role-badge" :class="`role-${slotProps.data.role}`">
                      {{ $t('appLayout.userRole.' + slotProps.data.role) }}
                    </span>
                  </div>
                </template>
              </Column>
              
              <Column field="isActive" :header="$t('common.status')" sortable>
                <template #body="slotProps">
                  <div class="status-cell">
                    <i :class="slotProps.data.isActive ? 'pi pi-check-circle' : 'pi pi-times-circle'"></i>
                    <span class="status-badge" :class="slotProps.data.isActive ? 'active' : 'inactive'">
                      {{ slotProps.data.isActive ? $t('lines.active') : $t('lines.inactive') }}
                    </span>
                  </div>
                </template>
              </Column>
              
              <Column field="relationships" :header="$t('users.relationships')">
                <template #body="slotProps">
                  <div class="relationships-cell">
                    <div v-if="slotProps.data.role === 'student' && slotProps.data.parents && slotProps.data.parents.length > 0">
                      <div class="relationship-header">
                        <i class="pi pi-users"></i>
                        {{ $t('users.parents') }}
                      </div>
                      <div v-for="parent in slotProps.data.parents" :key="parent._id" class="relationship-item">
                        {{ parent.firstName }} {{ parent.lastName }}
                      </div>
                    </div>
                    <div v-else-if="slotProps.data.role === 'parent' && slotProps.data.children && slotProps.data.children.length > 0">
                      <div class="relationship-header">
                        <i class="pi pi-user"></i>
                        {{ $t('users.children') }}
                      </div>
                      <div v-for="child in slotProps.data.children" :key="child._id" class="relationship-item">
                        {{ child.firstName }} {{ child.lastName }}
                      </div>
                    </div>
                    <span v-else class="no-relationships">—</span>
                  </div>
                </template>
              </Column>
              
              <Column field="createdAt" :header="$t('lines.created')" sortable>
                <template #body="slotProps">
                  <div class="date-cell">
                    <i class="pi pi-calendar"></i>
                    {{ formatDate(slotProps.data.createdAt) }}
                  </div>
                </template>
              </Column>
            </DataTable>
          </template>
        </Card>

        <!-- Invitations Section -->
        <div class="invitations-section">
          <h2>{{ $t('users.pendingInvitations') }}</h2>
          
          <div v-if="loadingInvitations" class="loading">{{ loadingInvitationsText }}</div>
          
          <div v-else-if="invitations.length === 0" class="no-invitations">
            {{ $t('users.noPendingInvitations') }}
          </div>

          <div v-else class="invitations-grid">
            <div 
              v-for="invitation in invitations" 
              :key="invitation._id" 
              class="invitation-card"
            >
              <div class="invitation-info">
                <div class="invitation-email">{{ invitation.email }}</div>
                <div class="invitation-phone">{{ invitation.phone }}</div>
                <div class="invitation-meta">
                  <span class="role-badge" :class="`role-${invitation.role}`">
                    {{ invitation.role }}
                  </span>
                  <span class="status-badge pending">{{ invitation.status }}</span>
                </div>
                <div class="invitation-details">
                  <div>{{ $t('users.invitedBy') }}: {{ invitation.invitedBy.firstName }} {{ invitation.invitedBy.lastName }}</div>
                  <div>{{ $t('users.expires') }}: {{ formatDate(invitation.expiresAt) }}</div>
                </div>
                <button 
                  @click="deleteInvitation(invitation._id)" 
                  class="delete-button"
                  :disabled="loading"
                >
                  {{ $t('common.delete') }}
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </AppLayout>
</template>

<script>
import { ref, inject, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import apiService from '../services/api'
import AppLayout from '../components/AppLayout.vue'

export default {
  name: 'UserManagement',
  components: {
    AppLayout
  },
  setup() {
    const authStore = inject('authStore')
    const router = useRouter()
    const { t } = useI18n()

    const breadcrumbs = computed(() => [
      { label: t('navigation.dashboard'), path: '/home' },
      { label: t('users.title') }
    ])
    
    const loading = ref(false)
    const loadingUsers = ref(false)
    const loadingInvitations = ref(false)
    const loadingStudents = ref(false)
    const loadingParents = ref(false)
    const message = ref('')
    const messageType = ref('success')
    const studentMessage = ref('')
    const studentMessageType = ref('success')
    const parentStudentMessage = ref('')
    const parentStudentMessageType = ref('success')
    
    const inviteForm = ref({
      email: '',
      phone: '',
      role: ''
    })
    
    const studentForm = ref({
      firstName: '',
      lastName: '',
      phone: ''
    })
    
    const parentStudentForm = ref({
      studentId: '',
      parentId1: '',
      parentId2: ''
    })
    
    const users = ref([])
    const invitations = ref([])
    const availableStudents = ref([])
    const availableParents = ref([])
    
    const userFilter = ref({
      role: '',
      isActive: ''
    })
    
    const userSearchFilter = ref('')
    
    const roleFilterOptions = [
      { label: t('users.admin'), value: 'admin' },
      { label: t('users.driver'), value: 'driver' },
      { label: t('users.parent'), value: 'parent' },
      { label: t('users.student'), value: 'student' }
    ]
    
    const statusFilterOptions = [
      { label: t('lines.active'), value: 'true' },
      { label: t('lines.inactive'), value: 'false' }
    ]
    
    const handleCreateStudent = async () => {
      try {
        loading.value = true
        studentMessage.value = ''
        
        await apiService.post('/auth/students', studentForm.value)
        
        studentMessage.value = t('messages.studentCreated')
        studentMessageType.value = 'success'
        
        // Reset form
        studentForm.value = {
          firstName: '',
          lastName: '',
          phone: ''
        }
        
        // Refresh lists
        await Promise.all([fetchUsers(), fetchAvailableStudents()])
        
      } catch (error) {
        studentMessage.value = error.response?.data?.message || t('messages.failedToCreate')
        studentMessageType.value = 'error'
      } finally {
        loading.value = false
      }
    }
    
    const handleConnectStudentToParents = async () => {
      try {
        loading.value = true
        parentStudentMessage.value = ''
        
        const parentIds = [parentStudentForm.value.parentId1]
        if (parentStudentForm.value.parentId2) {
          parentIds.push(parentStudentForm.value.parentId2)
        }
        
        await apiService.post('/auth/students/connect-parents', {
          studentId: parentStudentForm.value.studentId,
          parentIds
        })
        
        parentStudentMessage.value = t('messages.studentConnected')
        parentStudentMessageType.value = 'success'
        
        // Reset form
        parentStudentForm.value = {
          studentId: '',
          parentId1: '',
          parentId2: ''
        }
        
        // Refresh lists
        await Promise.all([fetchUsers(), fetchAvailableStudents()])
        
      } catch (error) {
        parentStudentMessage.value = error.response?.data?.message || t('messages.failedToConnect')
        parentStudentMessageType.value = 'error'
      } finally {
        loading.value = false
      }
    }
    
    const handleInvite = async () => {
      try {
        loading.value = true
        message.value = ''
        
        await apiService.post('/invitations', inviteForm.value)
        
        message.value = t('messages.invitationSent')
        messageType.value = 'success'
        
        // Reset form
        inviteForm.value = {
          email: '',
          phone: '',
          role: ''
        }
        
        // Refresh invitations list
        await fetchInvitations()
        
      } catch (error) {
        message.value = error.response?.data?.message || t('messages.failedToSendInvitation')
        messageType.value = 'error'
      } finally {
        loading.value = false
      }
    }
    
    const fetchUsers = async () => {
      try {
        loadingUsers.value = true
        const params = new URLSearchParams()
        if (userFilter.value.role) params.append('role', userFilter.value.role)
        if (userFilter.value.isActive) params.append('isActive', userFilter.value.isActive)
        params.append('populate', 'true') // Request populated relationships
        
        const response = await apiService.get(`/auth/users?${params.toString()}`)
        users.value = response.users
      } catch (error) {
        console.error('Failed to fetch users:', error)
      } finally {
        loadingUsers.value = false
      }
    }
    
    const fetchAvailableStudents = async () => {
      try {
        loadingStudents.value = true
        const response = await apiService.get('/auth/students/with-parents?maxParents=1')
        // Add displayName property for Select
        availableStudents.value = response.students.map(student => ({
          ...student,
          displayName: `${student.firstName} ${student.lastName}`
        }))
      } catch (error) {
        console.error('Failed to fetch available students:', error)
      } finally {
        loadingStudents.value = false
      }
    }
    
    const fetchAvailableParents = async () => {
      try {
        loadingParents.value = true
        const response = await apiService.get('/auth/users?role=parent&isActive=true')
        // Add displayName property for Select
        availableParents.value = response.users.map(parent => ({
          ...parent,
          displayName: `${parent.firstName} ${parent.lastName}`
        }))
      } catch (error) {
        console.error('Failed to fetch available parents:', error)
      } finally {
        loadingParents.value = false
      }
    }
    
    const fetchInvitations = async () => {
      try {
        loadingInvitations.value = true
        const response = await apiService.get('/invitations?status=pending')
        invitations.value = response.invitations
      } catch (error) {
        console.error('Failed to fetch invitations:', error)
      } finally {
        loadingInvitations.value = false
      }
    }
    
    const deleteInvitation = async (invitationId) => {
      if (!confirm(t('messages.confirmDeleteInvitation'))) return
      
      try {
        await apiService.delete(`/invitations/${invitationId}`)

        await fetchInvitations() // Refresh list
        message.value = t('messages.invitationDeleted')
        messageType.value = 'success'
      } catch (error) {
        message.value = error.response?.data?.message || t('messages.failedToDeleteInvitation')
        messageType.value = 'error'
      }
    }
    
    const formatDate = (dateString) => {
      return new Date(dateString).toLocaleDateString()
    }
    
    const getUserInitials = (user) => {
      return `${user.firstName?.[0] || ''}${user.lastName?.[0] || ''}`.toUpperCase()
    }
    
    const getRoleIcon = (role) => {
      const icons = {
        admin: 'pi pi-crown',
        driver: 'pi pi-car',
        parent: 'pi pi-users',
        student: 'pi pi-user'
      }
      return icons[role] || 'pi pi-user'
    }
    
    const goBack = () => {
      router.push('/home')
    }
    
    const filteredUsers = computed(() => {
      if (!userSearchFilter.value) {
        return users.value
      }
      const search = userSearchFilter.value.toLowerCase()
      return users.value.filter(user => {
        return (
          user.firstName?.toLowerCase().includes(search) ||
          user.lastName?.toLowerCase().includes(search) ||
          user.email?.toLowerCase().includes(search) ||
          user.phone?.toLowerCase().includes(search) ||
          user.role?.toLowerCase().includes(search)
        )
      })
    })
    
    const filteredSecondaryParents = computed(() => {
      if (!parentStudentForm.value.parentId1) {
        return availableParents.value
      }
      return availableParents.value.filter(parent => 
        (parent._id || parent.id) !== parentStudentForm.value.parentId1
      )
    })
    
    // Computed properties for translated strings
    const searchUsersPlaceholder = computed(() => t('common.search'))
    const loadingInvitationsText = computed(() => t('common.loading'))
    const usersPageReportTemplate = computed(() => 
      t('common.paginatorTemplate').replace('{first}', '{first}').replace('{last}', '{last}').replace('{totalRecords}', '{totalRecords}')
    )
    
    onMounted(async () => {
      await Promise.all([
        fetchUsers(),
        fetchInvitations(),
        fetchAvailableStudents(),
        fetchAvailableParents()
      ])
    })
    
    return {
      breadcrumbs,
      loading,
      loadingUsers,
      loadingInvitations,
      loadingStudents,
      loadingParents,
      message,
      messageType,
      studentMessage,
      studentMessageType,
      parentStudentMessage,
      parentStudentMessageType,
      inviteForm,
      studentForm,
      parentStudentForm,
      users,
      invitations,
      availableStudents,
      availableParents,
      userFilter,
      handleCreateStudent,
      handleConnectStudentToParents,
      handleInvite,
      fetchUsers,
      deleteInvitation,
      formatDate,
      getUserInitials,
      getRoleIcon,
      goBack,
      userSearchFilter,
      roleFilterOptions,
      statusFilterOptions,
      filteredUsers,
      filteredSecondaryParents,
      searchUsersPlaceholder,
      loadingInvitationsText,
      usersPageReportTemplate
    }
  }
}
</script>

<style scoped>
/* User Management specific styles */

.content-wrapper > div {
  background: white;
  border-radius: 8px;
  padding: 30px;
  margin-bottom: 30px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
}

.student-section h2,
.parent-student-section h2,
.invite-section h2,
.users-section h2,
.invitations-section h2 {
  color: #333;
  margin-bottom: 20px;
}

.student-form,
.parent-student-form,
.invite-form {
  margin-bottom: 20px;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 20px;
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  margin-bottom: 5px;
  color: #333;
  font-weight: bold;
}

.form-group input,
.form-group select {
  width: 100%;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
}

.form-group input:focus,
.form-group select:focus {
  outline: none;
  border-color: #007bff;
}

.create-student-button,
.connect-button,
.invite-button {
  background-color: #28a745;
  color: white;
  border: none;
  padding: 12px 24px;
  border-radius: 4px;
  font-size: 16px;
  cursor: pointer;
  transition: background-color 0.2s;
}

.create-student-button {
  background-color: #17a2b8;
}

.connect-button {
  background-color: #fd7e14;
}

.create-student-button:hover:not(:disabled) {
  background-color: #138496;
}

.connect-button:hover:not(:disabled) {
  background-color: #e8640a;
}

.invite-button:hover:not(:disabled) {
  background-color: #218838;
}

.create-student-button:disabled,
.connect-button:disabled,
.invite-button:disabled {
  background-color: #ccc;
  cursor: not-allowed;
}

.message {
  padding: 10px;
  border-radius: 4px;
  margin-top: 15px;
}

.message.success {
  background-color: #d4edda;
  color: #155724;
  border: 1px solid #c3e6cb;
}

.message.error {
  background-color: #f8d7da;
  color: #721c24;
  border: 1px solid #f5c6cb;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.table-filters {
  margin-bottom: 20px;
}

.filter-row {
  display: grid;
  grid-template-columns: 2fr 1fr 1fr;
  gap: 20px;
  align-items: end;
}

.filter-group {
  display: flex;
  flex-direction: column;
}

.filter-group label {
  font-weight: bold;
  margin-bottom: 5px;
  color: var(--p-text-color);
}

.users-table {
  margin-top: 20px;
}

.user-info-cell {
  display: flex;
  align-items: center;
  gap: 12px;
}

.user-details {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.user-name {
  font-weight: bold;
  color: var(--p-text-color);
  font-size: 0.95rem;
}

.user-contact {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 0.85rem;
  color: var(--p-text-muted-color);
}

.role-cell,
.status-cell {
  display: flex;
  align-items: center;
  gap: 8px;
}

.relationships-cell {
  font-size: 0.85rem;
}

.relationship-header {
  display: flex;
  align-items: center;
  gap: 6px;
  font-weight: bold;
  color: var(--p-text-color);
  margin-bottom: 4px;
}

.relationship-item {
  color: var(--p-text-muted-color);
  margin-left: 16px;
  font-size: 0.8rem;
}

.no-relationships {
  color: var(--p-text-muted-color);
}

.date-cell {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 0.85rem;
  color: var(--p-text-muted-color);
}

.empty-state {
  text-align: center;
  padding: 40px;
  color: var(--p-text-muted-color);
}

.empty-state p {
  margin-top: 16px;
  font-size: 1.1rem;
}

.loading {
  text-align: center;
  color: #666;
  padding: 40px;
}

.no-invitations {
  text-align: center;
  color: #666;
  padding: 40px;
  font-style: italic;
}

.invitations-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 20px;
}

.invitation-card {
  border: 1px solid #ddd;
  border-radius: 8px;
  padding: 20px;
  transition: box-shadow 0.2s;
}

.invitation-card:hover {
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
}

.invitation-email {
  font-weight: bold;
  font-size: 1.1rem;
  margin-bottom: 5px;
  color: #333;
}

.invitation-phone {
  color: #666;
  margin-bottom: 5px;
  font-size: 0.9rem;
}

.invitation-meta {
  display: flex;
  gap: 10px;
  margin: 10px 0;
}

.role-badge {
  padding: 2px 8px;
  border-radius: 12px;
  font-weight: bold;
  text-transform: uppercase;
}

.role-admin { color: #dc3545; }
.role-driver { color: #28a745; }
.role-parent { color: #ffc107; }
.role-student { color: #17a2b8; }

.status-badge {
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 0.7rem;
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

.status-badge.pending {
  background-color: #ffc107;
  color: #000;
}

.user-relationships {
  font-size: 0.85rem;
  color: #444;
  margin: 8px 0;
  padding: 8px;
  background-color: #f8f9fa;
  border-radius: 4px;
}

.relationship-item {
  margin-left: 10px;
  color: #666;
  font-size: 0.8rem;
}

.user-dates,
.invitation-details {
  font-size: 0.8rem;
  color: #666;
  margin-top: 10px;
}

.invitation-details div {
  margin-bottom: 3px;
}

.delete-button {
  background-color: #dc3545;
  color: white;
  border: none;
  padding: 6px 12px;
  border-radius: 4px;
  font-size: 0.8rem;
  cursor: pointer;
  margin-top: 10px;
  transition: background-color 0.2s;
}

.delete-button:hover:not(:disabled) {
  background-color: #c82333;
}

.delete-button:disabled {
  background-color: #ccc;
  cursor: not-allowed;
}

/* Section header icon spacing */
.section-header-card h2 {
  display: flex;
  align-items: center;
  gap: 12px;
  margin: 0;
  color: var(--p-primary-700);
  font-size: 1.25rem;
  font-weight: 600;
}

.section-header-card {
  padding: 15px 20px;
  background: var(--p-primary-50);
  border-radius: var(--p-border-radius) var(--p-border-radius) 0 0;
  border-bottom: 1px solid var(--p-surface-border);
}


/* Message container styling */
.message-container {
  margin-top: 15px;
}

.message-card {
  border-radius: 6px;
}

.message-card.success {
  border-left: 4px solid var(--p-green-500);
  background: var(--p-green-50);
}

.message-card.error {
  border-left: 4px solid var(--p-red-500);
  background: var(--p-red-50);
}

.message-content {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px;
}

.message-content i {
  font-size: 1.25rem;
}

.message-card.success .message-content i {
  color: var(--p-green-500);
}

.message-card.error .message-content i {
  color: var(--p-red-500);
}

@media (max-width: 768px) {
  .form-row {
    grid-template-columns: 1fr;
  }
  
  .filter-row {
    grid-template-columns: 1fr;
    gap: 15px;
  }
  
  .invitations-grid {
    grid-template-columns: 1fr;
  }
  
  .section-header {
    flex-direction: column;
    align-items: flex-start;
  }
}
</style>