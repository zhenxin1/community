"""Targeted final checks for media, quote selection, catalog privacy and DB invariants."""
from pathlib import Path
import shutil,sys,os,json,uuid,urllib.request,urllib.error,struct,zlib,subprocess,time
sys.path.insert(0,str(Path(__file__).parent));from integration import request,ok,manage
ROOT=Path(__file__).resolve().parents[1];checks=[]
def check(name,condition):
 checks.append({'name':name,'passed':bool(condition)});print(('PASS ' if condition else 'FAIL ')+name)
 if not condition:raise AssertionError(name)
def upload(token,content,name,kind):
 boundary='Boundary'+uuid.uuid4().hex
 data=(f'--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="{name}"\r\nContent-Type: {kind}\r\n\r\n'.encode()+content+f'\r\n--{boundary}--\r\n'.encode())
 headers={'Content-Type':'multipart/form-data; boundary='+boundary}
 if token:headers['Authorization']='Bearer '+token
 req=urllib.request.Request('http://127.0.0.1:8080/api/v1/uploads',data=data,headers=headers)
 try:
  with urllib.request.urlopen(req,timeout=30) as r:return r.status,json.load(r)
 except urllib.error.HTTPError as e:return e.code,json.load(e)
def png():
 def chunk(kind,data):return struct.pack('!I',len(data))+kind+data+struct.pack('!I',zlib.crc32(kind+data)&0xffffffff)
 return b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('!2I5B',2,2,8,2,0,0,0))+chunk(b'IDAT',zlib.compress((b'\0'+b'\x61\x94\x75'*2)*2))+chunk(b'IEND',b'')
def run():
 admin=ok('/auth/login','POST',manage.credentials()['admin'])['accessToken'];u=manage.credentials()['applicant'];user=ok('/auth/login','POST',u)['accessToken'];pub=ok('/auth/login','POST',manage.credentials()['publisher'])['accessToken']
 check('production root serves real Vue index','<title>寻爪' in urllib.request.urlopen('http://127.0.0.1:8080/').read().decode())
 check('production local asset served',urllib.request.urlopen('http://127.0.0.1:8080/assets/hero.webp').status==200)
 check('visitor upload refused',upload(None,png(),'fixture.png','image/png')[0]==401)
 check('SVG disguised as PNG refused',upload(user,b'<svg xmlns="http://www.w3.org/2000/svg"></svg>','bad.png','image/png')[0]==400)
 code,img=upload(user,png(),'fixture.png','image/png');check('real PNG upload accepted',code==200 and img['url'].startswith('/media/'))
 check('uploaded image readable',urllib.request.urlopen('http://127.0.0.1:8080'+img['url']).headers.get_content_type()=='image/png')
 check('nonexistent image rejected',request('/pets','POST',{'name':'测试','category':'cat','province':'测试','region':'测试','breed':'未知','description':'','image':'/assets/nonexistent.jpg','phone':'demo','wechat':'','email':''},pub)[0]==400)
 p=ok('/pets','POST',{'name':'qa媒体验证','category':'cat','province':'测试省','region':'教学测试区','breed':'未知','description':'图片上传集成测试','image':img['url'],'phone':'demo','wechat':'','email':''},pub)
 check('combined pet filtering',any(i['id']==p['id'] for i in ok('/pets?keyword=qa&category=cat&region='+urllib.parse.quote('教学测试区'))['items']))
 app=ok('/pets/'+p['id']+'/applications','POST',token=user);ok('/adoptions/'+app['id']+'/select','POST',token=pub);ok('/adoptions/'+app['id']+'/success','POST',token=pub);ok('/adoptions/'+app['id']+'/success','POST',token=user)
 check('media-created pet completes full adoption',ok('/pets/'+p['id'])['status']=='ADOPTED')
 catalog=ok('/products');check('hidden-only category not publicly exposed','测试用品' not in catalog['categories'])
 check('recommended products come first',catalog['items'][0]['recommended']==True)
 check('malformed page is validation error',request('/pets?page=bad')[0]==400)
 check('zero page is rejected',request('/products?page=0')[0]==400)
 # Use an isolated buyer so no demo cart is altered.
 tag='qa'+uuid.uuid4().hex[:8];pw='Qa7'+uuid.uuid4().hex[:12];ok('/auth/register','POST',{'account':tag,'password':pw,'confirmPassword':pw});buyer=ok('/auth/login','POST',{'account':tag,'password':pw})['accessToken']
 addr=ok('/addresses','POST',{'recipient':'测试','phone':'demo','address':'演示地址'},buyer)
 def product(price):return ok('/admin/products','POST',{'name':tag+'商品','category':'测试用品','description':'勾选测试','image':'/assets/cat.webp','price':price,'stock':10,'listed':True,'recommended':False,'version':0},admin)
 a,b=product(30000),product(60000)
 ok('/cart/'+a['id'],'POST',{'quantity':1,'selected':True},buyer);ok('/cart/'+b['id'],'POST',{'quantity':1,'selected':False},buyer)
 q=ok('/orders/quote?addressId='+addr['id'],token=buyer);check('unselected item excluded from discount threshold',q['subtotal']==30000 and q['payable']==21600 and len(q['items'])==1)
 o=ok('/orders','POST',{'addressId':addr['id'],'quoteToken':q['quoteToken'],'operationId':str(uuid.uuid4())},buyer);check('unselected cart line retained',len(ok('/cart',token=buyer)['items'])==1)
 before=ok('/products/'+a['id']);ok('/orders/'+o['id']+'/pay','POST',{'success':True},buyer)
 payload={k:before[k] for k in ['name','category','description','image','price','stock','listed','recommended','version']};check('stale admin stock version rejected after payment',request('/admin/products/'+a['id'],'PUT',payload,admin)[0]==409)
 for p in [a,b]:
  now=ok('/products/'+p['id']);ok('/admin/products/'+p['id'],'PUT',{k:now[k] for k in ['name','category','description','image','price','stock','recommended','version']}|{'listed':False},admin)
 cfg=manage.config();env=os.environ.copy();env['MYSQL_PWD']=cfg['DB_PASSWORD']
 sql="SELECT (SELECT COUNT(*) FROM product WHERE stock<0),(SELECT COUNT(*) FROM adoption_result r JOIN pet p ON p.id=r.pet_id JOIN adoption_application a ON a.id=r.application_id WHERE p.status<>'ADOPTED' OR a.status<>'SUCCESS'),(SELECT COUNT(*) FROM (SELECT pet_id,COUNT(*) n FROM adoption_application WHERE status='SELECTED' GROUP BY pet_id HAVING n>1) x);"
 client=os.environ.get('MYSQL_BIN') or shutil.which('mysql') or r'D:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe'
 res=subprocess.run([client,'-h','127.0.0.1','-u',cfg['DB_USERNAME'],'--batch','--skip-column-names','pet_final','-e',sql],env=env,capture_output=True,text=True)
 check('actual database inventory and adoption invariants',res.returncode==0 and res.stdout.strip()=='0\t0\t0')
if __name__=='__main__':
 failure=None
 try:run()
 except Exception as e:failure=type(e).__name__+': '+str(e);print('FAILED',failure)
 (ROOT/'evidence/quality-results.json').write_text(json.dumps({'executedAt':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),'checks':checks,'failure':failure},ensure_ascii=False,indent=2),encoding='utf-8')
 if failure:raise SystemExit(1)
 print(f'{len(checks)} final checks passed')
