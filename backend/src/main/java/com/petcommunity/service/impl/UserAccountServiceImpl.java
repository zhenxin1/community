package com.petcommunity.service.impl;

import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Autowired;
import com.petcommunity.common.BusinessException;
import com.petcommunity.mapper.user.UserMapper;
import com.petcommunity.mapper.user.MediaMapper;
import com.petcommunity.dto.user.*;
import com.petcommunity.entity.UserEntity;
import com.petcommunity.vo.user.UserVO;
import com.petcommunity.security.LoginLimiter;
import com.petcommunity.service.UserAccountService;
import java.time.*;
import java.util.*;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserAccountServiceImpl implements UserAccountService {
    @Autowired
    private UserMapper users;

    @Autowired
    private MediaMapper media;

    @Autowired
    private PasswordEncoder passwords;
    @Autowired
    private LoginLimiter limiter;

    @Autowired
    private Clock clock;

    private String dummyHash;

    @PostConstruct
    private void initialize() {
        dummyHash = passwords.encode(UUID.randomUUID().toString());
    }

 @Override @Transactional public UserEntity register(RegisterRequest request){
  UserEntity user=new UserEntity(); user.setUsername(request.getUsername().toLowerCase(Locale.ROOT));
  user.setPasswordHash(passwords.encode(request.getPassword())); user.setNickname(request.getNickname().strip());
  try{ users.insert(user); }catch(DuplicateKeyException e){ throw new BusinessException(409,"USERNAME_EXISTS","这个账号已被注册，换一个试试"); }
  return users.findById(user.getId());
 }
 @Override public UserEntity authenticate(LoginRequest request,String ip){
  String name=request.getUsername().toLowerCase(Locale.ROOT); limiter.check(name,ip);
  UserEntity user=name.matches("[a-z0-9_]{3,24}") ? users.findByUsername(name) : null;
  boolean valid;
  try{ valid=passwords.matches(request.getPassword(),user==null ? dummyHash : user.getPasswordHash()); }
  catch(IllegalArgumentException e){ valid=false; }
  if(user==null || !valid){ limiter.failed(name,ip); throw new BusinessException(401,"INVALID_CREDENTIALS","账号或密码不正确"); }
  if(!"ACTIVE".equals(user.getStatus())) throw new BusinessException(403,"ACCOUNT_FROZEN","账号已被冻结，请联系管理员");
  limiter.succeeded(name); return user;
 }
 @Override public UserVO view(UserEntity u){
  return new UserVO(u.getId().toString(),u.getUsername(),u.getNickname(),u.getAvatarMediaId()==null ? "" : u.getAvatarMediaId().toString(),
   u.getPhone(),u.getLocation(),u.getStatus(),u.getRole(),
   u.isMustChangePassword(),u.getVersion(),u.getCreatedAt().atOffset(ZoneOffset.UTC).withOffsetSameInstant(ZoneOffset.ofHours(8)));
 }
 @Override @Transactional public UserVO updateProfile(UserEntity actor,ProfileRequest request){
  UserEntity user=users.lockById(actor.getId());
  if(user==null || !"ACTIVE".equals(user.getStatus()) || user.getAuthVersion()!=actor.getAuthVersion()) throw new BusinessException(401,"UNAUTHENTICATED","登录状态已失效，请重新登录");
  if(user.getVersion()!=request.getVersion()) throw new BusinessException(409,"VERSION_CONFLICT","资料已在其他页面更新，请重新载入后再保存");
  Long avatar;
  try{ avatar=request.getAvatarId().isEmpty() ? null : Long.valueOf(request.getAvatarId()); }
  catch(NumberFormatException e){ throw new BusinessException(400,"VALIDATION_ERROR","头像编号不正确"); }
  if(avatar!=null){
   var file=media.lockById(avatar);
   boolean own=file!=null && file.getOwnerId().equals(user.getId()) && "AVATAR".equals(file.getBusinessType());
   boolean temporary=own && "TEMP".equals(file.getStatus()) && file.getCleanupAfter()!=null && file.getCleanupAfter().isAfter(LocalDateTime.now(clock));
   boolean bound=own && "BOUND".equals(file.getStatus()) && user.getId().equals(file.getBusinessId()) && avatar.equals(user.getAvatarMediaId());
   if(!temporary && !bound) throw new BusinessException(404,"RESOURCE_NOT_FOUND","头像不存在或不可使用");
  }
  String nickname=request.getNickname().strip(),phone=request.getPhone().strip(),location=request.getLocation().strip();
  if(Objects.equals(avatar,user.getAvatarMediaId()) && nickname.equals(user.getNickname()) && phone.equals(user.getPhone()) && location.equals(user.getLocation())) return view(user);
  if(!Objects.equals(avatar,user.getAvatarMediaId())){
   if(user.getAvatarMediaId()!=null) media.markDeleted(user.getAvatarMediaId(),LocalDateTime.now(clock).plusHours(24));
   if(avatar!=null) media.bindAvatar(avatar,user.getId());
  }
  user.setNickname(nickname); user.setPhone(phone); user.setLocation(location); user.setAvatarMediaId(avatar);
  if(users.updateProfile(user)!=1) throw new BusinessException(409,"VERSION_CONFLICT","资料已更新，请重新载入");
  return view(users.findById(user.getId()));
 }
}
