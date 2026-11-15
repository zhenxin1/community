package com.example.petadoptioncommunity.administration;
import org.apache.ibatis.annotations.*;
import java.time.Instant;
@Mapper public interface StateCommandMapper {
 record Command(String actorId,String operationId,String action,String targetId,byte[] payloadHash,String resultJson,Instant createdAt){}
 @Select("SELECT actor_id,operation_id,action,target_id,payload_hash,result_json,created_at FROM e4_command WHERE actor_id=#{actor} AND operation_id=#{operation} FOR UPDATE") Command command(@Param("actor") String actor,@Param("operation") String operation);
 @Insert("INSERT INTO e4_command VALUES(#{actorId},#{operationId},#{action},#{targetId},#{payloadHash},#{resultJson},#{createdAt})") void save(Command command);
 @Update("UPDATE e4_user SET status=#{status},state_version=state_version+1,auth_version=auth_version+IF(#{status}='FROZEN',1,0),latest_reason=#{reason},latest_action_at=#{at} WHERE id=#{id}") void state(@Param("id") String id,@Param("status") String status,@Param("reason") String reason,@Param("at") Instant at);
 @Insert("INSERT INTO e4_notification(id,recipient_id,title,body,type,operation_id,actor_id,created_at) VALUES(#{id},#{target},#{title},#{reason},'STATUS_CHANGE',#{operation},#{actor},#{at})") void notify(@Param("id") String id,@Param("target") String target,@Param("title") String title,@Param("reason") String reason,@Param("operation") String operation,@Param("actor") String actor,@Param("at") Instant at);
 @Insert("INSERT INTO e4_notification(id,recipient_id,title,body,type,operation_id,actor_id,created_at) VALUES(#{id},#{target},#{title},#{body},'ADMIN_MESSAGE',#{operation},#{actor},#{at})") void message(@Param("id") String id,@Param("target") String target,@Param("title") String title,@Param("body") String body,@Param("operation") String operation,@Param("actor") String actor,@Param("at") Instant at);
}
