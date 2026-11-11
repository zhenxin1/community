import { spawn } from 'node:child_process'
import fs from 'node:fs/promises'
import path from 'node:path'
import net from 'node:net'
import { fileURLToPath } from 'node:url'

const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..')
const base=(process.argv[2]||'http://127.0.0.1:18080').replace(/\/$/,'')
const out=path.join(root,'docs','testing')
const profile=path.join(root,'.runtime','browser-smoke',Date.now().toString())
await fs.mkdir(out,{recursive:true});await fs.mkdir(profile,{recursive:true})
const port=await new Promise(resolve=>{const s=net.createServer();s.listen(0,'127.0.0.1',()=>{const p=s.address().port;s.close(()=>resolve(p))})})
const browser=spawn(process.env.EDGE_PATH||'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',[
  '--headless=new','--disable-gpu','--no-first-run','--no-default-browser-check',
  '--remote-debugging-address=127.0.0.1',`--remote-debugging-port=${port}`,`--user-data-dir=${profile}`,'about:blank',
],{windowsHide:true,stdio:'ignore'})
let socket,serial=0
const pending=new Map(),errors=[],checks=[]
const delay=ms=>new Promise(resolve=>setTimeout(resolve,ms))
function call(method,params={}){
  return new Promise((resolve,reject)=>{
    const id=++serial
    const timeout=setTimeout(()=>{pending.delete(id);reject(new Error('CDP timed out: '+method))},15000)
    pending.set(id,{resolve:value=>{clearTimeout(timeout);resolve(value)},reject:error=>{clearTimeout(timeout);reject(error)}})
    socket.send(JSON.stringify({id,method,params}))
  })
}
async function evaluate(expression){
  const result=await call('Runtime.evaluate',{expression,returnByValue:true,awaitPromise:true,userGesture:true})
  if(result.exceptionDetails)throw new Error(JSON.stringify(result.exceptionDetails))
  return result.result.value
}
async function wait(expression){
  for(let i=0;i<120;i++){if(await evaluate(expression))return;await delay(100)}
  throw new Error('Wait failed: '+expression)
}
async function input(id,value){
  await evaluate(`(()=>{const e=document.getElementById(${JSON.stringify(id)});Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value').set.call(e,${JSON.stringify(value)});e.dispatchEvent(new Event('input',{bubbles:true}));e.focus()})()`)
}
async function enter(){
  await call('Input.dispatchKeyEvent',{type:'keyDown',key:'Enter',code:'Enter',windowsVirtualKeyCode:13,text:'\r',unmodifiedText:'\r'})
  await call('Input.dispatchKeyEvent',{type:'keyUp',key:'Enter',code:'Enter',windowsVirtualKeyCode:13})
}
async function screenshot(filename){
  await delay(150)
  const shot=await call('Page.captureScreenshot',{format:'png',captureBeyondViewport:true})
  await fs.writeFile(path.join(out,filename),Buffer.from(shot.data,'base64'))
}
function passed(name){checks.push({name,result:'PASS'});console.log('PASS '+name)}

try{
  let page
  for(let i=0;i<100;i++){
    try{const pages=await(await fetch(`http://127.0.0.1:${port}/json/list`)).json();page=pages.find(p=>p.type==='page');if(page)break}catch{}
    await delay(150)
  }
  if(!page)throw new Error('Headless Edge did not start')
  socket=new WebSocket(page.webSocketDebuggerUrl)
  await new Promise((resolve,reject)=>{socket.onopen=resolve;socket.onerror=reject})
  socket.onmessage=event=>{
    const message=JSON.parse(event.data)
    if(message.method==='Runtime.exceptionThrown')errors.push(message.params.exceptionDetails)
    if(!pending.has(message.id))return
    const task=pending.get(message.id);pending.delete(message.id)
    message.error?task.reject(new Error(JSON.stringify(message.error))):task.resolve(message.result)
  }
  await call('Runtime.enable');await call('Page.enable');await call('DOM.enable')
  await call('Emulation.setDeviceMetricsOverride',{width:1440,height:1000,deviceScaleFactor:1,mobile:false})
  await call('Page.navigate',{url:base+'/profile'})
  await wait('location.pathname==="/login" && !!document.getElementById("login-username")')
  passed('protected profile redirects anonymous browser to login')
  await screenshot('login-desktop.png')
  await evaluate('document.querySelector(\'a[href="/register"]\').click()')
  await wait('!!document.getElementById("register-username")')
  await screenshot('register-desktop.png')
  const name='browser_'+Date.now().toString(36),password='PawBrowser123!'
  await input('register-username',name);await input('register-nickname','小爪体验官');await input('register-password',password);await input('register-confirm','does-not-match')
  await enter();await wait('document.body.innerText.includes("两次输入的密码不一致")')
  passed('registration validates confirmation in the browser')
  await input('register-confirm',password);await enter()
  await wait('location.pathname==="/profile" && !!document.getElementById("profile-nickname")')
  passed('Enter submits registration and opens signed-in profile')
  await input('profile-nickname','团团的好朋友');await input('profile-phone','13900112233');await input('profile-location','湖北 · 武汉');await enter()
  await wait('!!document.querySelector(".notice-success") && document.querySelector(".member-card h2").textContent==="团团的好朋友"')
  passed('Enter saves profile and updates identity on the page')
  await call('Page.reload')
  await wait('!!document.getElementById("profile-phone") && document.getElementById("profile-phone").value==="13900112233"')
  if(await evaluate('localStorage.length')!==0)throw new Error('Unexpected localStorage identity data')
  passed('refresh restores session and persisted profile without localStorage identity')
  const fixture=path.join(root,'.runtime','avatar-fixture.png')
  const avatarData=await evaluate(`(()=>{const c=document.createElement('canvas');c.width=c.height=256;const x=c.getContext('2d');x.fillStyle='#e5eddb';x.fillRect(0,0,256,256);x.fillStyle='#ebb483';x.beginPath();x.moveTo(53,112);x.lineTo(47,41);x.lineTo(102,78);x.lineTo(155,78);x.lineTo(209,41);x.lineTo(204,115);x.fill();x.beginPath();x.ellipse(128,142,89,76,0,0,Math.PI*2);x.fill();x.fillStyle='#fff0d8';x.beginPath();x.ellipse(128,168,38,33,0,0,Math.PI*2);x.fill();x.strokeStyle='#354c3b';x.lineWidth=6;x.lineCap='round';for(const cx of [91,165]){x.beginPath();x.arc(cx,140,11,0,Math.PI);x.stroke()}x.fillStyle='#bc7a68';x.beginPath();x.moveTo(118,162);x.lineTo(138,162);x.lineTo(128,173);x.fill();return c.toDataURL('image/png').split(',')[1]})()`)
  await fs.writeFile(fixture,Buffer.from(avatarData,'base64'))
  const document=await call('DOM.getDocument')
  const selected=await call('DOM.querySelector',{nodeId:document.root.nodeId,selector:'#avatar-file'})
  await call('DOM.setFileInputFiles',{nodeId:selected.nodeId,files:[fixture]})
  await wait('!!document.querySelector(".avatar-edit img") && document.querySelector(".avatar-edit img").src.startsWith("blob:")')
  await evaluate('document.querySelector(".profile-editor button[type=submit]").click()')
  await wait('!!document.querySelector(".notice-success") && !!document.querySelector(".member-card img") && document.querySelector(".member-card img").naturalWidth>0')
  passed('avatar selection previews and saves an uploaded image')
  await screenshot('profile-desktop.png')
  await call('Emulation.setDeviceMetricsOverride',{width:390,height:844,deviceScaleFactor:1,mobile:true})
  if(!await evaluate('document.documentElement.scrollWidth<=innerWidth'))throw new Error('Profile overflows mobile viewport')
  await screenshot('profile-mobile.png');passed('profile fits mobile viewport')
  await evaluate('document.querySelector(".profile-nav button").click()')
  await wait('location.pathname==="/login" && !!document.getElementById("login-password")')
  passed('logout clears identity and returns to login')
  await screenshot('login-mobile.png')
  await call('Emulation.setDeviceMetricsOverride',{width:320,height:800,deviceScaleFactor:1,mobile:true})
  if(!await evaluate('document.documentElement.scrollWidth<=innerWidth'))throw new Error('Login overflows narrow viewport')
  passed('login fits a 320px viewport')
  await input('login-username',name);await input('login-password',password);await enter()
  await wait('location.pathname==="/profile" && !!document.querySelector(".avatar-edit img")')
  passed('Enter logs in again and restores saved avatar')
  if(!await evaluate('document.documentElement.scrollWidth<=innerWidth'))throw new Error('Profile overflows narrow viewport')
  passed('profile fits a 320px viewport')
  if(errors.length)throw new Error('Browser JavaScript exceptions: '+JSON.stringify(errors))
  passed('no uncaught browser JavaScript errors')
  await fs.writeFile(path.join(out,'browser-results.json'),JSON.stringify({checksPassed:checks.length,checks},null,2)+'\n')
  console.log(JSON.stringify({passed:checks.length}))
}finally{
  if(socket?.readyState===WebSocket.OPEN){try{await call('Browser.close')}catch{}socket.close()}
  if(!browser.killed)browser.kill()
}
