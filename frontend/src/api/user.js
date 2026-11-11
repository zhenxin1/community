import { request } from '../utils/http'
export const signIn = body => request('/user/auth/login', { method: 'POST', body })
export const signUp = body => request('/user/auth/register', { method: 'POST', body })
export const currentUser = () => request('/user/auth/me')
export const signOut = () => request('/user/auth/logout', { method: 'POST' })
export const getProfile = () => request('/user/profile')
export const saveProfile = body => request('/user/profile', { method: 'PUT', body })
export const uploadAvatar = file => {
  const form = new FormData()
  form.append('businessType', 'AVATAR')
  form.append('file', file)
  return request('/user/media', { method: 'POST', form })
}
export const deleteTemporaryAvatar = id => request(`/user/media/${id}`, { method: 'DELETE' })
