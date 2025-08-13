<template>
  <div class="home-container">
    <header class="header">
      <div class="header-content">
        <h1>School Bus System</h1>
        <div class="user-info">
          <span>Welcome, {{ authStore.user?.firstName }} {{ authStore.user?.lastName }}</span>
          <span class="role-badge" :class="roleClass">{{ userRole }}</span>
          <button @click="handleLogout" class="logout-button">Logout</button>
        </div>
      </div>
    </header>

    <main class="main-content">
      <div class="dashboard">
        <div class="welcome-section">
          <h2>Dashboard</h2>
          <p>Welcome to the School Bus Management System. Your role is: <strong>{{ userRole }}</strong></p>
        </div>

        <div class="role-specific-content">
          <!-- Admin View -->
          <div v-if="userRole === 'admin'" class="admin-dashboard">
            <h3>Admin Dashboard</h3>
            <div class="dashboard-cards">
              <div class="dashboard-card">
                <h4>Lines Management</h4>
                <p>Create and manage transportation lines</p>
                <button class="action-button" disabled>Manage Lines</button>
              </div>
              <div class="dashboard-card">
                <h4>Rides Management</h4>
                <p>Generate and monitor rides</p>
                <button class="action-button" disabled>Manage Rides</button>
              </div>
              <div class="dashboard-card">
                <h4>Users Management</h4>
                <p>Manage drivers, parents, and students</p>
                <button class="action-button" @click="goToUserManagement">Manage Users</button>
              </div>
              <div class="dashboard-card">
                <h4>Reports</h4>
                <p>View system reports and analytics</p>
                <button class="action-button" disabled>View Reports</button>
              </div>
            </div>
          </div>

          <!-- Driver View -->
          <div v-if="userRole === 'driver'" class="driver-dashboard">
            <h3>Driver Dashboard</h3>
            <div class="dashboard-cards">
              <div class="dashboard-card">
                <h4>My Rides</h4>
                <p>View and manage your assigned rides</p>
                <button class="action-button" disabled>View Rides</button>
              </div>
              <div class="dashboard-card">
                <h4>Today's Schedule</h4>
                <p>Check today's ride schedule</p>
                <button class="action-button" disabled>View Schedule</button>
              </div>
              <div class="dashboard-card">
                <h4>Student Status</h4>
                <p>Update student pickup/dropoff status</p>
                <button class="action-button" disabled>Update Status</button>
              </div>
            </div>
          </div>

          <!-- Parent View -->
          <div v-if="userRole === 'parent'" class="parent-dashboard">
            <h3>Parent Dashboard</h3>
            <div class="dashboard-cards">
              <div class="dashboard-card">
                <h4>My Children's Rides</h4>
                <p>View your children's ride schedules</p>
                <button class="action-button" disabled>View Rides</button>
              </div>
              <div class="dashboard-card">
                <h4>Book New Ride</h4>
                <p>Book rides for your children</p>
                <button class="action-button" disabled>Book Ride</button>
              </div>
              <div class="dashboard-card">
                <h4>Ride History</h4>
                <p>View past ride bookings</p>
                <button class="action-button" disabled>View History</button>
              </div>
            </div>
          </div>

          <!-- Student View -->
          <div v-if="userRole === 'student'" class="student-dashboard">
            <h3>Student Dashboard</h3>
            <div class="dashboard-cards">
              <div class="dashboard-card">
                <h4>My Rides</h4>
                <p>View your upcoming rides</p>
                <button class="action-button" disabled>View Rides</button>
              </div>
              <div class="dashboard-card">
                <h4>Today's Ride</h4>
                <p>Check today's ride information</p>
                <button class="action-button" disabled>Today's Info</button>
              </div>
              <div class="dashboard-card">
                <h4>Route Information</h4>
                <p>View your route details</p>
                <button class="action-button" disabled>View Route</button>
              </div>
            </div>
          </div>
        </div>

        <div class="system-info">
          <h3>System Information</h3>
          <div class="info-grid">
            <div class="info-item">
              <strong>User ID:</strong> {{ authStore.user?.id }}
            </div>
            <div class="info-item">
              <strong>Email:</strong> {{ authStore.user?.email }}
            </div>
            <div class="info-item">
              <strong>Phone:</strong> {{ authStore.user?.phone }}
            </div>
            <div class="info-item">
              <strong>Active:</strong> {{ authStore.user?.isActive ? 'Yes' : 'No' }}
            </div>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<script>
import { inject, computed } from 'vue'
import { useRouter } from 'vue-router'

export default {
  name: 'Home',
  setup() {
    const authStore = inject('authStore')
    const router = useRouter()
    
    const userRole = computed(() => {
      return authStore.user?.role || 'Unknown'
    })
    
    const roleClass = computed(() => {
      const role = userRole.value.toLowerCase()
      return `role-${role}`
    })
    
    const handleLogout = () => {
      authStore.logout()
      router.push('/login')
    }
    
    const goToUserManagement = () => {
      router.push('/user-management')
    }
    
    return {
      authStore,
      userRole,
      roleClass,
      handleLogout,
      goToUserManagement
    }
  }
}
</script>

<style scoped>
.home-container {
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
  font-size: 1.8rem;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 15px;
}

.role-badge {
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 0.8rem;
  font-weight: bold;
  text-transform: uppercase;
}

.role-admin { background-color: #dc3545; }
.role-driver { background-color: #28a745; }
.role-parent { background-color: #ffc107; color: #000; }
.role-student { background-color: #17a2b8; }

.logout-button {
  background-color: #6c757d;
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: 4px;
  cursor: pointer;
  transition: background-color 0.2s;
}

.logout-button:hover {
  background-color: #545b62;
}

.main-content {
  max-width: 1200px;
  margin: 0 auto;
  padding: 30px 20px;
}

.dashboard {
  background: white;
  border-radius: 8px;
  padding: 30px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
}

.welcome-section {
  margin-bottom: 40px;
  text-align: center;
}

.welcome-section h2 {
  color: #333;
  margin-bottom: 10px;
}

.welcome-section p {
  color: #666;
  font-size: 1.1rem;
}

.role-specific-content {
  margin-bottom: 40px;
}

.role-specific-content h3 {
  color: #333;
  margin-bottom: 20px;
  font-size: 1.5rem;
}

.dashboard-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 20px;
  margin-bottom: 30px;
}

.dashboard-card {
  background: #f8f9fa;
  border: 1px solid #dee2e6;
  border-radius: 8px;
  padding: 20px;
  text-align: center;
}

.dashboard-card h4 {
  color: #333;
  margin-bottom: 10px;
}

.dashboard-card p {
  color: #666;
  margin-bottom: 15px;
  font-size: 0.9rem;
}

.action-button {
  background-color: #007bff;
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: 4px;
  cursor: pointer;
  transition: background-color 0.2s;
}

.action-button:hover:not(:disabled) {
  background-color: #0056b3;
}

.action-button:disabled {
  background-color: #ccc;
  cursor: not-allowed;
}

.system-info {
  border-top: 1px solid #eee;
  padding-top: 20px;
}

.system-info h3 {
  color: #333;
  margin-bottom: 15px;
}

.info-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 15px;
}

.info-item {
  background: #f8f9fa;
  padding: 10px;
  border-radius: 4px;
  border-left: 3px solid #007bff;
}

.info-item strong {
  color: #333;
}
</style>