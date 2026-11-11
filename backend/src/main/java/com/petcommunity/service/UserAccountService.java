package com.petcommunity.service;
import com.petcommunity.dto.user.*;
import com.petcommunity.entity.UserEntity;
import com.petcommunity.vo.user.UserVO;
public interface UserAccountService {
 UserEntity register(RegisterRequest request);
 UserEntity authenticate(LoginRequest request,String ip);
 UserVO view(UserEntity user);
 UserVO updateProfile(UserEntity actor,ProfileRequest request);
}
