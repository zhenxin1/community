package com.example.petadoptioncommunity.administration;
import org.apache.ibatis.annotations.*;
import java.time.Instant;
import java.util.List;
@Mapper
public interface AdminUsersMapper {
 record Row(long total,String id,String account,String nickname,String role,String status,Instant createdAt){}
 record Detail(String id,String account,String nickname,String role,String status,Instant createdAt,String bio,String latestReason,Instant latestActionAt,long stateVersion){}
 String FILTER=" WHERE LOCATE(#{contains},account)>0 AND (#{status} IS NULL OR status=#{status})";
 // Both derived tables use the same statement read view under READ COMMITTED.
 // The aggregate always yields one row, preserving total even for an empty/out-of-range page.
 @Select("SELECT totals.total,p.id,p.account,p.nickname,p.role,p.status,p.created_at FROM "
  +"(SELECT COUNT(*) AS total FROM e4_user"+FILTER+") totals LEFT JOIN "
  +"(SELECT id,account,nickname,role,status,created_at FROM e4_user"+FILTER
  +" ORDER BY created_at DESC,id DESC LIMIT #{size} OFFSET #{offset}) p ON 1=1 ORDER BY p.created_at DESC,p.id DESC")
 List<Row> list(@Param("contains") String contains,@Param("status") String status,@Param("size") int size,@Param("offset") long offset);
 @Select("SELECT id,account,nickname,role,status,created_at,bio,latest_reason,latest_action_at,state_version FROM e4_user WHERE id=#{id}") Detail detail(String id);
}
