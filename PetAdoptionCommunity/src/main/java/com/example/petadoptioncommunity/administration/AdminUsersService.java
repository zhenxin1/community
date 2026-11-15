package com.example.petadoptioncommunity.administration;
import com.example.petadoptioncommunity.identity.*;
import com.example.petadoptioncommunity.web.ApiFailure;
import org.springframework.stereotype.Service;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeFormatterBuilder;
import java.util.*;
@Service
public class AdminUsersService {
 private final IdentityService identity;private final AdminUsersMapper db;
 private static final DateTimeFormatter TIME=new DateTimeFormatterBuilder().appendInstant(3).toFormatter();
 public AdminUsersService(IdentityService identity,AdminUsersMapper db){this.identity=identity;this.db=db;}
 public record User(String id,String account,String nickname,String role,String status,String createdAt){}
 public record Detail(String id,String account,String nickname,String role,String status,String createdAt,String bio,String latestReason,String latestActionAt,long stateVersion){}
 public record Page(List<User> items,int page,int size,long total){}
 public static int number(String value,int fallback){if(value==null)return fallback;if(!value.matches("[0-9]+"))throw AccountRules.invalid();try{int n=Integer.parseInt(value);if(n<1)throw AccountRules.invalid();return n;}catch(NumberFormatException e){throw AccountRules.invalid();}}
 public static String contains(String value){String v=value==null?"":AccountRules.trimAccount(value).toLowerCase(Locale.ROOT);if(v.codePointCount(0,v.length())>16)throw AccountRules.invalid();return v;}
 private void admin(IdentityPort.Actor actor){if(!"ADMIN".equals(actor.role()))throw new ApiFailure(403,"FORBIDDEN","无权限");}
 public Page list(IdentityPort.Actor actor,String pageValue,String sizeValue,String query,String status){
  int page=number(pageValue,1),size=number(sizeValue,20);String contains=contains(query);
  if(!Set.of(10,20,50).contains(size)||(status!=null&&!Set.of("ACTIVE","FROZEN").contains(status)))throw AccountRules.invalid();
  return identity.withActiveActor(actor,List.of(),()->{admin(actor);var projection=db.list(contains,status,size,((long)page-1)*size);long total=projection.get(0).total();var rows=projection.stream().filter(r->r.id()!=null).map(r->new User(r.id(),r.account(),r.nickname(),r.role(),r.status(),TIME.format(r.createdAt()))).toList();return new Page(rows,page,size,total);});
 }
 public Detail detail(IdentityPort.Actor actor,String id){
  if(id==null||!id.matches("[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"))throw AccountRules.invalid();
  return identity.withActiveActor(actor,List.of(),()->{admin(actor);var r=db.detail(id.toLowerCase(Locale.ROOT));if(r==null)throw new ApiFailure(404,"NOT_FOUND","用户不存在");return new Detail(r.id(),r.account(),r.nickname(),r.role(),r.status(),TIME.format(r.createdAt()),r.bio(),r.latestReason(),r.latestActionAt()==null?null:TIME.format(r.latestActionAt()),r.stateVersion());});
 }
}
