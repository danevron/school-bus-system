<template>
  <AppLayout 
    :page-title="$t('navigation.dashboard')" 
    :show-action-bar="false"
  >
      <Card class="dashboard">
        <template #content>
          <div class="welcome-section">
            <h2>{{ $t('home.welcome') }}</h2>
          </div>

          <div class="role-specific-content">
            <!-- Admin View -->
            <div v-if="userRole === 'admin'" class="admin-dashboard">
              <div class="dashboard-cards">
                <Card class="dashboard-card">
                  <template #title>
                    <h4>{{ $t('home.admin.linesManagement.title') }}</h4>
                  </template>
                  <template #content>
                    <p>{{ $t('home.admin.linesManagement.description') }}</p>
                    <Button @click="goToLineManagement" class="w-full">
                      {{ $t('home.admin.linesManagement.button') }}
                    </Button>
                  </template>
                </Card>
                
                <Card class="dashboard-card">
                  <template #title>
                    <h4>{{ $t('home.admin.usersManagement.title') }}</h4>
                  </template>
                  <template #content>
                    <p>{{ $t('home.admin.usersManagement.description') }}</p>
                    <Button @click="goToUserManagement" class="w-full">
                      {{ $t('home.admin.usersManagement.button') }}
                    </Button>
                  </template>
                </Card>
                
                <Card class="dashboard-card">
                  <template #title>
                    <h4>{{ $t('home.admin.rideManagement.title') }}</h4>
                  </template>
                  <template #content>
                    <p>{{ $t('home.admin.rideManagement.description') }}</p>
                    <Button @click="goToRideManagement" class="w-full">
                      {{ $t('home.admin.rideManagement.button') }}
                    </Button>
                  </template>
                </Card>
              </div>
            </div>

            <!-- Driver View -->
            <div v-if="userRole === 'driver'" class="driver-dashboard">
              <h3>{{ $t('home.driver.title') }}</h3>
              <div class="dashboard-cards">
                <Card class="dashboard-card">
                  <template #title>
                    <h4>{{ $t('home.driver.myLines.title') }}</h4>
                  </template>
                  <template #content>
                    <p>{{ $t('home.driver.myLines.description') }}</p>
                    <Button disabled class="w-full" severity="secondary">
                      {{ $t('home.driver.myLines.button') }}
                    </Button>
                  </template>
                </Card>
                
                <Card class="dashboard-card">
                  <template #title>
                    <h4>{{ $t('home.driver.todaySchedule.title') }}</h4>
                  </template>
                  <template #content>
                    <p>{{ $t('home.driver.todaySchedule.description') }}</p>
                    <Button disabled class="w-full" severity="secondary">
                      {{ $t('home.driver.todaySchedule.button') }}
                    </Button>
                  </template>
                </Card>
                
                <Card class="dashboard-card">
                  <template #title>
                    <h4>{{ $t('home.driver.studentStatus.title') }}</h4>
                  </template>
                  <template #content>
                    <p>{{ $t('home.driver.studentStatus.description') }}</p>
                    <Button disabled class="w-full" severity="secondary">
                      {{ $t('home.driver.studentStatus.button') }}
                    </Button>
                  </template>
                </Card>
              </div>
            </div>

            <!-- Parent View -->
            <div v-if="userRole === 'parent'" class="parent-dashboard">
              <h3>{{ $t('home.parent.title') }}</h3>
              <div class="dashboard-cards">
                <Card class="dashboard-card">
                  <template #title>
                    <h4>{{ $t('home.parent.childrenTransportation.title') }}</h4>
                  </template>
                  <template #content>
                    <p>{{ $t('home.parent.childrenTransportation.description') }}</p>
                    <Button disabled class="w-full" severity="secondary">
                      {{ $t('home.parent.childrenTransportation.button') }}
                    </Button>
                  </template>
                </Card>
                
                <Card class="dashboard-card">
                  <template #title>
                    <h4>{{ $t('home.parent.transportationStatus.title') }}</h4>
                  </template>
                  <template #content>
                    <p>{{ $t('home.parent.transportationStatus.description') }}</p>
                    <Button disabled class="w-full" severity="secondary">
                      {{ $t('home.parent.transportationStatus.button') }}
                    </Button>
                  </template>
                </Card>
              </div>
            </div>

            <!-- Student View -->
            <div v-if="userRole === 'student'" class="student-dashboard">
              <h3>{{ $t('home.student.title') }}</h3>
              <div class="dashboard-cards">
                <Card class="dashboard-card">
                  <template #title>
                    <h4>{{ $t('home.student.myTransportation.title') }}</h4>
                  </template>
                  <template #content>
                    <p>{{ $t('home.student.myTransportation.description') }}</p>
                    <Button disabled class="w-full" severity="secondary">
                      {{ $t('home.student.myTransportation.button') }}
                    </Button>
                  </template>
                </Card>
                
                <Card class="dashboard-card">
                  <template #title>
                    <h4>{{ $t('home.student.todaySchedule.title') }}</h4>
                  </template>
                  <template #content>
                    <p>{{ $t('home.student.todaySchedule.description') }}</p>
                    <Button disabled class="w-full" severity="secondary">
                      {{ $t('home.student.todaySchedule.button') }}
                    </Button>
                  </template>
                </Card>
                
                <Card class="dashboard-card">
                  <template #title>
                    <h4>{{ $t('home.student.routeInformation.title') }}</h4>
                  </template>
                  <template #content>
                    <p>{{ $t('home.student.routeInformation.description') }}</p>
                    <Button disabled class="w-full" severity="secondary">
                      {{ $t('home.student.routeInformation.button') }}
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