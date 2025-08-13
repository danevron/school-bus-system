<template>
  <div class="user-management-container">
    <header class="header">
      <div class="header-content">
        <h1>User Management</h1>
        <div class="header-actions">
          <button @click="goBack" class="back-button">← Back to Dashboard</button>
        </div>
      </div>
    </header>

    <main class="main-content">
      <div class="content-wrapper">
        <!-- Invite User Section -->
        <div class="invite-section">
          <h2>Invite New User</h2>
          <form @submit.prevent="handleInvite" class="invite-form">
            <div class="form-row">
              <div class="form-group">
                <label for="email">Email:</label>
                <input 
                  id="email"
                  type="email" 
                  v-model="inviteForm.email" 
                  required 
                  :disabled="loading"
                />
              </div>
              
              <div class="form-group">
                <label for="phone">Phone:</label>
                <input 
                  id="phone"
                  type="tel" 
                  v-model="inviteForm.phone" 
                  required 
                  :disabled="loading"
                />
              </div>
              
              <div class="form-group">
                <label for="role">Role:</label>
                <select 
                  id="role"
                  v-model="inviteForm.role" 
                  required 
                  :disabled="loading"
                >
                  <option value="">Select role...</option>
                  <option value="admin">Admin</option>
                  <option value="driver">Driver</option>
                  <option value="parent">Parent</option>
                  <option value="student">Student</option>
                </select>
              </div>
            </div>
            
            <button 
              type="submit" 
              class="invite-button"
              :disabled="loading"
            >
              {{ loading ? 'Sending...' : 'Send Invitation' }}
            </button>
          </form>
          
          <div v-if="message" class="message" :class="messageType">
            {{ message }}
          </div>
        </div>

        <!-- Users List Section -->
        <div class="users-section">
          <div class="section-header">
            <h2>All Users</h2>
            <div class="filters">
              <select v-model="userFilter.role" @change="fetchUsers">
                <option value="">All Roles</option>
                <option value="admin">Admin</option>
                <option value="driver">Driver</option>
                <option value="parent">Parent</option>
                <option value="student">Student</option>
              </select>
              <select v-model="userFilter.isActive" @change="fetchUsers">
                <option value="">All Status</option>
                <option value="true">Active</option>
                <option value="false">Inactive</option>
              </select>
            </div>
          </div>

          <div v-if="loadingUsers" class="loading">Loading users...</div>
          
          <div v-else-if="users.length === 0" class="no-users">
            No users found.
          </div>

          <div v-else class="users-grid">
            <div 
              v-for="user in users" 
              :key="user.id" 
              class="user-card"
              :class="{ inactive: !user.isActive }"
            >
              <div class="user-info">
                <div class="user-name">{{ user.firstName }} {{ user.lastName }}</div>
                <div class="user-email">{{ user.email }}</div>
                <div class="user-phone">{{ user.phone }}</div>
                <div class="user-meta">
                  <span class="role-badge" :class="`role-${user.role}`">
                    {{ user.role }}
                  </span>
                  <span class="status-badge" :class="user.isActive ? 'active' : 'inactive'">
                    {{ user.isActive ? 'Active' : 'Inactive' }}
                  </span>
                </div>
                <div class="user-dates">
                  Created: {{ formatDate(user.createdAt) }}
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Invitations Section -->
        <div class="invitations-section">
          <h2>Pending Invitations</h2>
          
          <div v-if="loadingInvitations" class="loading">Loading invitations...</div>
          
          <div v-else-if="invitations.length === 0" class="no-invitations">
            No pending invitations.
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
                  <div>Invited by: {{ invitation.invitedBy.firstName }} {{ invitation.invitedBy.lastName }}</div>
                  <div>Expires: {{ formatDate(invitation.expiresAt) }}</div>
                </div>
                <button 
                  @click="deleteInvitation(invitation._id)" 
                  class="delete-button"
                  :disabled="loading"
                >
                  Delete
                </button>
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
  name: 'UserManagement',
  setup() {
    const authStore = inject('authStore')
    const router = useRouter()
    
    const loading = ref(false)
    const loadingUsers = ref(false)
    const loadingInvitations = ref(false)
    const message = ref('')
    const messageType = ref('success')
    
    const inviteForm = ref({
      email: '',
      phone: '',
      role: ''
    })
    
    const users = ref([])
    const invitations = ref([])
    
    const userFilter = ref({
      role: '',
      isActive: ''
    })
    
    const handleInvite = async () => {
      try {
        loading.value = true
        message.value = ''
        
        await apiService.post('/invitations', inviteForm.value)
        
        message.value = 'Invitation sent successfully!'
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
        message.value = error.response?.data?.message || 'Failed to send invitation'
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
        
        const response = await apiService.get(`/auth/users?${params.toString()}`)
        users.value = response.users
      } catch (error) {
        console.error('Failed to fetch users:', error)
      } finally {
        loadingUsers.value = false
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
      if (!confirm('Are you sure you want to delete this invitation?')) return
      
      try {
        await apiService.delete(`/invitations/${invitationId}`)

        await fetchInvitations() // Refresh list
        message.value = 'Invitation deleted successfully'
        messageType.value = 'success'
      } catch (error) {
        message.value = error.response?.data?.message || 'Failed to delete invitation'
        messageType.value = 'error'
      }
    }
    
    const formatDate = (dateString) => {
      return new Date(dateString).toLocaleDateString()
    }
    
    const goBack = () => {
      router.push('/home')
    }
    
    onMounted(async () => {
      await Promise.all([
        fetchUsers(),
        fetchInvitations()
      ])
    })
    
    return {
      loading,
      loadingUsers,
      loadingInvitations,
      message,
      messageType,
      inviteForm,
      users,
      invitations,
      userFilter,
      handleInvite,
      fetchUsers,
      deleteInvitation,
      formatDate,
      goBack
    }
  }
}
</script>

<style scoped>
.user-management-container {
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

.main-content {
  max-width: 1200px;
  margin: 0 auto;
  padding: 30px 20px;
}

.content-wrapper > div {
  background: white;
  border-radius: 8px;
  padding: 30px;
  margin-bottom: 30px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
}

.invite-section h2,
.users-section h2,
.invitations-section h2 {
  color: #333;
  margin-bottom: 20px;
}

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
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
}

.form-group input:focus,
.form-group select:focus {
  outline: none;
  border-color: #007bff;
}

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

.invite-button:hover:not(:disabled) {
  background-color: #218838;
}

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

.filters {
  display: flex;
  gap: 10px;
}

.filters select {
  padding: 6px 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.loading {
  text-align: center;
  color: #666;
  padding: 40px;
}

.no-users,
.no-invitations {
  text-align: center;
  color: #666;
  padding: 40px;
  font-style: italic;
}

.users-grid,
.invitations-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 20px;
}

.user-card,
.invitation-card {
  border: 1px solid #ddd;
  border-radius: 8px;
  padding: 20px;
  transition: box-shadow 0.2s;
}

.user-card:hover,
.invitation-card:hover {
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
}

.user-card.inactive {
  opacity: 0.6;
  background-color: #f8f9fa;
}

.user-name,
.invitation-email {
  font-weight: bold;
  font-size: 1.1rem;
  margin-bottom: 5px;
  color: #333;
}

.user-email,
.user-phone,
.invitation-phone {
  color: #666;
  margin-bottom: 5px;
  font-size: 0.9rem;
}

.user-meta,
.invitation-meta {
  display: flex;
  gap: 10px;
  margin: 10px 0;
}

.role-badge {
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 0.7rem;
  font-weight: bold;
  text-transform: uppercase;
}

.role-admin { background-color: #dc3545; color: white; }
.role-driver { background-color: #28a745; color: white; }
.role-parent { background-color: #ffc107; color: #000; }
.role-student { background-color: #17a2b8; color: white; }

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

@media (max-width: 768px) {
  .form-row {
    grid-template-columns: 1fr;
  }
  
  .users-grid,
  .invitations-grid {
    grid-template-columns: 1fr;
  }
  
  .section-header {
    flex-direction: column;
    align-items: flex-start;
  }
  
  .filters {
    margin-top: 10px;
  }
}
</style>