<script setup>
import { computed, onBeforeUnmount, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../../../stores/auth'
import { saveProfile, uploadAvatar, deleteTemporaryAvatar } from '../../../api/user'

const auth = useAuthStore(), router = useRouter()
const form = reactive({ nickname: '', phone: '', location: '', avatarId: '', version: 0 })
const busy = ref(false), signingOut = ref(false), error = ref(''), success = ref(''), fieldErrors = ref({}), selected = ref(null), preview = ref(''), uploaded = ref(null), fileInput = ref(null)
const count = text => Array.from(text).length
function resetPreview() { if (preview.value) URL.revokeObjectURL(preview.value); preview.value = '' }
function reset() {
  for (const key of Object.keys(form)) form[key] = auth.user[key]
  resetPreview(); selected.value = null; uploaded.value = null; error.value = ''; fieldErrors.value = {}
  if (fileInput.value) fileInput.value.value = ''
}
reset()
const initial = computed(() => Array.from(auth.user?.nickname || '爪')[0])
const avatarUrl = computed(() => preview.value || (form.avatarId ? `/api/v1/media/${form.avatarId}/content` : ''))
const savedAvatarUrl = computed(() => auth.user?.avatarId ? `/api/v1/media/${auth.user.avatarId}/content` : '')
const dirty = computed(() => !!auth.user && (!!selected.value || ['nickname', 'phone', 'location', 'avatarId'].some(k => form[k] !== auth.user[k])))
const joinedAt = computed(() => new Intl.DateTimeFormat('zh-CN', { year: 'numeric', month: 'long', day: 'numeric' }).format(new Date(auth.user.createdAt)))
async function discardUploaded() {
  if (uploaded.value) { const id = uploaded.value; uploaded.value = null; try { await deleteTemporaryAvatar(id) } catch { /* 未绑定文件由服务端定期清理 */ } }
}
async function chooseFile(event) {
  const file = event.target.files?.[0]
  if (!file) return
  error.value = ''; success.value = ''
  if (!['image/jpeg', 'image/png', 'image/webp', 'image/gif'].includes(file.type)) { error.value = '请选择 JPG、PNG、GIF 或 WebP 图片'; event.target.value = ''; return }
  if (file.size > 5242880) { error.value = '图片不能超过 5 MB，请压缩后再上传'; event.target.value = ''; return }
  await discardUploaded(); resetPreview(); selected.value = file; preview.value = URL.createObjectURL(file)
}
async function removeAvatar() { await discardUploaded(); resetPreview(); selected.value = null; form.avatarId = ''; success.value = ''; if (fileInput.value) fileInput.value.value = '' }
async function reload() { try { await discardUploaded(); await auth.refresh(); reset(); success.value = '' } catch (e) { error.value = e.message; if (e.status === 401) { auth.clear(); router.replace('/login') } } }
async function submit() {
  if (busy.value || !dirty.value) return
  success.value = ''; error.value = ''; fieldErrors.value = {}
  if (!form.nickname.trim() || count(form.nickname.trim()) > 24) fieldErrors.value.nickname = '请填写 1–24 个字符的昵称'
  if (count(form.phone) > 32) fieldErrors.value.phone = '联系方式最多 32 个字符'
  if (count(form.location) > 100) fieldErrors.value.location = '所在地最多 100 个字符'
  if (Object.keys(fieldErrors.value).length) return
  busy.value = true
  try {
    if (selected.value && !uploaded.value) uploaded.value = (await uploadAvatar(selected.value)).id
    auth.user = await saveProfile({ ...form, nickname: form.nickname.trim(), phone: form.phone.trim(), location: form.location.trim(), avatarId: uploaded.value || form.avatarId })
    reset(); success.value = '资料已保存，新的爪印留下啦。'
  } catch (e) {
    error.value = e.message; fieldErrors.value = e.fields || {}
    if (e.code === 'UNAUTHENTICATED') { auth.clear(); await router.replace('/login') }
  } finally { busy.value = false }
}
async function logout() {
  if (signingOut.value) return
  signingOut.value = true; error.value = ''
  try { await discardUploaded(); await auth.logout(); await router.replace('/login') }
  catch (e) { error.value = e.message }
  finally { signingOut.value = false }
}
onBeforeUnmount(() => { resetPreview(); discardUploaded() })
</script>

<template>
  <main v-if="auth.user" class="profile-shell">
    <div class="profile-breadcrumb"><span>我的爪爪</span><span aria-hidden="true">/</span><span>个人资料</span></div>
    <section class="profile-hero"><div><span class="eyebrow">YOUR LITTLE CORNER</span><h1>你好，{{ auth.user.nickname }}<span class="heading-flower" aria-hidden="true">✳</span></h1><p>在这里，留下一点关于你的故事。</p></div><div class="hero-stamp" aria-hidden="true"><span>PAWPAW</span><b>♡</b><span>GOOD COMPANY</span></div></section>
    <div class="profile-grid">
      <aside class="profile-sidebar">
        <div class="profile-card member-card"><div class="avatar avatar-large"><img v-if="savedAvatarUrl" :src="savedAvatarUrl" alt="我的头像" /><span v-else>{{ initial }}</span></div><h2>{{ auth.user.nickname }}</h2><span class="member-username">@{{ auth.user.username }}</span><span class="member-chip"><span class="tiny-dot"></span> 爪爪社区的一员</span><div class="member-divider"></div><p class="joined-label">相遇于</p><p class="joined-date">{{ joinedAt }}</p></div>
        <nav class="profile-card profile-nav" aria-label="个人中心"><span class="profile-nav-active"><svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="8" r="4"/><path d="M4 21v-2a8 8 0 0 1 16 0v2"/></svg>个人资料<span aria-hidden="true">↗</span></span><button type="button" @click="logout" :disabled="signingOut || busy"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M9 4H4v16h5m6-13 5 5-5 5m5-5H9"/></svg>{{ signingOut ? '正在退出…' : '退出登录' }}<span aria-hidden="true">→</span></button></nav>
        <p class="sidebar-note">每一个小小的你，<br>都值得被温柔认识。</p>
      </aside>
      <section class="profile-card profile-editor">
        <div class="editor-heading"><div><h2>编辑个人资料</h2><p>让大家从一张头像、一个昵称开始认识你。</p></div><span class="editor-section-index">01</span></div>
        <form @submit.prevent="submit" novalidate>
          <div v-if="error" class="notice notice-error" role="alert">{{ error }}<button v-if="error.includes('重新载入')" type="button" class="text-button" @click="reload" :disabled="busy">重新载入资料</button></div>
          <div v-if="success" class="notice notice-success" role="status">{{ success }}</div>
          <div class="avatar-editor"><div class="avatar avatar-edit"><img v-if="avatarUrl" :src="avatarUrl" alt="头像预览" /><span v-else>{{ initial }}</span></div><div><label for="avatar-file" class="field-label">你的头像</label><div class="avatar-buttons"><button type="button" class="button button-small button-outline" @click="fileInput.click()" :disabled="busy">{{ avatarUrl ? '更换图片' : '上传图片' }} <span aria-hidden="true">↑</span></button><button v-if="avatarUrl" type="button" class="text-button" @click="removeAvatar" :disabled="busy">移除</button></div><p class="field-hint">JPG、PNG、GIF 或 WebP，大小不超过 5 MB</p><input id="avatar-file" ref="fileInput" class="visually-hidden" type="file" accept="image/jpeg,image/png,image/gif,image/webp" :disabled="busy" @change="chooseFile" /></div></div>
          <div class="editor-divider"></div>
          <div class="field"><label for="profile-nickname">昵称 <span class="required-mark">*</span></label><input id="profile-nickname" v-model="form.nickname" name="nickname" autocomplete="nickname" placeholder="希望大家怎么称呼你？" :disabled="busy" :aria-invalid="!!fieldErrors.nickname" /><small v-if="fieldErrors.nickname" class="field-error">{{ fieldErrors.nickname }}</small><small v-else class="field-hint">你在社区里展示的名字，最多 24 个字符。</small></div>
          <div class="profile-field-row"><div class="field"><label for="profile-phone">联系方式 <span class="optional-label">选填</span></label><input id="profile-phone" v-model="form.phone" name="phone" autocomplete="tel" placeholder="例如你的手机号" :disabled="busy" :aria-invalid="!!fieldErrors.phone" /><small v-if="fieldErrors.phone" class="field-error">{{ fieldErrors.phone }}</small></div><div class="field"><label for="profile-location">所在地 <span class="optional-label">选填</span></label><input id="profile-location" v-model="form.location" name="location" autocomplete="address-level2" placeholder="例如 湖北 · 武汉" :disabled="busy" :aria-invalid="!!fieldErrors.location" /><small v-if="fieldErrors.location" class="field-error">{{ fieldErrors.location }}</small></div></div>
          <div class="field account-readonly"><label for="profile-username">账号</label><input id="profile-username" :value="auth.user.username" readonly /><small class="field-hint">账号用于登录，注册后保持不变。</small></div>
          <div class="privacy-note"><svg viewBox="0 0 20 20" aria-hidden="true"><rect x="4" y="8" width="12" height="9" rx="2"/><path d="M6 8V6a4 4 0 0 1 8 0v2"/></svg><p>联系方式用于必要时联系你，不会显示在公开的社区内容中。</p></div>
          <div class="editor-footer"><span>{{ dirty ? '有新的修改等待保存' : '资料已是最新状态' }}</span><div><button type="button" class="button button-quiet" :disabled="busy || !dirty" @click="reload">取消修改</button><button class="button button-primary" type="submit" :disabled="busy || !dirty">{{ busy ? '正在保存…' : '保存资料' }} <span aria-hidden="true">↗</span></button></div></div>
        </form>
      </section>
    </div>
  </main>
</template>
