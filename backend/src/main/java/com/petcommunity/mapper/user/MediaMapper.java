package com.petcommunity.mapper.user;
import org.apache.ibatis.annotations.Mapper;
import com.petcommunity.entity.MediaEntity;
import org.apache.ibatis.annotations.Param;
import java.time.LocalDateTime;
import java.util.List;
@Mapper
public interface MediaMapper {
 MediaEntity findById(@Param("id") long id);
 MediaEntity lockById(@Param("id") long id);
 int insert(MediaEntity media);
 int bindAvatar(@Param("id") long id,@Param("userId") long userId);
 int markDeleted(@Param("id") long id,@Param("cleanupAfter") LocalDateTime cleanupAfter);
 List<Long> expired(@Param("now") LocalDateTime now);
 int delete(@Param("id") long id);
}
