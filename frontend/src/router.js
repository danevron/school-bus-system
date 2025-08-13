import { createRouter, createWebHistory } from 'vue-router'
import Login from './views/Login.vue'
import Home from './views/Home.vue'
import UserManagement from './views/UserManagement.vue'
import AcceptInvitation from './views/AcceptInvitation.vue'
import authStore from './stores/auth'

const routes = [
  {
    path: '/',
    redirect: '/home'
  },
  {
    path: '/login',
    name: 'Login',
    component: Login,
    meta: { requiresGuest: true }
  },
  {
    path: '/home',
    name: 'Home', 
    component: Home,
    meta: { requiresAuth: true }
  },
  {
    path: '/user-management',
    name: 'UserManagement',
    component: UserManagement,
    meta: { requiresAuth: true, requiresAdmin: true }
  },
  {
    path: '/accept-invitation',
    name: 'AcceptInvitation',
    component: AcceptInvitation,
    meta: { requiresGuest: true }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

router.beforeEach((to, from, next) => {
  const isLoggedIn = authStore.isAuthenticated()
  const userRole = authStore.getUserRole()
  
  if (to.meta.requiresAuth && !isLoggedIn) {
    next('/login')
  } else if (to.meta.requiresGuest && isLoggedIn) {
    next('/home')
  } else if (to.meta.requiresAdmin && userRole !== 'admin') {
    next('/home')
  } else {
    next()
  }
})

export default router