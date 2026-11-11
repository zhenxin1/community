<script setup>
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from './stores/auth'
import PawLogo from './components/PawLogo.vue'
const route = useRoute(), router = useRouter(), auth = useAuthStore()
const authenticated = computed(() => !!auth.user)
const home = () => router.push(authenticated.value ? '/profile' : '/login')
</script>

<template>
  <div class="site-wrap">
    <header class="site-header">
      <a href="/" class="brand" @click.prevent="home"><PawLogo /><span class="brand-word">爪爪社区<small>PAWPAW</small></span></a>
      <span class="header-caption">和毛孩子一起，把日子过得柔软一点。</span>
      <nav class="header-actions" aria-label="账号导航">
        <template v-if="!authenticated">
          <span class="header-question">{{ route.path === '/register' ? '已经有账号？' : '初次见面？' }}</span>
          <RouterLink :to="route.path === '/register' ? '/login' : '/register'" class="button button-small button-outline">{{ route.path === '/register' ? '去登录' : '加入爪爪' }} <span aria-hidden="true">↗</span></RouterLink>
        </template>
        <span v-else class="signed-in-label"><span class="tiny-dot"></span> 很高兴见到你，{{ auth.user.nickname }}</span>
      </nav>
    </header>
    <RouterView />
    <footer class="site-footer"><span>© {{ new Date().getFullYear() }} PAWPAW · 爪爪社区</span><span>让每一份陪伴，都有归处 <span aria-hidden="true">♡</span></span></footer>
  </div>
</template>
