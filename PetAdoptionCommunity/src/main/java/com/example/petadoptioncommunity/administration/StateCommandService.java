package com.example.petadoptioncommunity.administration;
import com.example.petadoptioncommunity.identity.*;
import com.example.petadoptioncommunity.web.ApiFailure;
import org.springframework.stereotype.Service;
import tools.jackson.databind.ObjectMapper;
import java.util.*;
import java.time.Instant;
import java.security.MessageDigest;
import java.nio.charset.StandardCharsets;
@Service public class StateCommandService {
 private final IdentityService identity;private final IdentityMapper users;private final StateCommandMapper db;private final ObjectMapper json=new ObjectMapper();
 public StateCommandService(IdentityService identity,IdentityMapper users,StateCommandMapper db){this.identity=identity;this.users=users;this.db=db;}
 public record Result(String operationId,String targetId,String outcome,long stateVersion,String notificationId,boolean replayed){}
 public static String uuid(String value){if(value==null||!value.matches("[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"))throw AccountRules.invalid();return value.toLowerCase(Locale.ROOT);}
 private void admin(IdentityPort.Actor actor){if(!"ADMIN".equals(actor.role()))throw new ApiFailure(403,"FORBIDDEN","无权限");}
 private Result result(StateCommandMapper.Command c,boolean replay){var r=json.readValue(c.resultJson(),Result.class);return new Result(r.operationId(),r.targetId(),r.outcome(),r.stateVersion(),r.notificationId(),replay);}
 public Result get(IdentityPort.Actor actor,String operation){String id=uuid(operation);return identity.withActiveActor(actor,List.of(),()->{admin(actor);var c=db.command(actor.userId(),id);if(c==null)throw new ApiFailure(404,"NOT_FOUND","当前没有已提交结果；仍可使用原标识和原内容重试");return result(c,true);});}
 public Result execute(IdentityPort.Actor actor,String target,String operation,Long version,String status,String reason){
  String id=uuid(target),op=uuid(operation);if(version==null||version<0||status==null||!Set.of("ACTIVE","FROZEN").contains(status)||reason==null)throw AccountRules.invalid();
  String normalized=AccountRules.trimAccount(reason);int length=normalized.codePointCount(0,normalized.length());if(length<1||length>200)throw AccountRules.invalid();
  byte[] payload;try{payload=MessageDigest.getInstance("SHA-256").digest(json.writeValueAsString(List.of("STATE",id,status,version,normalized)).getBytes(StandardCharsets.UTF_8));}catch(java.security.NoSuchAlgorithmException e){throw new IllegalStateException(e);}
  try{return identity.withActiveActor(actor,List.of(id),()->{
   admin(actor);users.lockUserSessions(id);var previous=db.command(actor.userId(),op);
   if(previous!=null){if(!"STATE".equals(previous.action())||!MessageDigest.isEqual(payload,previous.payloadHash()))throw new ApiFailure(409,"OPERATION_CONFLICT","操作标识已用于不同内容");return result(previous,true);}
   var targetUser=users.byId(id);if(targetUser==null)throw new ApiFailure(404,"NOT_FOUND","用户不存在");if(!"USER".equals(targetUser.role()))throw new ApiFailure(403,"FORBIDDEN","禁止处置管理员");
   if(targetUser.stateVersion()!=version)throw new ApiFailure(409,"VERSION_CONFLICT","状态已变更，请刷新并重新核对");
   Instant now=Instant.now();boolean changed=!status.equals(targetUser.status());String notification=null;
   if(changed){db.state(id,status,normalized,now);if("FROZEN".equals(status))users.revokeAll(id,now);notification=UUID.randomUUID().toString();db.notify(notification,id,"FROZEN".equals(status)?"账号已冻结":"账号已解冻",normalized,op,actor.userId(),now);}
   var result=new Result(op,id,changed?"APPLIED":"NO_CHANGE",version+(changed?1:0),notification,false);
   db.save(new StateCommandMapper.Command(actor.userId(),op,"STATE",id,payload,json.writeValueAsString(result),now));return result;
  });}catch(org.springframework.dao.DuplicateKeyException duplicate){
   return identity.withActiveActor(actor,List.of(),()->{admin(actor);var previous=db.command(actor.userId(),op);if(previous==null)throw duplicate;if(!"STATE".equals(previous.action())||!MessageDigest.isEqual(payload,previous.payloadHash()))throw new ApiFailure(409,"OPERATION_CONFLICT","操作标识已用于不同内容");return result(previous,true);});
  }
 }
 public Result send(IdentityPort.Actor actor,String target,String operation,String title,String body){
  String id=uuid(target),op=uuid(operation);if(title==null||body==null)throw AccountRules.invalid();
  String normalized=AccountRules.trimAccount(title);int length=normalized.codePointCount(0,normalized.length()),bodyLength=body.codePointCount(0,body.length());
  if(length<1||length>60||bodyLength<1||bodyLength>500)throw AccountRules.invalid();
  byte[] payload;try{payload=MessageDigest.getInstance("SHA-256").digest(json.writeValueAsString(List.of("ADMIN_MESSAGE",id,normalized,body)).getBytes(StandardCharsets.UTF_8));}catch(java.security.NoSuchAlgorithmException e){throw new IllegalStateException(e);}
  return identity.withActiveActor(actor,List.of(id),()->{
   admin(actor);var previous=db.command(actor.userId(),op);
   if(previous!=null){if(!"ADMIN_MESSAGE".equals(previous.action())||!MessageDigest.isEqual(payload,previous.payloadHash()))throw new ApiFailure(409,"OPERATION_CONFLICT","操作标识已用于不同内容");return result(previous,true);}
   var recipient=users.byId(id);if(recipient==null)throw new ApiFailure(404,"NOT_FOUND","用户不存在");if(!"USER".equals(recipient.role()))throw new ApiFailure(403,"FORBIDDEN","只能向普通账号保存通知");
   Instant now=Instant.now();String notification=UUID.randomUUID().toString();db.message(notification,id,normalized,body,op,actor.userId(),now);
   var result=new Result(op,id,"APPLIED",recipient.stateVersion(),notification,false);
   db.save(new StateCommandMapper.Command(actor.userId(),op,"ADMIN_MESSAGE",id,payload,json.writeValueAsString(result),now));return result;
  });
 }
}
