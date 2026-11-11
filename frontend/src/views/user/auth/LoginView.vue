<script setup>
import { reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../../../stores/auth'
import AuthLayout from '../../../layouts/AuthLayout.vue'

const router = useRouter(), auth = useAuthStore()
const form = reactive({ username: '', password: '' })
const busy = ref(false), showPassword = ref(false), error = ref(''), fieldErrors = ref({})
async function submit() {
  if (busy.value) return
  error.value = ''; fieldErrors.value = {}
  if (!form.username.trim() || !form.password) { error.value = '请填写账号和密码'; return }
  busy.value = true
  try { await auth.login({ username: form.username.trim(), password: form.password }); await router.replace('/profile') }
  catch (e) { error.value = e.message; fieldErrors.value = e.fields || {} }
  finally { busy.value = false }
}
</script>

<template>
  <AuthLayout>
    <div class="form-heading"><span class="eyebrow form-eyebrow">GOOD TO SEE YOU AGAIN</span><h2>欢迎回来 <span class="heading-flower" aria-hidden="true">✳</span></h2><p>登录爪爪，继续和毛孩子的故事。</p></div>
    <form class="account-form" @submit.prevent="submit" novalidate>
      <div v-if="error" class="notice notice-error" role="alert">{{ error }}</div>
      <div class="field"><label for="login-username">账号</label><input id="login-username" v-model="form.username" name="username" autocomplete="username" placeholder="输入你的账号" maxlength="24" required :aria-invalid="!!fieldErrors.username" /><small v-if="fieldErrors.username" class="field-error">{{ fieldErrors.username }}</small></div>
      <div class="field"><label for="login-password">密码</label><div class="password-wrap"><input id="login-password" v-model="form.password" name="password" :type="showPassword ? 'text' : 'password'" autocomplete="current-password" placeholder="输入密码" required :aria-invalid="!!fieldErrors.password" /><button type="button" class="password-toggle" :aria-label="showPassword ? '隐藏密码' : '显示密码'" :aria-pressed="showPassword" @click="showPassword = !showPassword"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M2 12s3.5-6 10-6 10 6 10 6-3.5 6-10 6S2 12 2 12Z"/><circle cx="12" cy="12" r="3"/></svg></button></div><small v-if="fieldErrors.password" class="field-error">{{ fieldErrors.password }}</small></div>
      <div class="login-helper"><span class="subtle-lock"><svg viewBox="0 0 20 20" aria-hidden="true"><rect x="4" y="8" width="12" height="9" rx="2"/><path d="M6 8V6a4 4 0 0 1 8 0v2"/></svg>安心登录，温暖相遇</span><details class="password-help"><summary>忘记密码？</summary><p>请联系平台管理员核实身份并重置密码。</p></details></div>
      <button class="button button-primary button-submit" type="submit" :disabled="busy"><span>{{ busy ? '正在登录…' : '登录，回到爪爪' }}</span><span aria-hidden="true">→</span></button>
      <p class="form-switch">还没有账号？<RouterLink to="/register">创建一个，认识新朋友 <span aria-hidden="true">↗</span></RouterLink></p>
    </form>
    <div class="form-bottom-note"><span class="note-line"></span><span>一人一宠，一点一滴。</span><span class="note-line"></span></div>
  </AuthLayout>
</template>
