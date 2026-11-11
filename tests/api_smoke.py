"""Run against a started isolated development instance; creates random test users."""
import argparse
import concurrent.futures
import http.cookiejar
import json
import struct
import subprocess
import urllib.error
import urllib.request
import uuid
import zlib
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser()
parser.add_argument('--base-url',default='http://127.0.0.1:18080')
args=parser.parse_args()
BASE=args.base_url.rstrip('/')
RESULTS=[]

class Client:
    def __init__(self):
        self.jar=http.cookiejar.CookieJar()
        self.opener=urllib.request.build_opener(urllib.request.HTTPCookieProcessor(self.jar))
        self.csrf=None
    def request(self,path,method='GET',body=None,headers=None,binary=None,csrf=True):
        h=dict(headers or {})
        if method not in ['GET','HEAD'] and csrf and self.csrf: h['X-CSRF-Token']=self.csrf
        if body is not None: h['Content-Type']='application/json'
        data=json.dumps(body,ensure_ascii=False).encode() if body is not None else binary
        req=urllib.request.Request(BASE+path,data=data,method=method,headers=h)
        try: response=self.opener.open(req,timeout=15)
        except urllib.error.HTTPError as error: response=error
        raw=response.read()
        parsed=json.loads(raw) if 'application/json' in response.headers.get('Content-Type','') else raw
        return response.code,parsed,response.headers
    def session(self):
        status,body,_=self.request('/api/v1/common/session')
        assert status==200,(status,body)
        self.csrf=body['data']['csrfToken']
        return body['data']
    def cookie(self): return next((c.value for c in self.jar if c.name=='JSESSIONID'),None)
    def register(self,name,password,nickname='测试小爪'):
        status,body,headers=self.request('/api/v1/user/auth/register','POST',{'username':name,'password':password,'nickname':nickname})
        if status==200: self.csrf=body['data']['csrfToken']
        return status,body,headers
    def login(self,name,password):
        status,body,headers=self.request('/api/v1/user/auth/login','POST',{'username':name,'password':password})
        if status==200:self.csrf=body['data']['csrfToken']
        return status,body,headers
    def upload(self,content,name='avatar.png',mime='image/png'):
        boundary='----pawpaw'+uuid.uuid4().hex
        body=(f'--{boundary}\r\nContent-Disposition: form-data; name="businessType"\r\n\r\nAVATAR\r\n--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="{name}"\r\nContent-Type: {mime}\r\n\r\n'.encode()+content+f'\r\n--{boundary}--\r\n'.encode())
        return self.request('/api/v1/user/media','POST',headers={'Content-Type':f'multipart/form-data; boundary={boundary}'},binary=body)

def passed(name): RESULTS.append({'name':name,'result':'PASS'});print('PASS '+name,flush=True)
def expect(response,status,code=None):
    assert response[0]==status,(response[0],response[1])
    if code: assert response[1]['code']==code,response[1]
    return response[1]
def profile(client): return expect(client.request('/api/v1/user/profile'),200,'OK')['data']
def payload(user,**changes):
    return {**{key:user[key] for key in ['nickname','avatarId','phone','location','version']},**changes}

def png():
    def chunk(kind,data): return struct.pack('>I',len(data))+kind+data+struct.pack('>I',zlib.crc32(kind+data)&0xffffffff)
    return b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',4,4,8,2,0,0,0))+chunk(b'IDAT',zlib.compress((b'\0'+bytes([120,160,110])*4)*4))+chunk(b'IEND',b'')

c=Client();visitor=Client();name='qa_'+uuid.uuid4().hex[:10];password='  PawPass123!  '
session=c.session();assert not session['authenticated'];anonymous_cookie=c.cookie();old_csrf=c.csrf
passed('anonymous session and CSRF bootstrap')
expect(visitor.request('/api/v1/user/auth/me'),401,'UNAUTHENTICATED');passed('anonymous cannot read identity')
expect(c.request('/api/v1/user/auth/register','POST',{'username':name,'password':password,'nickname':'小爪'},csrf=False),403,'CSRF_INVALID');passed('registration requires CSRF')
expect(c.request('/api/v1/user/auth/register','POST',{'username':name,'password':password,'nickname':'小爪','role':'ADMIN'}),400,'VALIDATION_ERROR');passed('registration rejects privilege fields')
expect(c.register(name,'short'),400,'VALIDATION_ERROR');passed('password length validation')
registration=expect(c.register(name.upper(),password,'  测试小爪  '),200,'OK');user=registration['data']['user']
assert user['username']==name and user['nickname']=='测试小爪' and user['role']=='USER' and 'roleIds' not in user and 'permissions' not in user
assert c.cookie()!=anonymous_cookie and c.csrf!=old_csrf and isinstance(user['id'],str)
assert set(user).isdisjoint({'password','passwordHash','password_hash','authVersion'})
passed('registration auto login, normalization, session and CSRF rotation')
cookie=next(cookie for cookie in c.jar if cookie.name=='JSESSIONID')
assert cookie.path=='/api' and cookie.has_nonstandard_attr('HttpOnly') and cookie.get_nonstandard_attr('SameSite')=='Lax'
passed('session cookie has HttpOnly, SameSite and API path')
expect(c.request('/api/v1/user/profile'),200,'OK');passed('authenticated user reads profile')
fresh=Client();fresh.session();expect(fresh.register(name.upper(),password),409,'USERNAME_EXISTS');passed('case-insensitive duplicate account')
expect(c.request('/api/v1/user/profile','PUT',payload(user,nickname='新名字'),headers={'X-CSRF-Token':old_csrf},csrf=False),403,'CSRF_INVALID');passed('pre-login CSRF no longer works')
saved=expect(c.request('/api/v1/user/profile','PUT',payload(user,nickname='新的小爪',phone='13800138000',location='湖北 · 武汉')),200,'OK')['data']
assert saved['version']==user['version']+1 and saved['location']=='湖北 · 武汉'
passed('profile saves to MySQL and increments version')
expect(c.request('/api/v1/user/profile','PUT',payload(user,nickname='过期覆盖')),409,'VERSION_CONFLICT');passed('stale profile cannot overwrite newer data')
expect(c.request('/api/v1/user/profile','PUT',{**payload(saved),'status':'FROZEN'}),400,'VALIDATION_ERROR');passed('profile rejects unauthorized fields')
expect(c.request('/api/v1/user/profile','PUT',{**payload(saved),'role':'ADMIN'}),400,'VALIDATION_ERROR');passed('profile cannot upgrade USER to ADMIN')
expect(c.request('/api/v1/user/profile','PUT',payload(saved,version='1')),400,'VALIDATION_ERROR');passed('numeric fields reject string coercion')
expect(c.request('/api/v1/user/profile','PUT',payload(saved,nickname=' ')),400,'VALIDATION_ERROR');passed('blank nickname validation')
same=expect(c.request('/api/v1/user/profile','PUT',payload(saved)),200,'OK')['data'];assert same['version']==saved['version'];passed('unchanged profile does not increment version')

image=png();media=expect(c.upload(image),200,'OK')['data'];media_path=media['contentPath']
assert c.request(media_path)[1]==image
expect(visitor.request(media_path),404,'RESOURCE_NOT_FOUND');passed('unbound avatar visible only to owner')
expect(c.upload(b'<svg onload=alert(1)>','avatar.png'),415,'UNSUPPORTED_MEDIA_TYPE');passed('forged image content rejected')
expect(c.upload(image,'avatar.exe'),415,'UNSUPPORTED_MEDIA_TYPE');passed('invalid image extension rejected')
expect(c.upload(image,'avatar.png','text/plain'),415,'UNSUPPORTED_MEDIA_TYPE');passed('inconsistent MIME rejected')
expect(c.upload(b'x'*(5242881)),413,'FILE_TOO_LARGE');passed('oversize image rejected')
other=Client();other.session();name2='qa_'+uuid.uuid4().hex[:10];other_user=expect(other.register(name2,'OtherPass123!'),200,'OK')['data']['user']
expect(other.request('/api/v1/user/profile','PUT',payload(other_user,avatarId=media['id'])),404,'RESOURCE_NOT_FOUND');passed('another user cannot bind uploaded avatar')
saved=expect(c.request('/api/v1/user/profile','PUT',payload(saved,avatarId=media['id'])),200,'OK')['data']
assert visitor.request(media_path)[1]==image;passed('saved avatar becomes public only after binding')
expect(c.request('/api/v1/user/media/'+media['id'],'DELETE'),409,'MEDIA_IN_USE');passed('bound avatar cannot be deleted as temporary file')
partial=c.request(media_path,headers={'Range':'bytes=0-7'});assert partial[0]==206 and partial[1]==image[:8] and partial[2]['Content-Range'].startswith('bytes 0-7/')
passed('image range request returns matching bytes')
expect(c.request(media_path,headers={'Range':'bytes=99999-'}),416,'RANGE_NOT_SATISFIABLE');passed('invalid image range rejected')
saved=expect(c.request('/api/v1/user/profile','PUT',payload(saved,avatarId='')),200,'OK')['data']
expect(visitor.request(media_path),404,'RESOURCE_NOT_FOUND');passed('removed avatar immediately inaccessible')

with concurrent.futures.ThreadPoolExecutor(max_workers=2) as executor:
    results=list(executor.map(lambda nickname:c.request('/api/v1/user/profile','PUT',payload(saved,nickname=nickname)),['并发小爪甲','并发小爪乙']))
assert sorted(r[0] for r in results)==[200,409];passed('concurrent profile update allows one winner')
saved=profile(c)
expect(c.request('/api/v1/user/auth/logout','POST'),200,'OK');expect(c.request('/api/v1/user/auth/me'),401,'UNAUTHENTICATED');passed('logout invalidates session')
c.session();expect(c.login(name,password.strip()),401,'INVALID_CREDENTIALS');passed('password whitespace is preserved')
expect(c.login(name,password),200,'OK');assert profile(c)['nickname']==saved['nickname'];passed('login restores persisted profile')
c.session();assert c.request('/api/v1/user/auth/me')[0]==200;passed('session bootstrap preserves signed-in identity')

unicode_client=Client();unicode_client.session();uname='qa_'+uuid.uuid4().hex[:10];upassword='小爪'.__mul__(32)
expect(unicode_client.register(uname,upassword),200,'OK');expect(unicode_client.request('/api/v1/user/auth/logout','POST'),200,'OK');unicode_client.session()
expect(unicode_client.login(uname,upassword[:-2]+'小狗'),401,'INVALID_CREDENTIALS');expect(unicode_client.login(uname,upassword),200,'OK');passed('64-character Unicode password is not truncated')

# Verify revocation only for the random test accounts in the project-owned database.
client_config=ROOT/'.runtime'/'mysql'/'admin-client.cnf'
if client_config.exists():
    def sql(statement):
        import shutil
        result=subprocess.run([shutil.which('mysql.exe'),'--defaults-file='+str(client_config),'--default-character-set=utf8mb4','--database=pet_community','--batch','--skip-column-names'],input=statement.encode(),stdout=subprocess.PIPE,stderr=subprocess.PIPE,creationflags=subprocess.CREATE_NO_WINDOW)
        assert result.returncode==0,result.stderr.decode(errors='replace')
        return result.stdout.decode().strip()
    stored_hash=sql('SELECT password_hash FROM sys_user WHERE id='+user['id']+';')
    assert stored_hash.startswith('{pbkdf2}') and password not in stored_hash;passed('database stores salted PBKDF2 hash only')
    second=Client();second.session();expect(second.login(name,password),200,'OK')
    sql('UPDATE sys_user SET auth_version=auth_version+1 WHERE id='+user['id']+';')
    expect(c.request('/api/v1/user/auth/me'),401,'UNAUTHENTICATED');expect(second.request('/api/v1/user/auth/me'),401,'UNAUTHENTICATED');passed('auth version revokes every existing session')
    sql("UPDATE sys_user SET status='FROZEN' WHERE id="+user['id']+';');c.session();expect(c.login(name,password),403,'ACCOUNT_FROZEN');passed('frozen account cannot log in')
    sql("UPDATE sys_user SET status='ACTIVE' WHERE id="+user['id']+';')

limiter=Client();limiter.session()
# Other failed logins in this run count toward the same address limit.
limited=False
for attempt in range(12):
    response=limiter.login('missing_'+str(attempt),'DefinitelyWrong')
    if response[0]==429:
        assert int(response[2]['Retry-After'])>0;limited=True;break
    expect(response,401,'INVALID_CREDENTIALS')
assert limited;passed('HTTP login failure rate limit returns Retry-After')
out=ROOT/'docs'/'testing';out.mkdir(parents=True,exist_ok=True)
report={'checksPassed':len(RESULTS),'baseUrl':BASE,'checks':RESULTS}
(out/'api-results.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'passed':len(RESULTS)},ensure_ascii=True))
