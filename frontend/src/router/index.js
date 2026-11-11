import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import LoginView from '../views/user/auth/LoginView.vue'
import RegisterView from '../views/user/auth/RegisterView.vue'
import ProfileView from '../views/user/profile/ProfileView.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', redirect: '/profile' },
    { path: '/login', component: LoginView, meta: { guest: true, title: '欢迎回来' } },
    { path: '/register', component: RegisterView, meta: { guest: true, title: '加入爪爪' } },
    { path: '/profile', component: ProfileView, meta: { authenticated: true, title: '个人资料' } },
    { path: '/:pathMatch(.*)*', redirect: '/' },
  ],
})
router.beforeEach(async to => {
  const auth = useAuthStore()
  try { await auth.hydrate() } catch { /* 页面显示连接错误，保留重试入口 */ }
  if (to.meta.authenticated && !auth.user) return '/login'
  if (to.meta.guest && auth.user) return '/profile'
  document.title = `${to.meta.title || '让陪伴发生'} · 爪爪社区`
})
export default router
