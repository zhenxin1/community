package com.petcommunity.service;
import com.petcommunity.vo.user.MediaVO;
import org.springframework.http.ResponseEntity;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.web.multipart.MultipartFile;
public interface MediaService {
 MediaVO uploadAvatar(long userId,String businessType,MultipartFile file);
 void deleteTemporary(long userId,long mediaId);
 ResponseEntity<ByteArrayResource> content(Long userId,long mediaId,String range);
 void cleanup();
}
