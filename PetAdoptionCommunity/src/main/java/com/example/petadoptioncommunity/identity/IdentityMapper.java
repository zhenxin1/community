package com.example.petadoptioncommunity.identity;
import org.apache.ibatis.annotations.*;
import java.time.Instant;
@Mapper
public interface IdentityMapper {
 record Account(String id,String account,String passwordHash,String role,String status,String nickname,long authVersion,long stateVersion,Instant createdAt,String latestReason,Instant latestActionAt){}
 record Profile(String id,String account,String nickname,String role,String status,Instant createdAt,String bio,long profileVersion){}
 @Select("SELECT id,account,nickname,role,status,created_at,bio,profile_version FROM e4_user WHERE id=#{id}") Profile profile(String id);
 @Update("UPDATE e4_user SET nickname=#{nickname},bio=#{bio},profile_version=profile_version+1 WHERE id=#{id} AND profile_version=#{version}") int updateProfile(@Param("id") String id,@Param("nickname") String nickname,@Param("bio") String bio,@Param("version") long version);
 @Update("UPDATE e4_user SET password_hash=#{hash},auth_version=auth_version+1 WHERE id=#{id}") void rotatePassword(@Param("id") String id,@Param("hash") String hash);
 @Update("UPDATE e4_session SET revoked_at=#{at} WHERE user_id=#{id} AND revoked_at IS NULL") void revokeAll(@Param("id") String id,@Param("at") Instant at);
 @Select("SELECT * FROM e4_session WHERE user_id=#{id} ORDER BY token_hash FOR UPDATE") java.util.List<Session> lockUserSessions(String id);
 record Session(byte[] tokenHash,String userId,long authVersion,long stateVersion,Instant expiresAt,Instant revokedAt){}
 @Select("SELECT id,account,password_hash,role,status,nickname,auth_version,state_version,created_at,latest_reason,latest_action_at FROM e4_user WHERE account=#{account}") Account byAccount(String account);
 @Select("SELECT id,account,password_hash,role,status,nickname,auth_version,state_version,created_at,latest_reason,latest_action_at FROM e4_user WHERE id=#{id}") Account byId(String id);
 @Select("SELECT id,account,password_hash,role,status,nickname,auth_version,state_version,created_at,latest_reason,latest_action_at FROM e4_user WHERE id=#{id} FOR UPDATE") Account lockAccount(String id);
 @Select("SELECT * FROM e4_session WHERE token_hash=#{hash}") Session session(byte[] hash);
 @Select("SELECT * FROM e4_session WHERE token_hash=#{hash} FOR UPDATE") Session lockSession(byte[] hash);
 @Insert("INSERT INTO e4_user(id,account,password_hash,role,status,nickname,created_at) VALUES(#{id},#{account},#{passwordHash},#{role},'ACTIVE',#{nickname},#{createdAt})") void insertAccount(Account account);
 @Insert("INSERT INTO e4_session(token_hash,user_id,auth_version,state_version,expires_at) VALUES(#{tokenHash},#{userId},#{authVersion},#{stateVersion},#{expiresAt})") void insertSession(Session session);
 @Update("UPDATE e4_session SET revoked_at=#{at} WHERE token_hash=#{hash} AND revoked_at IS NULL") void revoke(@Param("hash") byte[] hash,@Param("at") Instant at);
}
