<template>
  <div class="route-create-container">
    <header class="header">
      <div class="header-content">
        <h1>Create New Route</h1>
        <div class="header-actions">
          <button @click="goBack" class="back-button">← Back to Routes</button>
        </div>
      </div>
    </header>

    <main class="main-content">
      <div class="content-wrapper">
        <div class="create-route-section">
          <div class="form-container">
            <h2>Route Information</h2>
            <form @submit.prevent="handleCreateRoute" class="route-form">
              <div class="form-group">
                <label for="routeName">Route Name *</label>
                <input 
                  id="routeName"
                  type="text" 
                  v-model="routeForm.name" 
                  required 
                  :disabled="loading"
                  placeholder="Enter route name (e.g., 'Downtown to School')"
                  maxlength="100"
                />
              </div>

              <div class="form-group">
                <label for="routeDescription">Description</label>
                <textarea 
                  id="routeDescription"
                  v-model="routeForm.description" 
                  :disabled="loading"
                  placeholder="Optional description of the route"
                  rows="3"
                  maxlength="500"
                ></textarea>
              </div>

              <div class="form-actions">
                <button 
                  type="button"
                  @click="goBack"
                  class="cancel-button"
                  :disabled="loading"
                >
                  Cancel
                </button>
                <button 
                  type="submit" 
                  class="create-button"
                  :disabled="loading || !routeForm.name.trim()"
                >
                  {{ loading ? 'Creating...' : 'Create Route' }}
                </button>
              </div>
            </form>

            <div v-if="message" class="message" :class="messageType">
              {{ message }}
            </div>
          </div>

          <div class="info-panel">
            <h3>📍 About Route Creation</h3>
            <div class="info-content">
              <p><strong>Step 1:</strong> Create your route with a name and optional description.</p>
              <p><strong>Step 2:</strong> After creation, you'll be taken to the route details page where you can:</p>
              <ul>
                <li>Add pickup and dropoff stops</li>
                <li>Set coordinates and timing for each stop</li>
                <li>Reorder stops by dragging</li>
                <li>View the route on an interactive map</li>
              </ul>
              <p><strong>Note:</strong> You can save a route without stops and add them later.</p>
            </div>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<script>
import { ref, inject } from 'vue'
import { useRouter } from 'vue-router'
import apiService from '../services/api'

export default {
  name: 'RouteCreate',
  setup() {
    const authStore = inject('authStore')
    const router = useRouter()
    
    const loading = ref(false)
    const message = ref('')
    const messageType = ref('success')
    
    const routeForm = ref({
      name: '',
      description: '',
      stops: [],
      totalDistance: 0,
      estimatedDuration: 0
    })
    
    const handleCreateRoute = async () => {
      try {
        loading.value = true
        message.value = ''
        
        const routeData = {
          name: routeForm.value.name.trim(),
          description: routeForm.value.description.trim(),
          stops: [], // Empty stops array - stops will be added later
          totalDistance: 0, // Will be calculated when stops are added
          estimatedDuration: 0 // Will be calculated when stops are added
        }
        
        const response = await apiService.post('/routes', routeData)
        
        message.value = 'Route created successfully! Redirecting...'
        messageType.value = 'success'
        
        // Redirect to the newly created route detail page
        setTimeout(() => {
          router.push(`/routes/${response.route._id}`)
        }, 1500)
        
      } catch (error) {
        console.error('Failed to create route:', error)
        message.value = error.response?.data?.message || 'Failed to create route'
        messageType.value = 'error'
      } finally {
        loading.value = false
      }
    }
    
    const goBack = () => {
      router.push('/routes')
    }
    
    return {
      loading,
      message,
      messageType,
      routeForm,
      handleCreateRoute,
      goBack
    }
  }
}
</script>

<style scoped>
.route-create-container {
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

.content-wrapper {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.create-route-section {
  display: grid;
  grid-template-columns: 1fr 300px;
  gap: 30px;
  align-items: start;
}

.form-container {
  background: white;
  border-radius: 8px;
  padding: 30px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
}

.form-container h2 {
  color: #333;
  margin-bottom: 20px;
  border-bottom: 2px solid #e9ecef;
  padding-bottom: 10px;
}

.route-form {
  margin-bottom: 20px;
}

.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  margin-bottom: 5px;
  color: #333;
  font-weight: bold;
}

.form-group input,
.form-group textarea {
  width: 100%;
  padding: 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
  transition: border-color 0.2s;
}

.form-group input:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #007bff;
  box-shadow: 0 0 0 3px rgba(0, 123, 255, 0.1);
}

.form-group input:disabled,
.form-group textarea:disabled {
  background-color: #f8f9fa;
  cursor: not-allowed;
}

.form-group textarea {
  resize: vertical;
  min-height: 80px;
}

.form-actions {
  display: flex;
  gap: 15px;
  justify-content: flex-end;
  margin-top: 30px;
}

.cancel-button,
.create-button {
  padding: 12px 24px;
  border: none;
  border-radius: 4px;
  font-size: 16px;
  cursor: pointer;
  transition: background-color 0.2s;
  font-weight: 500;
}

.cancel-button {
  background-color: #6c757d;
  color: white;
}

.cancel-button:hover:not(:disabled) {
  background-color: #545b62;
}

.create-button {
  background-color: #28a745;
  color: white;
}

.create-button:hover:not(:disabled) {
  background-color: #218838;
}

.cancel-button:disabled,
.create-button:disabled {
  background-color: #ccc;
  cursor: not-allowed;
}

.message {
  padding: 12px;
  border-radius: 4px;
  margin-top: 15px;
  font-weight: 500;
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

.info-panel {
  background: white;
  border-radius: 8px;
  padding: 25px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  height: fit-content;
}

.info-panel h3 {
  color: #333;
  margin-bottom: 15px;
  font-size: 1.1rem;
}

.info-content p {
  color: #666;
  margin-bottom: 12px;
  line-height: 1.5;
  font-size: 0.9rem;
}

.info-content ul {
  color: #666;
  margin: 10px 0 15px 20px;
  font-size: 0.9rem;
}

.info-content li {
  margin-bottom: 5px;
  line-height: 1.4;
}

@media (max-width: 768px) {
  .header-content {
    flex-direction: column;
    gap: 15px;
    text-align: center;
  }
  
  .create-route-section {
    grid-template-columns: 1fr;
  }
  
  .form-actions {
    flex-direction: column;
  }
  
  .cancel-button,
  .create-button {
    width: 100%;
  }
}
</style>