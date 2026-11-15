package com.example.petadoptioncommunity.identity;
import com.example.petadoptioncommunity.web.ApiFailure;
import org.springframework.stereotype.Service;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import java.time.*;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeFormatterBuilder;
import java.security.*;
import java.util.*;
import java.util.function.Supplier;
@Service
public class IdentityService implements IdentityPort {
 private final IdentityMapper db; private final PasswordEncoder passwords; private final TransactionTemplate tx;
 private final SecureRandom random=new SecureRandom();
 private final String dummy;
 private static final DateTimeFormatter TIME=new DateTimeFormatterBuilder().appendInstant(3).toFormatter();
 public record User(String id,String account,String nickname,String role,String status,String createdAt){}
 public record LoginResult(String accessToken,String expiresAt,User user){ @Override public String toString(){return "LoginResult[redacted]";} }
 public static class Frozen extends ApiFailure {
  public final String reason,actionAt;
  Frozen(IdentityMapper.Account a){super(403,"ACCOUNT_FROZEN_VERIFIED","请联系管理员线下核实");reason=a.latestReason();actionAt=TIME.format(a.latestActionAt());}
 }
 public IdentityService(IdentityMapper db,PasswordEncoder passwords,PlatformTransactionManager manager){
  this.db=db;this.passwords=passwords;tx=new TransactionTemplate(manager);tx.setIsolationLevel(TransactionDefinition.ISOLATION_READ_COMMITTED);dummy=passwords.encode(UUID.randomUUID().toString());
 }
 private User user(IdentityMapper.Account a){return new User(a.id(),a.account(),a.nickname(),a.role(),a.status(),TIME.format(a.createdAt()));}
 public User register(String account,String password,String confirmation){
  account=AccountRules.account(account);AccountRules.password(password);
  if(!password.equals(confirmation))throw AccountRules.invalid();
  var a=new IdentityMapper.Account(UUID.randomUUID().toString(),account,passwords.encode(password),"USER","ACTIVE",account,0,0,Instant.now(),null,null);
  try{tx.executeWithoutResult(s->db.insertAccount(a));}catch(DuplicateKeyException e){throw new ApiFailure(409,"ACCOUNT_TAKEN","账号已占用");}return user(a);
 }
 public LoginResult login(String account,String password){
  account=AccountRules.account(account);AccountRules.loginPassword(password);
  var initial=db.byAccount(account);
  boolean matches=passwords.matches(password,initial==null?dummy:initial.passwordHash());
  if(initial==null||!matches)throw badLogin();
  return tx.execute(s->{
   var a=db.lockAccount(initial.id());
   if(a==null||!a.passwordHash().equals(initial.passwordHash()))throw badLogin();
   if(!"ACTIVE".equals(a.status()))throw new Frozen(a);
   byte[] bytes=new byte[32];random.nextBytes(bytes);
   String token=Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
   Instant expires=Instant.now().plusSeconds(1800);
   db.insertSession(new IdentityMapper.Session(hash(token),a.id(),a.authVersion(),a.stateVersion(),expires,null));
   return new LoginResult(token,TIME.format(expires),user(a));
  });
 }
 private ApiFailure badLogin(){return new ApiFailure(401,"UNAUTHENTICATED","账号或密码错误");}
 private ApiFailure invalid(){return new ApiFailure(401,"SESSION_INVALID","会话无效，请重新登录");}
 public static String token(String credential){return credential!=null&&credential.startsWith("Bearer ")?credential.substring(7):null;}
 private static byte[] hash(String token){try{return MessageDigest.getInstance("SHA-256").digest(token.getBytes(java.nio.charset.StandardCharsets.UTF_8));}catch(NoSuchAlgorithmException e){throw new IllegalStateException(e);}}
 private boolean valid(IdentityMapper.Account a,IdentityMapper.Session s){return a!=null&&s!=null&&a.id().equals(s.userId())&&"ACTIVE".equals(a.status())&&s.revokedAt()==null&&s.expiresAt().isAfter(Instant.now())&&a.authVersion()==s.authVersion()&&a.stateVersion()==s.stateVersion();}
 @Override public Actor requireActive(String credential){
  String token=token(credential);if(token==null||token.length()!=43)throw invalid();
  var s=db.session(hash(token));var a=s==null?null:db.byId(s.userId());if(!valid(a,s))throw invalid();
  return new Actor(a.id(),a.role(),a.stateVersion(),a.authVersion(),HexFormat.of().formatHex(hash(token)));
 }
 @Override public <T>T withActiveActor(Actor actor,Collection<String> ids,Supplier<T> work){
  return tx.execute(status->{
   var ordered=new TreeSet<String>(ids);ordered.add(actor.userId());
   IdentityMapper.Account account=null;
   for(String id:ordered){var locked=db.lockAccount(id);if(id.equals(actor.userId()))account=locked;}
   var session=db.lockSession(HexFormat.of().parseHex(actor.sessionKey()));
   if(!valid(account,session)||!account.role().equals(actor.role())||account.authVersion()!=actor.authVersion()||account.stateVersion()!=actor.stateVersion())throw invalid();
   T result=work.get();
   if(!valid(db.byId(actor.userId()),db.session(HexFormat.of().parseHex(actor.sessionKey()))))throw invalid();
   return result;
  });
 }
 @Override public PublicIdentity readPublicIdentity(String id){var a=db.byId(id);if(a==null)throw new ApiFailure(404,"NOT_FOUND","用户不存在");return new PublicIdentity(a.id(),a.nickname());}
 public void logout(String credential){
  String token=token(credential);if(token==null||token.length()!=43)return;
  var candidate=db.session(hash(token));if(candidate==null)return;
  tx.executeWithoutResult(status->{var a=db.lockAccount(candidate.userId());var s=db.lockSession(hash(token));if(valid(a,s))db.revoke(hash(token),Instant.now());});
 }
 public record Profile(String id,String account,String nickname,String role,String status,String createdAt,String bio,long profileVersion){}
 private Profile profile(String id){var p=db.profile(id);return new Profile(p.id(),p.account(),p.nickname(),p.role(),p.status(),TIME.format(p.createdAt()),p.bio(),p.profileVersion());}
 public Profile me(Actor actor){return withActiveActor(actor,List.of(),()->profile(actor.userId()));}
 public Profile updateProfile(Actor actor,String nickname,String bio,Long version){
  if(nickname==null||bio==null||version==null||version<0)throw AccountRules.invalid();
  String normalized=AccountRules.trimAccount(nickname);
  int count=normalized.codePointCount(0,normalized.length());
  if(count<1||count>30||bio.codePointCount(0,bio.length())>200)throw AccountRules.invalid();
  return withActiveActor(actor,List.of(),()->{
   if(db.updateProfile(actor.userId(),normalized,bio,version)!=1)throw new ApiFailure(409,"VERSION_CONFLICT","资料已变更，请刷新核对");
   return profile(actor.userId());
  });
 }
 public void changePassword(Actor actor,String oldPassword,String newPassword,String confirmation){
  AccountRules.loginPassword(oldPassword);AccountRules.password(newPassword);
  if(!newPassword.equals(confirmation)||newPassword.equals(oldPassword))throw AccountRules.invalid();
  tx.executeWithoutResult(status->{
   var a=db.lockAccount(actor.userId());
   var key=HexFormat.of().parseHex(actor.sessionKey());var session=db.lockSession(key);
   // Always verify the current hash while holding the account lock, including competing rotations.
   boolean matches=a!=null&&passwords.matches(oldPassword,a.passwordHash());
   if(!valid(a,session)||!a.role().equals(actor.role())||a.authVersion()!=actor.authVersion()||a.stateVersion()!=actor.stateVersion())throw invalid();
   if(!matches)throw new ApiFailure(400,"VALIDATION_ERROR","原密码错误");
   String encoded=passwords.encode(newPassword);db.rotatePassword(a.id(),encoded);db.revokeAll(a.id(),Instant.now());
   var updated=db.byId(a.id());var revoked=db.session(key);
   if(updated.authVersion()!=a.authVersion()+1||!updated.passwordHash().equals(encoded)||!updated.status().equals(a.status())||updated.stateVersion()!=a.stateVersion()||revoked.revokedAt()==null||!revoked.expiresAt().isAfter(Instant.now()))throw new IllegalStateException("Credential rotation invariant failed");
  });
 }
 public String initializeAdmin(String account,String password){
  String normalized=AccountRules.account(account);AccountRules.loginPassword(password);
  try { return tx.execute(s->{var exists=db.byAccount(normalized);if(exists!=null)return "ADMIN".equals(exists.role())?"ADMIN_ALREADY_EXISTS":"ACCOUNT_CONFLICT";
   var a=new IdentityMapper.Account(UUID.randomUUID().toString(),normalized,passwords.encode(password),"ADMIN","ACTIVE",normalized,0,0,Instant.now(),null,null);
   db.insertAccount(a);return "ADMIN_CREATED";});
  } catch(DuplicateKeyException duplicate) { return tx.execute(s->{var exists=db.byAccount(normalized);if(exists==null)throw duplicate;return "ADMIN".equals(exists.role())?"ADMIN_ALREADY_EXISTS":"ACCOUNT_CONFLICT";}); }
 }
}
