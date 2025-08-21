import { createRouter, createWebHistory } from 'vue-router'
import Login from './views/Login.vue'
import Home from './views/Home.vue'
import UserManagement from './views/UserManagement.vue'
import AcceptInvitation from './views/AcceptInvitation.vue'
import RouteList from './views/RouteList.vue'
import RouteDetail from './views/RouteDetail.vue'
import RouteCreate from './views/RouteCreate.vue'
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
  },
  {
    path: '/routes',
    name: 'RouteList',
    component: RouteList,
    meta: { requiresAuth: true, requiresAdmin: true }
  },
  {
    path: '/routes/create',
    name: 'RouteCreate',
    component: RouteCreate,
    meta: { requiresAuth: true, requiresAdmin: true }
  },
  {
    path: '/routes/:id',
    name: 'RouteDetail',
    component: RouteDetail,
    meta: { requiresAuth: true, requiresAdmin: true }
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