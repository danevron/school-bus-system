import { createRouter, createWebHistory } from 'vue-router'
import Login from './views/Login.vue'
import Home from './views/Home.vue'
import UserManagement from './views/UserManagement.vue'
import AcceptInvitation from './views/AcceptInvitation.vue'
import LineList from './views/LineList.vue'
import LineCreate from './views/LineCreate.vue'
import LineView from './views/LineView.vue'
import LineRouteManager from './views/LineRouteManager.vue'
import RideList from './views/RideList.vue'
import RideView from './views/RideView.vue'
import Registrations from './views/Registrations.vue'
import RegistrationCreate from './views/RegistrationCreate.vue'
import RegistrationEdit from './views/RegistrationEdit.vue'
import RegistrationRequestCreate from './views/RegistrationRequestCreate.vue'
import RegistrationDetail from './views/RegistrationDetail.vue'
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
    path: '/lines',
    name: 'LineList',
    component: LineList,
    meta: { requiresAuth: true, requiresAdmin: true }
  },
  {
    path: '/lines/create',
    name: 'LineCreate',
    component: LineCreate,
    meta: { requiresAuth: true, requiresAdmin: true }
  },
  {
    path: '/lines/:id',
    name: 'LineView',
    component: LineView,
    meta: { requiresAuth: true, requiresAdmin: true }
  },
  {
    path: '/lines/:id/route',
    name: 'LineRouteManager',
    component: LineRouteManager,
    meta: { requiresAuth: true, requiresAdmin: true }
  },
  {
    path: '/rides',
    name: 'RideList',
    component: RideList,
    meta: { requiresAuth: true, requiresAdmin: true }
  },
  {
    path: '/rides/:id',
    name: 'RideView',
    component: RideView,
    meta: { requiresAuth: true, requiresAdmin: true }
  },
  {
    path: '/registrations',
    name: 'Registrations',
    component: Registrations,
    meta: { requiresAuth: true, requiresAdmin: true }
  },
  {
    path: '/registrations/create',
    name: 'RegistrationCreate',
    component: RegistrationCreate,
    meta: { requiresAuth: true, requiresAdmin: true }
  },
  {
    path: '/registrations/:id/edit',
    name: 'RegistrationEdit',
    component: RegistrationEdit,
    meta: { requiresAuth: true, requiresAdmin: true }
  },
  {
    path: '/registrations/:id/detail',
    name: 'RegistrationDetail',
    component: RegistrationDetail,
    meta: { requiresAuth: true, requiresAdmin: true }
  },
  {
    path: '/registration-requests/create/:registrationId',
    name: 'RegistrationRequestCreate',
    component: RegistrationRequestCreate,
    meta: { requiresAuth: true, requiresParent: true }
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
  } else if (to.meta.requiresParent && userRole !== 'parent') {
    next('/home')
  } else {
    next()
  }
})

export default router