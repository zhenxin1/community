package com.petcommunity.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import com.petcommunity.common.BusinessException;
import com.petcommunity.mapper.user.MediaMapper;
import com.petcommunity.mapper.user.UserMapper;
import com.petcommunity.entity.MediaEntity;
import com.petcommunity.vo.user.MediaVO;
import com.petcommunity.service.*;
import com.petcommunity.utils.AvatarStorage;
import java.io.IOException;
import java.time.*;
import java.util.*;
import java.util.regex.*;
import org.slf4j.*;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.*;
import org.springframework.web.multipart.MultipartFile;

@Service
public class MediaServiceImpl implements MediaService {
 private static final Logger LOG=LoggerFactory.getLogger(MediaServiceImpl.class);
    @Autowired
    private MediaMapper media;

    @Autowired
    private UserMapper users;

    @Autowired
    private AvatarStorage storage;

    @Autowired
    private Clock clock;

 @Override @Transactional public MediaVO uploadAvatar(long userId,String businessType,MultipartFile file){
  if(!"AVATAR".equals(businessType)) throw new BusinessException(400,"VALIDATION_ERROR","当前上传接口仅支持个人头像");
  var stored=storage.save(file);
  TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization(){
   @Override public void afterCompletion(int status){
    if(status!=STATUS_COMMITTED) try{ storage.delete(stored.key()); }catch(IOException e){ LOG.warn("Could not remove rolled-back avatar"); }
   }
  });
  var entity=new MediaEntity(); entity.setOwnerId(userId);entity.setStorageKey(stored.key());entity.setOriginalName(stored.originalName());
  entity.setMimeType(stored.mime());entity.setSizeBytes(stored.size());entity.setCleanupAfter(LocalDateTime.now(clock).plusHours(24));
  media.insert(entity); entity=media.findById(entity.getId());
  return new MediaVO(entity.getId().toString(),"AVATAR",entity.getMimeType(),entity.getSizeBytes(),"/api/v1/media/"+entity.getId()+"/content",entity.getCreatedAt().atOffset(ZoneOffset.UTC).withOffsetSameInstant(ZoneOffset.ofHours(8)));
 }
 @Override @Transactional public void deleteTemporary(long userId,long mediaId){
  var file=media.lockById(mediaId);
  if(file==null || !file.getOwnerId().equals(userId) || !"AVATAR".equals(file.getBusinessType()) || "DELETED".equals(file.getStatus())) throw missing();
  if("BOUND".equals(file.getStatus())) throw new BusinessException(409,"MEDIA_IN_USE","头像正在使用，请先在个人资料中更换或移除");
  media.markDeleted(mediaId,LocalDateTime.now(clock).plusHours(24));
 }
 @Override public ResponseEntity<ByteArrayResource> content(Long userId,long mediaId,String range){
  var file=media.findById(mediaId);
  if(file==null || !"AVATAR".equals(file.getBusinessType()) || "DELETED".equals(file.getStatus())) throw missing();
  boolean allowed="TEMP".equals(file.getStatus()) && Objects.equals(file.getOwnerId(),userId) && file.getCleanupAfter()!=null && file.getCleanupAfter().isAfter(LocalDateTime.now(clock));
  if("BOUND".equals(file.getStatus()) && file.getBusinessId()!=null){
   var owner=users.findById(file.getBusinessId());
   allowed=owner!=null && Objects.equals(owner.getAvatarMediaId(),file.getId());
  }
  if(!allowed) throw missing();
  byte[] body=storage.read(file.getStorageKey());
  HttpHeaders headers=new HttpHeaders();headers.setContentType(MediaType.parseMediaType(file.getMimeType()));
  headers.set("Cache-Control","private, no-store");headers.set("Accept-Ranges","bytes");
  headers.set("X-Content-Type-Options","nosniff");
  int status=200;
  if(range!=null){
   long[] bounds=parseRange(range,body.length); status=206;
   headers.set("Content-Range","bytes "+bounds[0]+"-"+bounds[1]+"/"+body.length);
   body=Arrays.copyOfRange(body,(int)bounds[0],(int)bounds[1]+1);
  }
  headers.setContentLength(body.length);
  return new ResponseEntity<>(new ByteArrayResource(body),headers,HttpStatusCode.valueOf(status));
 }
 public static long[] parseRange(String range,long length){
  Matcher matcher=Pattern.compile("^bytes=(\\d*)-(\\d*)$").matcher(range);
  try{
   if(!matcher.matches() || length<=0 || matcher.group(1).isEmpty() && matcher.group(2).isEmpty()) throw new IllegalArgumentException();
   long start,end;
   if(matcher.group(1).isEmpty()){
    long suffix=Long.parseLong(matcher.group(2)); if(suffix<=0) throw new IllegalArgumentException();
    start=Math.max(0,length-suffix);end=length-1;
   }else{
    start=Long.parseLong(matcher.group(1));end=matcher.group(2).isEmpty() ? length-1 : Math.min(length-1,Long.parseLong(matcher.group(2)));
   }
   if(start>=length || end<start) throw new IllegalArgumentException();
   return new long[]{start,end};
  }catch(IllegalArgumentException e){ throw new BusinessException(416,"RANGE_NOT_SATISFIABLE","图片字节范围不正确",Map.of("Content-Range","bytes */"+length)); }
 }
 @Override @Transactional public void cleanup(){
  var now=LocalDateTime.now(clock);
  for(Long id:media.expired(now)){
   var file=media.lockById(id);
   if(file==null || !Set.of("TEMP","DELETED").contains(file.getStatus()) || file.getCleanupAfter()==null || file.getCleanupAfter().isAfter(now)) continue;
   try{ storage.delete(file.getStorageKey()); media.delete(id); }
   catch(IOException e){ LOG.warn("Avatar cleanup failed for mediaId={}",id); }
  }
 }
 private static BusinessException missing(){ return new BusinessException(404,"RESOURCE_NOT_FOUND","图片不存在或不可访问"); }
}
