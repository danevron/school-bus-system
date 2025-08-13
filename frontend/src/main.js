import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import authStore from './stores/auth'

const app = createApp(App)

app.use(router)
app.provide('authStore', authStore)

app.mount('#app')