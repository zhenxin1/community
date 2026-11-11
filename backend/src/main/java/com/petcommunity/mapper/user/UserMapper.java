package com.petcommunity.mapper.user;
import org.apache.ibatis.annotations.Mapper;
import com.petcommunity.entity.UserEntity;
import org.apache.ibatis.annotations.Param;
@Mapper
public interface UserMapper {
 UserEntity findById(@Param("id") long id);
 UserEntity lockById(@Param("id") long id);
 UserEntity findByUsername(@Param("username") String username);
 int insert(UserEntity user);
 int updateProfile(UserEntity user);
}
