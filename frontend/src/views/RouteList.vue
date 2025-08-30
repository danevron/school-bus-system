<template>
  <div class="route-list-container">
    <header class="header">
      <div class="header-content">
        <h1>Route Management</h1>
        <div class="header-actions">
          <button @click="goBack" class="back-button">← Back to Dashboard</button>
          <button @click="handleAddRoute" class="add-route-button">+ Add New Route</button>
        </div>
      </div>
    </header>

    <main class="main-content">
      <div class="content-wrapper">
        <!-- Filters Section -->
        <div class="filters-section">
          <div class="filters">
            <select v-model="routeFilter.isActive" @change="fetchRoutes">
              <option value="">All Routes</option>
              <option value="true">Active Routes</option>
              <option value="false">Inactive Routes</option>
            </select>
          </div>
          <div class="route-count">
            {{ routes.length }} route{{ routes.length !== 1 ? 's' : '' }} found
          </div>
        </div>

        <!-- Routes List Section -->
        <div class="routes-section">
          <div v-if="loading" class="loading">Loading routes...</div>
          
          <div v-else-if="routes.length === 0" class="no-routes">
            <div class="empty-state">
              <h3>No routes found</h3>
              <p>Start by creating your first bus route.</p>
              <button @click="handleAddRoute" class="add-route-button-large">
                + Create First Route
              </button>
            </div>
          </div>

          <div v-else class="routes-grid">
            <div 
              v-for="route in routes" 
              :key="route._id" 
              class="route-card"
              :class="{ inactive: !route.isActive }"
              @click="viewRoute(route._id)"
            >
              <div class="route-header">
                <h3 class="route-name">{{ route.name }}</h3>
                <div class="route-status">
                  <span class="status-badge" :class="route.isActive ? 'active' : 'inactive'">
                    {{ route.isActive ? 'Active' : 'Inactive' }}
                  </span>
                </div>
              </div>

              <div class="route-info">
                <div class="route-stats">
                  <div class="stat-item">
                    <span class="stat-label">Stops:</span>
                    <span class="stat-value">{{ route.stops.length }}</span>
                  </div>
                  <div class="stat-item">
                    <span class="stat-label">Distance:</span>
                    <span class="stat-value">{{ route.totalDistance }} km</span>
                  </div>
                  <div class="stat-item">
                    <span class="stat-label">Duration:</span>
                    <span class="stat-value">{{ formatDuration(route.estimatedDuration) }}</span>
                  </div>
                </div>

                <div class="route-stops-preview">
                  <div class="stops-summary">
                    <strong>Route:</strong>
                    <span v-if="route.stops.length > 0" class="stop-names">
                      {{ getStopNamesPreview(route.stops) }}
                    </span>
                    <span v-else class="no-stops">No stops defined</span>
                  </div>
                </div>

                <div class="route-meta">
                  <div class="route-dates">
                    Created: {{ formatDate(route.createdAt) }}
                  </div>
                  <div class="route-types">
                    <span v-if="hasPickupStops(route.stops)" class="type-badge pickup">
                      Pickup
                    </span>
                    <span v-if="hasDropoffStops(route.stops)" class="type-badge dropoff">
                      Dropoff
                    </span>
                  </div>
                </div>
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
  name: 'RouteList',
  setup() {
    const authStore = inject('authStore')
    const router = useRouter()
    
    const loading = ref(false)
    const routes = ref([])
    
    const routeFilter = ref({
      isActive: ''
    })
    
    const fetchRoutes = async () => {
      try {
        loading.value = true
        const params = new URLSearchParams()
        if (routeFilter.value.isActive) params.append('isActive', routeFilter.value.isActive)
        
        const response = await apiService.get(`/routes?${params.toString()}`)
        routes.value = response.routes
      } catch (error) {
        console.error('Failed to fetch routes:', error)
      } finally {
        loading.value = false
      }
    }
    
    const viewRoute = (routeId) => {
      router.push(`/routes/${routeId}`)
    }
    
    const handleAddRoute = () => {
      router.push('/routes/create')
    }
    
    const formatDate = (dateString) => {
      return new Date(dateString).toLocaleDateString()
    }
    
    const formatDuration = (minutes) => {
      if (minutes < 60) {
        return `${minutes} min`
      }
      const hours = Math.floor(minutes / 60)
      const remainingMinutes = minutes % 60
      return `${hours}h ${remainingMinutes}m`
    }
    
    const getStopNamesPreview = (stops) => {
      if (stops.length === 0) return ''
      if (stops.length <= 3) {
        return stops.map(stop => stop.name).join(' → ')
      }
      return `${stops[0].name} → ... → ${stops[stops.length - 1].name} (${stops.length} stops)`
    }
    
    const hasPickupStops = (stops) => {
      return stops.some(stop => stop.type === 'pickup')
    }
    
    const hasDropoffStops = (stops) => {
      return stops.some(stop => stop.type === 'dropoff')
    }
    
    const goBack = () => {
      router.push('/home')
    }
    
    onMounted(async () => {
      await fetchRoutes()
    })
    
    return {
      loading,
      routes,
      routeFilter,
      fetchRoutes,
      viewRoute,
      handleAddRoute,
      formatDate,
      formatDuration,
      getStopNamesPreview,
      hasPickupStops,
      hasDropoffStops,
      goBack
    }
  }
}
</script>

<style scoped>
.route-list-container {
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

.header-actions {
  display: flex;
  gap: 12px;
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

.add-route-button {
  background-color: #28a745;
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: 4px;
  cursor: pointer;
  transition: background-color 0.2s;
  font-weight: 500;
}

.add-route-button:hover {
  background-color: #218838;
}

.main-content {
  max-width: 1200px;
  margin: 0 auto;
  padding: 30px 20px;
}

.content-wrapper {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.filters-section {
  background: white;
  border-radius: 8px;
  padding: 20px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.filters select {
  padding: 8px 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  background: white;
}

.route-count {
  color: #666;
  font-size: 0.9rem;
}

.routes-section {
  background: white;
  border-radius: 8px;
  padding: 30px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
}

.loading {
  text-align: center;
  color: #666;
  padding: 40px;
  font-size: 1.1rem;
}

.no-routes {
  text-align: center;
  padding: 60px 20px;
}

.empty-state h3 {
  color: #333;
  margin-bottom: 10px;
}

.empty-state p {
  color: #666;
  margin-bottom: 30px;
}

.add-route-button-large {
  background-color: #28a745;
  color: white;
  border: none;
  padding: 12px 24px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 1rem;
  font-weight: 500;
  transition: background-color 0.2s;
}

.add-route-button-large:hover {
  background-color: #218838;
}

.routes-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(400px, 1fr));
  gap: 20px;
}

.route-card {
  border: 1px solid #ddd;
  border-radius: 8px;
  padding: 20px;
  transition: all 0.2s;
  cursor: pointer;
  background: white;
}

.route-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  transform: translateY(-2px);
}

.route-card.inactive {
  opacity: 0.7;
  background-color: #f8f9fa;
}

.route-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 15px;
}

.route-name {
  margin: 0;
  color: #333;
  font-size: 1.25rem;
  font-weight: 600;
}

.status-badge {
  padding: 4px 8px;
  border-radius: 12px;
  font-size: 0.75rem;
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

.route-stats {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 10px;
  margin-bottom: 15px;
  padding: 10px;
  background-color: #f8f9fa;
  border-radius: 4px;
}

.stat-item {
  text-align: center;
}

.stat-label {
  display: block;
  font-size: 0.8rem;
  color: #666;
  margin-bottom: 2px;
}

.stat-value {
  display: block;
  font-weight: 600;
  color: #333;
}

.route-stops-preview {
  margin-bottom: 15px;
}

.stops-summary {
  font-size: 0.9rem;
}

.stop-names {
  color: #666;
  margin-left: 8px;
}

.no-stops {
  color: #999;
  font-style: italic;
  margin-left: 8px;
}

.route-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.8rem;
  color: #666;
}

.route-types {
  display: flex;
  gap: 5px;
}

.type-badge {
  padding: 2px 6px;
  border-radius: 8px;
  font-size: 0.7rem;
  font-weight: bold;
  text-transform: uppercase;
}

.type-badge.pickup {
  background-color: #17a2b8;
  color: white;
}

.type-badge.dropoff {
  background-color: #ffc107;
  color: #000;
}

@media (max-width: 768px) {
  .header-content {
    flex-direction: column;
    gap: 15px;
    text-align: center;
  }
  
  .header-actions {
    justify-content: center;
  }
  
  .filters-section {
    flex-direction: column;
    gap: 15px;
    align-items: stretch;
  }
  
  .routes-grid {
    grid-template-columns: 1fr;
  }
  
  .route-stats {
    grid-template-columns: 1fr;
    gap: 8px;
  }
  
  .route-meta {
    flex-direction: column;
    gap: 8px;
    align-items: flex-start;
  }
}
</style>