package com.example.petadoptioncommunity.notification;
import com.example.petadoptioncommunity.identity.IdentityPort;
import com.example.petadoptioncommunity.web.ApiFailure;
import org.springframework.stereotype.Service;
import java.util.*;
import java.time.format.DateTimeFormatterBuilder;
@Service public class NotificationService {
 private final NotificationMapper db;private final IdentityPort identity;
 private static final java.time.format.DateTimeFormatter TIME=new DateTimeFormatterBuilder().appendInstant(3).toFormatter();
 public NotificationService(NotificationMapper db,IdentityPort identity){this.db=db;this.identity=identity;}
 public record Notification(String id,String title,String body,String type,String operationId,String createdAt,String readAt){}
 public record Page(List<Notification> items,int page,int size,long total){}
 private Notification dto(NotificationMapper.Row r){return new Notification(r.id(),r.title(),r.body(),r.type(),r.operationId(),TIME.format(r.createdAt()),r.readAt()==null?null:TIME.format(r.readAt()));}
 private Notification owned(IdentityPort.Actor actor,String id){var row=db.owned(actor.userId(),id);if(row==null){boolean exists=db.exists(id)>0;throw new ApiFailure(exists?403:404,exists?"FORBIDDEN":"NOT_FOUND","无法访问通知");}return dto(row);}
 public Page list(IdentityPort.Actor actor,int page,int size,String filter){if(page<1||!Set.of(10,20,50).contains(size)||!Set.of("ALL","UNREAD").contains(filter))throw new ApiFailure(400,"VALIDATION_ERROR","分页筛选参数无效");return identity.withActiveActor(actor,List.of(),()->new Page(db.list(actor.userId(),filter.equals("UNREAD"),size,((long)page-1)*size).stream().map(this::dto).toList(),page,size,db.count(actor.userId(),filter.equals("UNREAD"))));}
 private String validId(String id){if(id==null||!id.matches("[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"))throw com.example.petadoptioncommunity.identity.AccountRules.invalid();return id.toLowerCase(Locale.ROOT);}
 public Notification detail(IdentityPort.Actor actor,String id){String target=validId(id);return identity.withActiveActor(actor,List.of(),()->owned(actor,target));}
 public Notification read(IdentityPort.Actor actor,String id){String target=validId(id);return identity.withActiveActor(actor,List.of(),()->{owned(actor,target);db.mark(actor.userId(),target);return owned(actor,target);});}
}
