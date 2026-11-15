"""Real HTTP + MySQL integration tests. Creates only labelled test records; no resets."""
import sys,os,json,uuid,time,concurrent.futures,threading,urllib.request,urllib.error,importlib.util,struct,zlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('manage',ROOT/'scripts/manage.py');manage=importlib.util.module_from_spec(spec);spec.loader.exec_module(manage)
BASE='http://127.0.0.1:8080/api/v1';results=[]
def check(name,condition):
 results.append({'name':name,'passed':bool(condition)})
 print(('PASS ' if condition else 'FAIL ')+name)
 if not condition:raise AssertionError(name)
def request(path,method='GET',body=None,token=None):
 headers={'Content-Type':'application/json'}
 if token:headers['Authorization']='Bearer '+token
 req=urllib.request.Request(BASE+path,data=json.dumps(body,ensure_ascii=False).encode() if body is not None else None,headers=headers,method=method)
 try:
  with urllib.request.urlopen(req,timeout=30) as r:return r.status,json.load(r) if r.status!=204 else None
 except urllib.error.HTTPError as e:
  try:return e.code,json.load(e)
  except:return e.code,{}
def ok(path,method='GET',body=None,token=None):
 status,data=request(path,method,body,token)
 if status>=400:raise RuntimeError(f'{method} {path}: {status} {data.get("message", "")}')
 return data
def parallel(calls):
 barrier=threading.Barrier(len(calls))
 def invoke(fn):barrier.wait();return fn()
 with concurrent.futures.ThreadPoolExecutor(max_workers=len(calls)) as pool:return list(pool.map(invoke,calls))
def run():
 tag='qa'+uuid.uuid4().hex[:8];password='TestSafe'+uuid.uuid4().hex[:16]+'7'
 users=[]
 for n in range(4):
  account=tag+str(n);u=ok('/auth/register','POST',{'account':account,'password':password,'confirmPassword':password});login=ok('/auth/login','POST',{'account':account,'password':password});users.append({'id':u['id'],'token':login['accessToken'],'account':account})
 pub,u1,u2,outsider=users;adminCred=manage.credentials()['admin'];admin=ok('/auth/login','POST',adminCred)['accessToken']
 check('unknown registration fields cannot elevate',request('/auth/register','POST',{'account':tag+'z','password':password,'confirmPassword':password,'role':'ADMIN'})[0]==400)
 check('wrong login generic rejection',request('/auth/login','POST',{'account':u1['account'],'password':'wrong'})[0]==401)
 check('USER cannot administer users',request('/admin/users',token=u1['token'])[0]==403)
 check('visitor protected request rejected',request('/cart')[0]==401)
 me=ok('/me',token=u1['token']);updated=ok('/me','PUT',{'nickname':'测试成员','bio':'<script>text only</script>','expectedProfileVersion':me['profileVersion']},u1['token'])
 check('profile plain text stored',updated['bio']=='<script>text only</script>')
 check('stale profile version rejected',request('/me','PUT',{'nickname':'old','bio':'','expectedProfileVersion':me['profileVersion']},u1['token'])[0]==409)
 check('foreign profile query rejected',request('/me?userId='+pub['id'],token=u1['token'])[0]==400)
 op=str(uuid.uuid4());detail=ok('/admin/users/'+outsider['id'],token=admin);body={'operationId':op,'expectedStateVersion':detail['stateVersion'],'targetStatus':'FROZEN','reason':'自动化测试处置'}
 first=ok('/admin/users/'+outsider['id']+'/state','POST',body,admin);second=ok('/admin/users/'+outsider['id']+'/state','POST',body,admin)
 check('freeze repeated command has one result',first['notificationId']==second['notificationId'] and second['replayed'])
 check('frozen old session revoked',request('/cart',token=outsider['token'])[0]==401)
 check('frozen reason only after valid credential',request('/auth/login','POST',{'account':outsider['account'],'password':password})[1].get('reason')=='自动化测试处置')
 ok('/admin/users/'+outsider['id']+'/state','POST',{'operationId':str(uuid.uuid4()),'expectedStateVersion':first['stateVersion'],'targetStatus':'ACTIVE','reason':'测试结束解冻'},admin)
 check('unfreeze does not restore old session',request('/cart',token=outsider['token'])[0]==401)
 outsider['token']=ok('/auth/login','POST',{'account':outsider['account'],'password':password})['accessToken']
 message={'operationId':str(uuid.uuid4()),'title':'测试通知','body':'单用户教学说明'};n=ok('/admin/users/'+outsider['id']+'/notifications','POST',message,admin);nn=ok('/admin/users/'+outsider['id']+'/notifications','POST',message,admin)
 check('message idempotency',n['notificationId']==nn['notificationId'])
 check('foreign notification rejected',request('/me/notifications/'+n['notificationId'],token=u1['token'])[0]==403)
 read1=ok('/me/notifications/'+n['notificationId']+'/read','PUT',token=outsider['token']);read2=ok('/me/notifications/'+n['notificationId']+'/read','PUT',token=outsider['token']);check('read keeps first timestamp',read1['readAt']==read2['readAt'])
 def pet():return ok('/pets','POST',{'name':tag+'伙伴','category':'cat','province':'测试省','region':'教学演示','breed':'未知','description':'集成测试记录','image':'/assets/taro.webp','phone':'demo-phone','wechat':'','email':''},pub['token'])
 p=pet();pid=p['id']
 check('visitor contacts absent',not any(k in ok('/pets/'+pid) for k in ['phone','wechat','email']))
 check('logged in available contact visible',ok('/pets/'+pid,token=u1['token'])['phone']=='demo-phone')
 check('self application rejected',request('/pets/'+pid+'/applications','POST',token=pub['token'])[0]==400)
 applications=parallel([lambda:request('/pets/'+pid+'/applications','POST',token=u1['token']),lambda:request('/pets/'+pid+'/applications','POST',token=u1['token'])]);check('parallel same applicant one active application',applications[0][1]['id']==applications[1][1]['id'])
 a1=applications[0][1];a2=ok('/pets/'+pid+'/applications','POST',token=u2['token']);selections=parallel([lambda:request('/adoptions/'+a1['id']+'/select','POST',token=pub['token']),lambda:request('/adoptions/'+a2['id']+'/select','POST',token=pub['token'])]);check('parallel selection one winner',sorted(x[0] for x in selections)==[200,409])
 idx=0 if selections[0][0]==200 else 1;chosen=[a1,a2][idx];chosenUser=[u1,u2][idx];otherUser=[u2,u1][idx]
 check('handover other applicant contacts removed','phone' not in ok('/pets/'+pid,token=otherUser['token']))
 check('unrelated confirmation rejected',request('/adoptions/'+chosen['id']+'/success','POST',token=outsider['token'])[0]==403)
 ok('/adoptions/'+chosen['id']+'/success','POST',token=pub['token']);one=ok('/adoptions/'+chosen['id']+'/success','POST',token=pub['token']);check('single party repeat remains selected',one['status']=='SELECTED')
 confirmations=parallel([lambda:request('/adoptions/'+chosen['id']+'/success','POST',token=chosenUser['token']),lambda:request('/adoptions/'+chosen['id']+'/success','POST',token=chosenUser['token'])]);check('double confirmation repeated remains successful',all(x[0]==200 and x[1]['status']=='SUCCESS' for x in confirmations))
 check('adopted no new applications',request('/pets/'+pid+'/applications','POST',token=outsider['token'])[0]==409)
 p2=pet();a=ok('/pets/'+p2['id']+'/applications','POST',token=u1['token']);ok('/adoptions/'+a['id']+'/select','POST',token=pub['token']);ok('/adoptions/'+a['id']+'/success','POST',token=pub['token']);ok('/adoptions/'+a['id']+'/failure','POST',token=u1['token']);check('failure restores available',ok('/pets/'+p2['id'])['status']=='AVAILABLE')
 new=ok('/pets/'+p2['id']+'/applications','POST',token=u2['token']);ok('/adoptions/'+new['id']+'/select','POST',token=pub['token']);check('old successful confirmation cannot affect new handover',request('/adoptions/'+a['id']+'/success','POST',token=u1['token'])[0]==409)
 def product(stock=3,price=30000):return ok('/admin/products','POST',{'name':tag+'商品','category':'测试用品','description':'自动化隔离测试商品','image':'/assets/cat.webp','price':price,'stock':stock,'listed':True,'recommended':False,'version':0},admin)
 prod=product(1);prid=prod['id'];check('USER cannot create product',request('/admin/products','POST',{},u1['token'])[0]==403)
 check('fractional cart quantity rejected',request('/cart/'+prid,'POST',{'quantity':1.5,'selected':True},u1['token'])[0]==400)
 def address(u):return ok('/addresses','POST',{'recipient':'测试收件人','phone':'demo-only','address':'课程测试地址，无真实信息'},u['token'])
 ad1,ad2=address(u1),address(u2)
 check('foreign address modification rejected',request('/addresses/'+ad1['id'],'PUT',{'recipient':'x','phone':'x','address':'x','version':0},u2['token'])[0]==403)
 def create(u,addr,pid=prid):
  ok('/cart/'+pid,'POST',{'quantity':1,'selected':True},u['token']);q=ok('/orders/quote?addressId='+addr['id'],token=u['token']);body={'addressId':addr['id'],'quoteToken':q['quoteToken'],'operationId':str(uuid.uuid4())};return ok('/orders','POST',body,u['token']),body,q
 o1,body,q=create(u1,ad1);check('300 threshold with 20 percent discount',q['payable']==21600 and q['discount']==3000 and q['subsidy']==5400)
 replay=ok('/orders','POST',body,u1['token']);check('order creation same key one order',o1['id']==replay['id'])
 check('order cannot read across user',request('/orders/'+o1['id'],token=u2['token'])[0]==403)
 pendingAdmin=next(o for o in ok('/admin/orders',token=admin) if o['id']==o1['id']);check('admin unpaid shipping privacy',all(k not in pendingAdmin for k in ['address','phone','recipient']))
 check('unpaid cannot ship',request('/admin/orders/'+o1['id']+'/ship','POST',{'carrier':'demo','tracking':'test'},admin)[0]==409)
 o2,_,_=create(u2,ad2)
 pay=parallel([lambda:request('/orders/'+o1['id']+'/pay','POST',{'success':True},u1['token']),lambda:request('/orders/'+o2['id']+'/pay','POST',{'success':True},u2['token'])]);check('last stock one payment winner',sorted(p[0] for p in pay)==[200,409])
 winner=o1 if pay[0][0]==200 else o2;winnerUser=u1 if pay[0][0]==200 else u2
 ok('/orders/'+winner['id']+'/pay','POST',{'success':True},winnerUser['token']);check('repeat payment no negative stock',ok('/products/'+prid)['stock']==0)
 ok('/admin/orders/'+winner['id']+'/ship','POST',{'carrier':'课程模拟物流','tracking':'DEMO-NOT-REAL'},admin);ok('/orders/'+winner['id']+'/receive','POST',token=winnerUser['token']);rec=ok('/orders/'+winner['id']+'/receive','POST',token=winnerUser['token']);check('shipment receipt idempotent',rec['status']=='COMPLETED')
 # Multi-item atomic failure: no stock deduction in any line.
 x,y=product(2,10001),product(2,59999)
 ok('/cart/'+x['id'],'POST',{'quantity':1,'selected':True},u1['token']);ok('/cart/'+y['id'],'POST',{'quantity':1,'selected':True},u1['token']);q=ok('/orders/quote?addressId='+ad1['id'],token=u1['token']);multi=ok('/orders','POST',{'addressId':ad1['id'],'quoteToken':q['quoteToken'],'operationId':str(uuid.uuid4())},u1['token'])
 y2=ok('/products/'+y['id']);ok('/admin/products/'+y['id'],'PUT',{k:y2[k] for k in ['name','category','description','image','price','listed','recommended','version']}|{'stock':0},admin)
 check('multi-product stock failure rejects whole payment',request('/orders/'+multi['id']+'/pay','POST',{'success':True},u1['token'])[0]==409)
 check('multi-product stock failure leaves other stock',ok('/products/'+x['id'])['stock']==2 and ok('/orders/'+multi['id'],token=u1['token'])['status']=='PENDING')
 ok('/orders/'+multi['id']+'/cancel','POST',token=u1['token']);check('cancelled payment rejected',request('/orders/'+multi['id']+'/pay','POST',{'success':True},u1['token'])[0]==409)
 # Quote changes, address snapshot, deselected items and payment/cancel competition.
 z=product(4,60000);ok('/cart/'+z['id'],'POST',{'quantity':1,'selected':True},u2['token']);q=ok('/orders/quote?addressId='+ad2['id'],token=u2['token']);body={'addressId':ad2['id'],'quoteToken':q['quoteToken'],'operationId':str(uuid.uuid4())};ok('/addresses/'+ad2['id'],'PUT',{'recipient':'变更','phone':'demo','address':'另一个演示地址','version':ad2['version']},u2['token']);check('address changed quote requires reconfirmation',request('/orders','POST',body,u2['token'])[0]==409)
 q=ok('/orders/quote?addressId='+ad2['id'],token=u2['token']);o=ok('/orders','POST',{'addressId':ad2['id'],'quoteToken':q['quoteToken'],'operationId':str(uuid.uuid4())},u2['token']);race=parallel([lambda:request('/orders/'+o['id']+'/pay','POST',{'success':True},u2['token']),lambda:request('/orders/'+o['id']+'/cancel','POST',token=u2['token'])]);check('payment cancel competition one effective state',sorted(x[0] for x in race)==[200,409]);final=ok('/orders/'+o['id'],token=u2['token']);stock=ok('/products/'+z['id'])['stock'];check('payment cancel stock agrees with state',(final['status']=='PAID' and stock==3) or (final['status']=='CANCELLED' and stock==4))
 # Password rotation + independent sessions.
 secondLogin=ok('/auth/login','POST',{'account':u1['account'],'password':password});ok('/me/password','POST',{'oldPassword':password,'newPassword':password+'X','confirmPassword':password+'X'},u1['token']);check('password rotation revokes all sessions',request('/me',token=u1['token'])[0]==401 and request('/me',token=secondLogin['accessToken'])[0]==401)
 check('new password authenticates',request('/auth/login','POST',{'account':u1['account'],'password':password+'X'})[0]==200)
 # Retire test listings; retain records for audit without cluttering demo catalog.
 for p in [prod,x,y,z]:
  current=ok('/products/'+p['id']);ok('/admin/products/'+p['id'],'PUT',{k:current[k] for k in ['name','category','description','image','price','stock','recommended','version']}|{'listed':False},admin)
 # pet2 remains HANDOVER, pet1 ADOPTED, so neither appears in public available list.
 print('Run tag:',tag)
if __name__=='__main__':
 started=time.time();failure=None
 try:run()
 except Exception as e:failure=type(e).__name__+': '+str(e);print('FAILED:',failure)
 finally:
  out=ROOT/'evidence';out.mkdir(exist_ok=True)
  (out/'integration-results.json').write_text(json.dumps({'executedAt':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),'seconds':round(time.time()-started,3),'checks':results,'failure':failure,'environment':'Java17 SpringBoot4.1.2 MySQL8.0.45 real HTTP; no mocks; labelled test records retained'},ensure_ascii=False,indent=2),encoding='utf-8')
 if failure:raise SystemExit(1)
 print(f'{len(results)} checks passed')
