<template>
  <AppLayout 
    :page-title="$t('registrations.create.title')" 
    :show-action-bar="true"
    :breadcrumbs="breadcrumbItems"
  >
    <template #actions>
      <div class="action-buttons">
        <Button 
          :label="$t('common.cancel')" 
          icon="pi pi-times"
          severity="secondary"
          outlined
          @click="goBack"
        />
        <Button 
          :label="$t('common.save')" 
          icon="pi pi-check"
          severity="success"
          type="submit"
          @click="saveRegistration"
          :loading="saving"
        />
      </div>
    </template>

    <form @submit.prevent="saveRegistration" class="registration-form">
      <!-- Basic Information Card -->
      <Card class="form-section">
        <template #title>
          <div class="section-header">
            <i class="pi pi-info-circle"></i>
            <span>{{ $t('registrations.create.basicInfo') }}</span>
          </div>
        </template>
        <template #content>
          <div class="form-grid">
            <div class="form-group">
              <label for="title" class="form-label required">{{ $t('registrations.title') }}</label>
              <InputText 
                id="title"
                v-model="registration.title" 
                :placeholder="$t('registrations.create.titlePlaceholder')"
                :invalid="!!errors.title"
                fluid
                required
              />
              <small v-if="errors.title" class="error-message">{{ errors.title }}</small>
            </div>
            
            <div class="form-group">
              <label for="type" class="form-label required">{{ $t('registrations.type') }}</label>
              <Select 
                id="type"
                v-model="registration.type" 
                :options="typeOptions"
                option-label="label"
                option-value="value"
                :placeholder="$t('registrations.create.typePlaceholder')"
                :invalid="!!errors.type"
                fluid
                required
              />
              <small v-if="errors.type" class="error-message">{{ errors.type }}</small>
            </div>
            
            <div class="form-group full-width">
              <label for="description" class="form-label">{{ $t('registrations.description') }}</label>
              <Textarea 
                id="description"
                v-model="registration.description" 
                :placeholder="$t('registrations.create.descriptionPlaceholder')"
                rows="3"
                auto-resize
                class="description-textarea"
                @input="handleDescriptionInput"
              />
            </div>
          </div>
        </template>
      </Card>

      <!-- Stops Management Card -->
      <Card class="form-section">
        <template #title>
          <div class="section-header">
            <i class="pi pi-map-marker"></i>
            <span>{{ $t('registrations.create.stopsManagement') }}</span>
          </div>
        </template>
        <template #content>
          <div class="stops-section">
            <div class="stops-header">
              <p class="stops-description">{{ $t('registrations.create.stopsDescription') }}</p>
              <Button 
                :label="$t('registrations.create.addStop')" 
                icon="pi pi-plus"
                severity="success"
                size="small"
                @click="addNewStop"
              />
            </div>

            <DataTable 
              v-model:editingRows="editingRows"
              :value="registration.stops" 
              editMode="row"
              dataKey="id"
              @row-edit-save="onRowEditSave"
              @row-edit-cancel="onRowEditCancel"
              :pt="{
                table: { style: 'min-width: 50rem' },
                column: {
                  bodycell: ({ state }) => ({
                    style: state['d_editing'] && 'padding-top: 0.6rem; padding-bottom: 0.6rem'
                  })
                }
              }"
              class="stops-table"
            >
              <template #empty>
                <div class="empty-state">
                  <i class="pi pi-map-marker empty-icon"></i>
                  <h4>{{ $t('registrations.create.noStops') }}</h4>
                  <p>{{ $t('registrations.create.noStopsDescription') }}</p>
                  <Button 
                    :label="$t('registrations.create.addFirstStop')" 
                    icon="pi pi-plus"
                    severity="success"
                    @click="addNewStop"
                  />
                </div>
              </template>

              <Column 
                field="name" 
                :header="$t('registrations.create.stops.name')"
                style="width: 40%"
              >
                <template #body="{ data }">
                  {{ data.name }}
                </template>
                <template #editor="{ data, field }">
                  <InputText 
                    v-model="data[field]" 
                    :placeholder="$t('registrations.create.stopNamePlaceholder')"
                    fluid
                  />
                </template>
              </Column>

              <Column 
                field="description" 
                :header="$t('registrations.create.stops.description')"
                style="width: 40%"
              >
                <template #body="{ data }">
                  {{ data.description || '-' }}
                </template>
                <template #editor="{ data, field }">
                  <InputText 
                    v-model="data[field]" 
                    :placeholder="$t('registrations.create.stopDescriptionPlaceholder')"
                    fluid
                  />
                </template>
              </Column>

              <Column :rowEditor="true" style="width: 10%; min-width: 8rem" bodyStyle="text-align:center">
              </Column>

              <Column style="width: 10%; min-width: 8rem" bodyStyle="text-align:center">
                <template #body="{ data, index }">
                  <Button 
                    icon="pi pi-trash" 
                    severity="danger"
                    text
                    rounded
                    @click="removeStop(index)"
                    v-tooltip="$t('common.delete')"
                  />
                </template>
              </Column>
            </DataTable>
          </div>
        </template>
      </Card>
    </form>
  </AppLayout>
</template>

<script>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import AppLayout from '../components/AppLayout.vue'
import apiService from '../services/api.js'

export default {
  name: 'RegistrationCreate',
  components: {
    AppLayout
  },
  setup() {
    const router = useRouter()
    const { t } = useI18n()
    
    // Reactive data
    const registration = ref({
      title: '',
      description: '',
      type: '',
      stops: []
    })
    
    const saving = ref(false)
    const errors = ref({})
    const editingRows = ref([])
    
    // Options
    const typeOptions = computed(() => [
      { label: t('registrations.types.pickup'), value: 'pickup' },
      { label: t('registrations.types.return'), value: 'return' }
    ])
    
    // Breadcrumb
    const breadcrumbItems = computed(() => [
      { label: t('navigation.dashboard'), path: '/home' },
      { label: t('registrations.title'), path: '/registrations' },
      { label: t('registrations.create.title') }
    ])
    
    // Stop management
    let stopIdCounter = 1
    
    const addNewStop = () => {
      const newStop = {
        id: stopIdCounter++,
        name: '',
        description: ''
      }
      
      registration.value.stops.push(newStop)
      
      // Start editing the new row immediately
      editingRows.value = [newStop]
    }
    
    const removeStop = (index) => {
      // Remove from editing rows if it's being edited
      const stopToRemove = registration.value.stops[index]
      editingRows.value = editingRows.value.filter(row => row.id !== stopToRemove.id)
      
      // Remove from stops array
      registration.value.stops.splice(index, 1)
    }
    
    const onRowEditSave = (event) => {
      const { newData, index } = event
      
      // Validate stop data
      if (!newData.name || !newData.name.trim()) {
        // Don't save if name is empty
        return
      }
      
      registration.value.stops[index] = newData
    }
    
    const onRowEditCancel = (event) => {
      const { index } = event
      const stop = registration.value.stops[index]
      
      // If it's a new stop with no name, remove it
      if (!stop.name || !stop.name.trim()) {
        removeStop(index)
      }
    }
    
    // Form validation
    const validateForm = () => {
      errors.value = {}
      
      if (!registration.value.title || !registration.value.title.trim()) {
        errors.value.title = t('registrations.create.errors.titleRequired')
      }
      
      if (!registration.value.type) {
        errors.value.type = t('registrations.create.errors.typeRequired')
      }
      
      return Object.keys(errors.value).length === 0
    }
    
    // Actions
    const saveRegistration = async () => {
      if (!validateForm()) {
        return
      }
      
      saving.value = true
      
      try {
        const registrationData = {
          title: registration.value.title.trim(),
          type: registration.value.type,
          description: registration.value.description ? registration.value.description.trim() : '',
          stops: registration.value.stops.filter(stop => stop.name && stop.name.trim()).map(stop => ({
            name: stop.name.trim(),
            description: stop.description ? stop.description.trim() : ''
          }))
        }
        
        await apiService.post('/registrations', registrationData)
        
        // Navigate back to registrations list
        router.push('/registrations')
      } catch (error) {
        console.error('Error saving registration:', error)
        // Handle error (could add toast notification here)
      } finally {
        saving.value = false
      }
    }
    
    const goBack = () => {
      router.push('/registrations')
    }
    
    const handleDescriptionInput = (event) => {
      registration.value.description = event.target.value
    }
    
    return {
      registration,
      saving,
      errors,
      editingRows,
      typeOptions,
      breadcrumbItems,
      addNewStop,
      removeStop,
      onRowEditSave,
      onRowEditCancel,
      saveRegistration,
      goBack,
      handleDescriptionInput
    }
  }
}
</script>

<style scoped>
.registration-form {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

/* Action Buttons */
.action-buttons {
  display: flex;
  gap: 1rem;
}

/* Form Sections */
.form-section {
  margin-bottom: 0;
}

.section-header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  color: var(--p-primary-color);
  font-weight: 600;
}

.section-header i {
  font-size: 1.25rem;
}

/* Form Grid */
.form-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1.5rem;
  align-items: start;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.form-group.full-width {
  grid-column: 1 / -1;
}

.form-label {
  font-weight: 600;
  color: var(--p-text-color);
  font-size: 0.875rem;
}

.form-label.required::after {
  content: ' *';
  color: var(--p-red-500);
}

.error-message {
  color: var(--p-red-500);
  font-size: 0.75rem;
}

/* Stops Section */
.stops-section {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.stops-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 1rem;
}

.stops-description {
  color: var(--p-text-muted-color);
  margin: 0;
  flex: 1;
}

.stops-table {
  border: 1px solid var(--p-surface-border);
  border-radius: var(--p-border-radius);
}

/* Empty State */
.empty-state {
  text-align: center;
  padding: 3rem 1rem;
}

.empty-icon {
  font-size: 3rem;
  color: var(--p-text-muted-color);
  margin-bottom: 1rem;
}

.empty-state h4 {
  color: var(--p-text-color);
  margin-bottom: 1rem;
  font-size: 1.25rem;
}

.empty-state p {
  color: var(--p-text-muted-color);
  margin-bottom: 2rem;
  max-width: 400px;
  margin-left: auto;
  margin-right: auto;
}

/* Description Textarea */
.description-textarea {
  min-height: 3rem;
  resize: vertical;
}

/* Responsive Design */
@media (max-width: 768px) {
  .form-grid {
    grid-template-columns: 1fr;
  }
  
  .stops-header {
    flex-direction: column;
    align-items: stretch;
  }
  
  .action-buttons {
    flex-direction: column;
  }
}
</style>