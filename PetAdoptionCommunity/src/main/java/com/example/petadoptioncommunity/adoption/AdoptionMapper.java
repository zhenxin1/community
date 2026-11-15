package com.example.petadoptioncommunity.adoption;
import org.apache.ibatis.annotations.*; import java.util.*;
@Mapper public interface AdoptionMapper {
 @Select("SELECT p.*,u.nickname publisher_name FROM pet p JOIN e4_user u ON p.publisher_id=u.id WHERE p.status='AVAILABLE' ORDER BY p.created_at DESC,p.id DESC") List<Map<String,Object>> list();
 @Select("SELECT p.*,u.nickname publisher_name FROM pet p JOIN e4_user u ON p.publisher_id=u.id WHERE p.id=#{id}") Map<String,Object> pet(String id);
 @Select("SELECT * FROM pet WHERE id=#{id} FOR UPDATE") Map<String,Object> lockPet(String id);
 @Insert("INSERT INTO pet(id,publisher_id,name,category,province,region,breed,description,image,phone,wechat,email) VALUES(#{id},#{publisherId},#{name},#{category},#{province},#{region},#{breed},#{description},#{image},#{phone},#{wechat},#{email})") void insert(Map<String,Object> p);
 @Select("SELECT * FROM adoption_application WHERE pet_id=#{petId} AND applicant_id=#{userId} AND status IN ('PENDING','SELECTED') LIMIT 1") Map<String,Object> active(@Param("petId")String petId,@Param("userId")String userId);
 @Insert("INSERT INTO adoption_application(id,pet_id,applicant_id) VALUES(#{id},#{petId},#{userId})") void apply(@Param("id")String id,@Param("petId")String petId,@Param("userId")String userId);
 @Select("SELECT * FROM adoption_application WHERE id=#{id}") Map<String,Object> application(String id);
 @Select("SELECT a.*,p.name pet_name,p.image,p.publisher_id,u.nickname applicant_name FROM adoption_application a JOIN pet p ON a.pet_id=p.id JOIN e4_user u ON a.applicant_id=u.id WHERE a.applicant_id=#{userId} OR p.publisher_id=#{userId} ORDER BY a.created_at DESC,a.id DESC") List<Map<String,Object>> applications(String userId);
 @Select("SELECT p.*,u.nickname publisher_name FROM pet p JOIN e4_user u ON p.publisher_id=u.id WHERE publisher_id=#{id} ORDER BY created_at DESC") List<Map<String,Object>> mine(String id);
 @Select("SELECT COUNT(*) FROM adoption_application WHERE pet_id=#{petId} AND applicant_id=#{userId} AND status='SELECTED'") int selected(@Param("petId")String petId,@Param("userId")String userId);
 @Update("UPDATE adoption_application SET status=#{status},publisher_confirmed=#{pub},applicant_confirmed=#{app} WHERE id=#{id}") void applicationState(@Param("id")String id,@Param("status")String status,@Param("pub")boolean pub,@Param("app")boolean app);
 @Update("UPDATE pet SET status=#{status} WHERE id=#{id}") void petState(@Param("id")String id,@Param("status")String status);
 @Update("UPDATE adoption_application SET status='NOT_SELECTED' WHERE pet_id=#{id} AND status='PENDING'") void closeOthers(String id);
 @Insert("INSERT INTO adoption_result(pet_id,application_id) VALUES(#{petId},#{applicationId})") void result(@Param("petId")String petId,@Param("applicationId")String applicationId);
}
