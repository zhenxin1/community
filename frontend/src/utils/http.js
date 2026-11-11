let csrfToken = null
let initializing = null

export class ApiError extends Error {
  constructor(body, status) {
    super(body.message || '请求失败，请稍后重试')
    this.code = body.code
    this.status = status
    this.fields = Object.fromEntries((body.fieldErrors || []).map(f => [f.field, f.message]))
    this.requestId = body.requestId
  }
}

export function resetSession() { csrfToken = null; initializing = null }

export async function initializeSession() {
  if (initializing) return initializing
  initializing = fetch('/api/v1/common/session', { credentials: 'same-origin', cache: 'no-store' })
    .then(async response => {
      const body = await response.json()
      if (!response.ok) throw new ApiError(body, response.status)
      csrfToken = body.data.csrfToken
      return body.data
    }).finally(() => { initializing = null })
  return initializing
}

export async function request(path, { method = 'GET', body, form } = {}) {
  const write = !['GET', 'HEAD'].includes(method)
  if (write && !csrfToken) await initializeSession()
  const headers = { Accept: 'application/json' }
  if (write) headers['X-CSRF-Token'] = csrfToken
  if (body !== undefined) headers['Content-Type'] = 'application/json'
  let response
  try {
    response = await fetch(`/api/v1${path}`, {
      method, headers, credentials: 'same-origin', cache: 'no-store',
      body: form || (body === undefined ? undefined : JSON.stringify(body)),
    })
  } catch { throw new Error('暂时连接不上服务，请稍后再试') }
  const result = await response.json().catch(() => ({ message: '服务暂时不可用，请稍后再试' }))
  if (!response.ok) {
    if (result.code === 'CSRF_INVALID') resetSession()
    throw new ApiError(result, response.status)
  }
  if (result.data?.csrfToken) csrfToken = result.data.csrfToken
  return result.data
}
