<template>
  <AppLayout 
    page-title="Dashboard" 
    :show-action-bar="false"
  >
      <Card class="dashboard">
        <template #content>
          <div class="welcome-section">
            <h2>Welcome to the School Bus Management System</h2>
          </div>

          <div class="role-specific-content">
            <!-- Admin View -->
            <div v-if="userRole === 'admin'" class="admin-dashboard">
              <div class="dashboard-cards">
                <Card class="dashboard-card">
                  <template #title>
                    <h4>Lines Management</h4>
                  </template>
                  <template #content>
                    <p>Create and manage transportation lines with routes</p>
                    <Button @click="goToLineManagement" class="w-full">
                      Manage Lines
                    </Button>
                  </template>
                </Card>
                
                <Card class="dashboard-card">
                  <template #title>
                    <h4>Users Management</h4>
                  </template>
                  <template #content>
                    <p>Manage drivers, parents, and students</p>
                    <Button @click="goToUserManagement" class="w-full">
                      Manage Users
                    </Button>
                  </template>
                </Card>
                
                <Card class="dashboard-card">
                  <template #title>
                    <h4>Ride Management</h4>
                  </template>
                  <template #content>
                    <p>Create and manage individual rides</p>
                    <Button @click="goToRideManagement" class="w-full">
                      Manage Rides
                    </Button>
                  </template>
                </Card>
              </div>
            </div>

            <!-- Driver View -->
            <div v-if="userRole === 'driver'" class="driver-dashboard">
              <h3>Driver Dashboard</h3>
              <div class="dashboard-cards">
                <Card class="dashboard-card">
                  <template #title>
                    <h4>My Lines</h4>
                  </template>
                  <template #content>
                    <p>View and manage your assigned transportation lines</p>
                    <Button disabled class="w-full" severity="secondary">
                      View Lines
                    </Button>
                  </template>
                </Card>
                
                <Card class="dashboard-card">
                  <template #title>
                    <h4>Today's Schedule</h4>
                  </template>
                  <template #content>
                    <p>Check today's transportation schedule</p>
                    <Button disabled class="w-full" severity="secondary">
                      View Schedule
                    </Button>
                  </template>
                </Card>
                
                <Card class="dashboard-card">
                  <template #title>
                    <h4>Student Status</h4>
                  </template>
                  <template #content>
                    <p>Update student pickup/dropoff status</p>
                    <Button disabled class="w-full" severity="secondary">
                      Update Status
                    </Button>
                  </template>
                </Card>
              </div>
            </div>

            <!-- Parent View -->
            <div v-if="userRole === 'parent'" class="parent-dashboard">
              <h3>Parent Dashboard</h3>
              <div class="dashboard-cards">
                <Card class="dashboard-card">
                  <template #title>
                    <h4>My Children's Transportation</h4>
                  </template>
                  <template #content>
                    <p>View your children's transportation schedules</p>
                    <Button disabled class="w-full" severity="secondary">
                      View Transportation
                    </Button>
                  </template>
                </Card>
                
                <Card class="dashboard-card">
                  <template #title>
                    <h4>Transportation Status</h4>
                  </template>
                  <template #content>
                    <p>View your children's current transportation assignments</p>
                    <Button disabled class="w-full" severity="secondary">
                      View Assignments
                    </Button>
                  </template>
                </Card>
              </div>
            </div>

            <!-- Student View -->
            <div v-if="userRole === 'student'" class="student-dashboard">
              <h3>Student Dashboard</h3>
              <div class="dashboard-cards">
                <Card class="dashboard-card">
                  <template #title>
                    <h4>My Transportation</h4>
                  </template>
                  <template #content>
                    <p>View your assigned transportation lines</p>
                    <Button disabled class="w-full" severity="secondary">
                      View Transportation
                    </Button>
                  </template>
                </Card>
                
                <Card class="dashboard-card">
                  <template #title>
                    <h4>Today's Schedule</h4>
                  </template>
                  <template #content>
                    <p>Check today's transportation information</p>
                    <Button disabled class="w-full" severity="secondary">
                      Today's Info
                    </Button>
                  </template>
                </Card>
                
                <Card class="dashboard-card">
                  <template #title>
                    <h4>Route Information</h4>
                  </template>
                  <template #content>
                    <p>View your route details</p>
                    <Button disabled class="w-full" severity="secondary">
                      View Route
                    </Button>
                  </template>
                </Card>
              </div>
            </div>
          </div>
        </template>
      </Card>
  </AppLayout>
</template>

<script>
import { inject, computed } from 'vue'
import { useRouter } from 'vue-router'
import AppLayout from '../components/AppLayout.vue'

export default {
  name: 'Home',
  components: {
    AppLayout
  },
  setup() {
    const authStore = inject('authStore')
    const router = useRouter()
    
    const userRole = computed(() => {
      return authStore.user?.role || 'Unknown'
    })
    
    const goToUserManagement = () => {
      router.push('/user-management')
    }
    
    const goToLineManagement = () => {
      router.push('/lines')
    }
    
    const goToRideManagement = () => {
      router.push('/rides')
    }
    
    return {
      userRole,
      goToUserManagement,
      goToLineManagement,
      goToRideManagement
    }
  }
}
</script>

<style scoped>
/* Dashboard specific styles */

.welcome-section {
  margin-bottom: 40px;
  text-align: center;
}

.welcome-section h2 {
  color: var(--p-text-color);
  margin-bottom: 10px;
}

.welcome-section p {
  color: var(--p-text-muted-color);
  font-size: 1.1rem;
}

.role-specific-content {
  margin-bottom: 40px;
}

.role-specific-content h3 {
  color: var(--p-text-color);
  margin-bottom: 20px;
  font-size: 1.5rem;
}

.dashboard-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 20px;
  margin-bottom: 30px;
}

.dashboard-card {
  text-align: center;
}

.dashboard-card h4 {
  color: var(--p-text-color);
  margin: 0;
  font-size: 1.1rem;
}

.dashboard-card p {
  color: var(--p-text-muted-color);
  margin-bottom: 15px;
  font-size: 0.95rem;
  line-height: 1.4;
}
</style>