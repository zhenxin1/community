package com.example.petadoptioncommunity.notification;
import org.apache.ibatis.annotations.*;
import java.time.Instant;
import java.util.List;
@Mapper public interface NotificationMapper {
 record Row(String id,String recipientId,String title,String body,String type,String operationId,Instant createdAt,Instant readAt){}
 String OWNED="SELECT id,recipient_id,title,body,type,operation_id,created_at,read_at FROM e4_notification WHERE recipient_id=#{userId}";
 @Select(OWNED+" AND (#{unread}=false OR read_at IS NULL) ORDER BY created_at DESC,id DESC LIMIT #{size} OFFSET #{offset}")
 List<Row> list(@Param("userId") String userId,@Param("unread") boolean unread,@Param("size") int size,@Param("offset") long offset);
 @Select("SELECT COUNT(*) FROM e4_notification WHERE recipient_id=#{userId} AND (#{unread}=false OR read_at IS NULL)") long count(@Param("userId") String userId,@Param("unread") boolean unread);
 @Select(OWNED+" AND id=#{id}") Row owned(@Param("userId") String userId,@Param("id") String id);
 @Select("SELECT COUNT(*) FROM e4_notification WHERE id=#{id}") long exists(String id);
 @Update("UPDATE e4_notification SET read_at=COALESCE(read_at,UTC_TIMESTAMP(3)) WHERE recipient_id=#{userId} AND id=#{id}") void mark(@Param("userId") String userId,@Param("id") String id);
}
