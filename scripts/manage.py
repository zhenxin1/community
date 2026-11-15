"""Local course project lifecycle. Standard library only, secrets never printed."""
from pathlib import Path
import os,sys,json,subprocess,shutil,getpass,secrets,string,urllib.request,urllib.error
ROOT=Path(__file__).resolve().parents[1];APP=ROOT/'PetAdoptionCommunity';LOCAL=ROOT/'.local';LOCAL.mkdir(exist_ok=True)
def config():
 data=json.loads((LOCAL/'runtime.json').read_text(encoding='utf-8')) if (LOCAL/'runtime.json').exists() else {}
 for k in ['DB_URL','DB_USERNAME','DB_PASSWORD']:
  if k in os.environ:data[k]=os.environ[k]
 return data
def write_idea_config(data):
 # Generated private Spring configuration; runtime.json remains the input source.
 def escape(value):
  text=str(value).replace('\\','\\\\').replace('\r','\\r').replace('\n','\\n').replace('\t','\\t')
  return ('\\ '+text[1:]) if text.startswith(' ') else text
 keys={'spring.datasource.url':'DB_URL','spring.datasource.username':'DB_USERNAME','spring.datasource.password':'DB_PASSWORD'}
 lines=['# Generated from runtime.json by manage.py configure. Local secrets; never commit.']
 lines.extend(key+'='+escape(data[name]) for key,name in keys.items())
 (LOCAL/'application-local.properties').write_text('\n'.join(lines)+'\n',encoding='utf-8')
def java():
 home=os.environ.get('JAVA_HOME')
 if home:return str(Path(home)/'bin/java.exe') if os.name=='nt' else str(Path(home)/'bin/java')
 return shutil.which('java') or 'java'
def invoke(path,method='GET',body=None,token=None):
 headers={'Content-Type':'application/json'}
 if token:headers['Authorization']='Bearer '+token
 q=urllib.request.Request('http://127.0.0.1:8080/api/v1'+path,data=json.dumps(body,ensure_ascii=False).encode('utf-8') if body is not None else None,headers=headers,method=method)
 try:
  with urllib.request.urlopen(q,timeout=30) as r:return json.load(r) if r.status!=204 else None
 except urllib.error.HTTPError as e:
  data=json.load(e);raise RuntimeError(str(e.code)+' '+data.get('message','API failed')) from None
def credentials():
 p=LOCAL/'demo-credentials.json'
 if not p.exists():
  pw=lambda:'Aa7'+''.join(secrets.choice(string.ascii_letters+string.digits) for _ in range(15))
  p.write_text(json.dumps({k:{'account':a,'password':pw()} for k,a in [('admin','admin'),('publisher','linlin'),('applicant','xiaoyu'),('secondApplicant','anan')]},indent=2),encoding='utf-8')
 return json.loads(p.read_text(encoding='utf-8'))
def seed():
 if (LOCAL/'seed.json').exists():print('Demo seed already recorded; no existing data changed.');return
 users=credentials()
 for role,u in users.items():
  if role!='admin':
   try:invoke('/auth/register','POST',{**u,'confirmPassword':u['password']})
   except RuntimeError as e:
    if not str(e).startswith('409 '):raise
  login=invoke('/auth/login','POST',u);u['token']=login['accessToken'];u['id']=login['user']['id']
 admin=users['admin']['token'];publisher=users['publisher']['token']
 pets=[('芋圆','cat','中华田园猫','湖北省','武汉市','taro','有一点慢热，也很喜欢靠着人睡觉。希望找到耐心、稳定的家庭。'),('芝麻','cat','中华田园猫','浙江省','杭州市','sesame','活泼好奇，喜欢窗边的阳光。请做好封窗与长期陪伴准备。'),('麦芽','dog','混种犬','江苏省','南京市','malt','温柔亲人，喜欢散步。希望你能每天留出陪伴和运动的时间。'),('云朵','cat','长毛猫','上海市','浦东新区','cloud','安静乖巧，需要定期梳毛和耐心照料。'),('栗子','cat','中华田园猫','湖北省','武汉市','chestnut','对世界充满好奇，喜欢探索和奔跑。'),('豆豆','dog','混种犬','四川省','成都市','bean','亲人爱玩，期待一个稳定温暖的家。')]
 petIds=[]
 for name,cat,breed,province,region,image,desc in pets:
  p=invoke('/pets','POST',{'name':name,'category':cat,'breed':breed,'province':province,'region':region,'image':'/assets/'+image+'.webp','description':desc+'【教学演示资料】','phone':'','wechat':'demo_contact_only','email':''},publisher);petIds.append(p['id'])
 categories=[('主粮','food','均衡营养主粮'),('零食','snack','训练奖励小零食'),('营养保健品','nutrition','日常营养补充'),('食具','bowl','易清洁宠物食盆'),('窝垫','bed','柔软舒适睡垫'),('围栏','fence','家用宠物围栏'),('环境用品','environment','宠物家居小物'),('洗护','wash','温和宠物洗护'),('工具','brush','日常梳毛工具'),('除味消毒','clean','宠物环境清洁'),('牵引','leash','日常出行牵引'),('玩具','toy','互动陪伴玩具'),('服饰','clothes','舒适宠物衣物'),('驱虫护理','care','日常护理用品')]
 assets=APP/'vue1/public/assets';productIds=[]
 for i,(category,prefix,name) in enumerate(categories):
  for n in range(1,3):
   image=next(iter(assets.glob(prefix+'-'+str(n)+'.svg')),None)
   if not image:image=next(iter(assets.glob(prefix+'*.svg')),None)
   url='/assets/'+image.name if image else '/assets/'+['cat','treat','bowl','wand','dog'][i%5]+'.webp'
   if i==0:url='/assets/'+('cat' if n==1 else 'dog')+'.webp'
   p=invoke('/admin/products','POST',{'name':name+(' · 经典款' if n==1 else ' · 轻享款'),'category':category,'description':'为日常陪伴准备的一份贴心选择。适用情况请在购买前认真核对。此为教学演示商品，不提供实际商品或医疗建议。','image':url,'price':int((39+i*11+n*10)*100),'stock':30,'listed':True,'recommended':i<3,'version':0},admin);productIds.append(p['id'])
 for u in users.values():invoke('/auth/logout','POST',None,u['token'])
 (LOCAL/'seed.json').write_text(json.dumps({'petIds':petIds,'productIds':productIds},ensure_ascii=False,indent=2),encoding='utf-8')
 print('Seeded 6 pets and 28 products in 14 categories. Demo credentials are in ignored .local/demo-credentials.json.')
def main():
 action=sys.argv[1] if len(sys.argv)>1 else 'help'
 if action=='configure':
  data={'DB_URL':'jdbc:mysql://127.0.0.1:3306/pet_final?connectionTimeZone=UTC&forceConnectionTimeZoneToSession=true','DB_USERNAME':input('MySQL username: ').strip() or 'root','DB_PASSWORD':getpass.getpass('MySQL password (hidden): ')}
  (LOCAL/'runtime.json').write_text(json.dumps(data,indent=2),encoding='utf-8');write_idea_config(data);credentials();print('Ignored local configuration saved for scripts and IDEA.');return
 env=os.environ.copy();env.update(config())
 if action=='serve':
  jar=APP/'target/PetAdoptionCommunity-0.0.1-SNAPSHOT.jar'
  if not jar.exists():raise RuntimeError('Build first: scripts/build.ps1')
  raise SystemExit(subprocess.call([java(),'-jar',str(jar)],cwd=APP,env=env))
 if action=='init':
  if set(['DB_URL','DB_USERNAME','DB_PASSWORD'])-env.keys():raise RuntimeError('Configure DB first')
  if '/pet_final?' not in env['DB_URL']:raise RuntimeError('Initialization is restricted to pet_final')
  mysql=shutil.which('mysql')
  if not mysql:raise RuntimeError('Put MySQL client on PATH')
  sqlenv=env.copy();sqlenv['MYSQL_PWD']=env['DB_PASSWORD']
  subprocess.run([mysql,'-h','127.0.0.1','-u',env['DB_USERNAME'],'-e','CREATE DATABASE IF NOT EXISTS pet_final CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci'],env=sqlenv,check=True)
  cp=str(APP/'target/classes')+os.pathsep+(APP/'target/classpath.txt').read_text().strip()
  base=[java(),'-cp',cp,'com.example.petadoptioncommunity.operations.Offline']
  subprocess.run(base+['migrate'],cwd=APP,env=env,check=True)
  u=credentials()['admin'];subprocess.run(base+['admin-stdin'],input=u['account']+'\n'+u['password']+'\n',encoding='utf-8',cwd=APP,env=env,check=True)
  print('Schema and offline ADMIN initialized; existing accounts never reset.');return
 if action=='seed':seed();return
 print('Usage: python scripts/manage.py configure | init | serve | seed')
if __name__=='__main__':main()
