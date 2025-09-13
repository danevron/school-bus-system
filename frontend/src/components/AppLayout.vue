<template>
  <div class="app-layout">
    <!-- Global Header -->
    <header class="global-header">
      <div class="header-content">
        <div class="brand">
          <i class="pi pi-car brand-icon"></i>
          <span class="brand-text">School Bus System</span>
        </div>
        <div class="user-info">
          <Avatar 
            :label="userInitials" 
            shape="circle"
            class="user-avatar"
          />
          <span class="role-badge" :class="roleClass">{{ userRole }}</span>
          <Button 
            @click="handleLogout" 
            icon="pi pi-sign-out"
            severity="secondary"
            variant="text"
            aria-label="Logout"
            class="logout-button"
          />
        </div>
      </div>
    </header>

    <!-- Page Action Bar -->
    <div class="page-action-bar" v-if="showActionBar">
      <div class="action-bar-content">
        <div class="page-info">
          <div class="breadcrumb" v-if="breadcrumbs.length > 0">
            <span 
              v-for="(crumb, index) in breadcrumbs" 
              :key="index" 
              class="breadcrumb-item"
              :class="{ active: index === breadcrumbs.length - 1 }"
            >
              <router-link v-if="crumb.path && index < breadcrumbs.length - 1" :to="crumb.path">
                {{ crumb.label }}
              </router-link>
              <span v-else>{{ crumb.label }}</span>
              <i v-if="index < breadcrumbs.length - 1" class="pi pi-chevron-right breadcrumb-separator"></i>
            </span>
          </div>
          <h1 class="page-title">{{ pageTitle }}</h1>
        </div>
        <div class="page-actions">
          <slot name="actions"></slot>
        </div>
      </div>
    </div>

    <!-- Main Content -->
    <main class="main-content" :class="{ 'with-action-bar': showActionBar }">
      <slot></slot>
    </main>
  </div>
</template>

<script>
import { computed, inject } from 'vue'
import { useRouter } from 'vue-router'

export default {
  name: 'AppLayout',
  props: {
    pageTitle: {
      type: String,
      default: ''
    },
    breadcrumbs: {
      type: Array,
      default: () => []
    },
    showActionBar: {
      type: Boolean,
      default: true
    }
  },
  setup() {
    const authStore = inject('authStore')
    const router = useRouter()
    
    const userRole = computed(() => {
      const user = authStore.user
      return user?.role || 'guest'
    })
    
    const userInitials = computed(() => {
      const user = authStore.user
      if (!user) return 'U'
      const firstName = user.firstName || ''
      const lastName = user.lastName || ''
      return `${firstName.charAt(0)}${lastName.charAt(0)}`.toUpperCase()
    })
    
    const roleClass = computed(() => {
      return `role-${userRole.value}`
    })
    
    const handleLogout = () => {
      authStore.logout()
      router.push('/login')
    }
    
    return {
      userRole,
      userInitials,
      roleClass,
      handleLogout
    }
  }
}
</script>

<style scoped>
.app-layout {
  min-height: 100vh;
  background-color: var(--p-surface-ground);
}

/* Global Header */
.global-header {
  background: var(--p-primary-500);
  color: white;
  box-shadow: var(--p-shadow-md);
  position: sticky;
  top: 0;
  z-index: 1000;
}

.header-content {
  max-width: 1400px;
  margin: 0 auto;
  padding: 0 1.5rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
  height: 4rem;
}

.brand {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  font-weight: 600;
  font-size: 1.25rem;
}

.brand-icon {
  font-size: 2rem;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.user-avatar {
  background-color: var(--p-surface-0);
  color: var(--p-primary-500);
  font-weight: 600;
}

.role-badge {
  padding: 0.25rem 0.75rem;
  border-radius: 1rem;
  font-size: 0.75rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.role-admin { background-color: var(--p-red-100); color: var(--p-red-700); }
.role-driver { background-color: var(--p-green-100); color: var(--p-green-700); }
.role-parent { background-color: var(--p-yellow-100); color: var(--p-yellow-800); }
.role-student { background-color: var(--p-blue-100); color: var(--p-blue-700); }

.logout-button {
  color: white !important;
  padding: 0.5rem !important;
}

.logout-button:hover {
  background-color: rgba(255, 255, 255, 0.1) !important;
}

/* Page Action Bar */
.page-action-bar {
  background: white;
  border-bottom: 1px solid var(--p-surface-border);
  box-shadow: var(--p-shadow-sm);
  position: sticky;
  top: 4rem;
  z-index: 999;
}

.action-bar-content {
  max-width: 1400px;
  margin: 0 auto;
  padding: 1rem 1.5rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 2rem;
}

.page-info {
  flex: 1;
  min-width: 0;
}

.breadcrumb {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 0.5rem;
  font-size: 0.875rem;
  color: var(--p-text-muted-color);
}

.breadcrumb-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.breadcrumb-item a {
  color: var(--p-primary-500);
  text-decoration: none;
  transition: color 0.2s;
}

.breadcrumb-item a:hover {
  color: var(--p-primary-600);
  text-decoration: underline;
}

.breadcrumb-item.active {
  color: var(--p-text-color);
  font-weight: 500;
}

.breadcrumb-separator {
  font-size: 0.75rem;
  color: var(--p-text-muted-color);
}

.page-title {
  margin: 0;
  font-size: 1.5rem;
  font-weight: 600;
  color: var(--p-text-color);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.page-actions {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  flex-shrink: 0;
}

/* Main Content */
.main-content {
  min-height: calc(100vh - 4rem);
  padding: 1.5rem;
  max-width: 1400px;
  margin: 0 auto;
}

.main-content.with-action-bar {
  min-height: calc(100vh - 4rem - 4.5rem);
}

/* Responsive Design */
@media (max-width: 768px) {
  .header-content {
    padding: 0 1rem;
  }
  
  .brand-text {
    display: none;
  }
  
  .action-bar-content {
    padding: 1rem;
    flex-direction: column;
    align-items: flex-start;
    gap: 1rem;
  }
  
  .page-info {
    width: 100%;
  }
  
  .page-actions {
    width: 100%;
    justify-content: flex-end;
  }
  
  .main-content {
    padding: 1rem;
  }
}

@media (max-width: 640px) {
  .user-info {
    gap: 0.5rem;
  }
  
  .role-badge {
    display: none;
  }
  
  .page-actions {
    flex-wrap: wrap;
    gap: 0.5rem;
  }
}
</style>