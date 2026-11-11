<script setup>
import { reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../../../stores/auth'
import AuthLayout from '../../../layouts/AuthLayout.vue'
const router = useRouter(), auth = useAuthStore()
const form = reactive({ username: '', nickname: '', password: '', confirmPassword: '' })
const busy = ref(false), showPassword = ref(false), error = ref(''), fieldErrors = ref({})
const count = text => Array.from(text).length
async function submit() {
  if (busy.value) return
  error.value = ''; fieldErrors.value = {}
  if (!/^[A-Za-z0-9_]{3,24}$/.test(form.username.trim())) fieldErrors.value.username = '使用 3–24 位字母、数字或下划线'
  if (!form.nickname.trim() || count(form.nickname.trim()) > 24) fieldErrors.value.nickname = '请填写 1–24 个字符的昵称'
  if (count(form.password) < 8 || count(form.password) > 64) fieldErrors.value.password = '密码需要 8–64 个字符'
  if (form.password !== form.confirmPassword) fieldErrors.value.confirmPassword = '两次输入的密码不一致'
  if (Object.keys(fieldErrors.value).length) return
  busy.value = true
  try {
    await auth.register({ username: form.username.trim(), nickname: form.nickname.trim(), password: form.password })
    await router.replace('/profile')
  } catch (e) { error.value = e.message; fieldErrors.value = e.fields || {} }
  finally { busy.value = false }
}
</script>

<template>
  <AuthLayout>
    <div class="form-heading register-heading"><span class="eyebrow form-eyebrow">A LITTLE HELLO, A NEW BEGINNING</span><h2>很高兴，遇见你 <span class="heading-flower" aria-hidden="true">✳</span></h2><p>创建你的账号，留下一枚专属爪印。</p></div>
    <form class="account-form register-form" @submit.prevent="submit" novalidate>
      <div v-if="error" class="notice notice-error" role="alert">{{ error }}</div>
      <div class="field"><label for="register-username">账号</label><input id="register-username" v-model="form.username" name="username" autocomplete="username" placeholder="3–24 位字母、数字或下划线" maxlength="24" :aria-invalid="!!fieldErrors.username" /><small v-if="fieldErrors.username" class="field-error">{{ fieldErrors.username }}</small></div>
      <div class="field"><label for="register-nickname">昵称</label><input id="register-nickname" v-model="form.nickname" name="nickname" autocomplete="nickname" placeholder="希望大家怎么称呼你？" :aria-invalid="!!fieldErrors.nickname" /><small v-if="fieldErrors.nickname" class="field-error">{{ fieldErrors.nickname }}</small></div>
      <div class="field"><label for="register-password">密码</label><div class="password-wrap"><input id="register-password" v-model="form.password" name="password" :type="showPassword ? 'text' : 'password'" autocomplete="new-password" placeholder="设置 8–64 个字符的密码" :aria-invalid="!!fieldErrors.password" /><button type="button" class="password-toggle" :aria-label="showPassword ? '隐藏密码' : '显示密码'" :aria-pressed="showPassword" @click="showPassword = !showPassword"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M2 12s3.5-6 10-6 10 6 10 6-3.5 6-10 6S2 12 2 12Z"/><circle cx="12" cy="12" r="3"/></svg></button></div><small v-if="fieldErrors.password" class="field-error">{{ fieldErrors.password }}</small></div>
      <div class="field"><label for="register-confirm">确认密码</label><input id="register-confirm" v-model="form.confirmPassword" name="confirmPassword" :type="showPassword ? 'text' : 'password'" autocomplete="new-password" placeholder="再输入一次密码" :aria-invalid="!!fieldErrors.confirmPassword" /><small v-if="fieldErrors.confirmPassword" class="field-error">{{ fieldErrors.confirmPassword }}</small></div>
      <button class="button button-primary button-submit" type="submit" :disabled="busy"><span>{{ busy ? '正在创建账号…' : '创建账号，加入爪爪' }}</span><span aria-hidden="true">→</span></button>
      <p class="form-switch">已经有账号？<RouterLink to="/login">直接登录 <span aria-hidden="true">↗</span></RouterLink></p>
    </form>
  </AuthLayout>
</template>
