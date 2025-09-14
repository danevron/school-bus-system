import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import authStore from './stores/auth'
import i18n from './i18n'

// PrimeVue
import PrimeVue from 'primevue/config'
import Aura from '@primevue/themes/aura'

// PrimeVue Components
import Button from 'primevue/button'
import InputText from 'primevue/inputtext'
import Password from 'primevue/password'
import Card from 'primevue/card'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import Dialog from 'primevue/dialog'
import Select from 'primevue/select'
import Calendar from 'primevue/calendar'
import Checkbox from 'primevue/checkbox'
import SelectButton from 'primevue/selectbutton'
import Avatar from 'primevue/avatar'
import Toast from 'primevue/toast'
import ToastService from 'primevue/toastservice'
import InputMask from 'primevue/inputmask'
import IconField from 'primevue/iconfield'
import InputIcon from 'primevue/inputicon'
import Tag from 'primevue/tag'

// PrimeIcons
import 'primeicons/primeicons.css'

const app = createApp(App)

app.use(router)
app.use(i18n)
app.use(PrimeVue, {
  theme: {
    preset: Aura,
    options: {
      darkModeSelector: '.dark-mode',
      cssLayer: {
        name: 'primevue',
        order: 'tailwind-base, primevue, tailwind-utilities'
      }
    }
  }
})
app.use(ToastService)

// Register PrimeVue components globally
app.component('Button', Button)
app.component('InputText', InputText)
app.component('InputIcon', InputIcon)
app.component('Password', Password)
app.component('Card', Card)
app.component('Tag', Tag)
app.component('DataTable', DataTable)
app.component('Column', Column)
app.component('Dialog', Dialog)
app.component('Calendar', Calendar)
app.component('Checkbox', Checkbox)
app.component('SelectButton', SelectButton)
app.component('Avatar', Avatar)
app.component('Toast', Toast)
app.component('Select', Select) 
app.component('InputMask', InputMask)
app.component('IconField', IconField)

app.provide('authStore', authStore)

app.mount('#app')