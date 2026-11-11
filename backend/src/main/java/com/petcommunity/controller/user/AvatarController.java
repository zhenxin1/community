package com.petcommunity.controller.user;
import org.springframework.beans.factory.annotation.Autowired;
import com.petcommunity.common.Result;
import com.petcommunity.vo.user.MediaVO;
import com.petcommunity.vo.user.ActionVO;
import com.petcommunity.security.SessionManager;
import com.petcommunity.service.MediaService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
@RestController
public class AvatarController {
    @Autowired
    private MediaService media;

    @Autowired
    private SessionManager sessions;

 @PostMapping(value="/api/v1/user/media",consumes="multipart/form-data")
 public Result<MediaVO> upload(@RequestParam("businessType") String businessType,@RequestPart("file") MultipartFile file,HttpServletRequest request){
  return Result.ok(media.uploadAvatar(sessions.require(request).getId(),businessType,file),(String)request.getAttribute("requestId"));
 }
 @DeleteMapping("/api/v1/user/media/{mediaId}") public Result<ActionVO> delete(@PathVariable long mediaId,HttpServletRequest request){
  media.deleteTemporary(sessions.require(request).getId(),mediaId);return Result.ok(new ActionVO(true),(String)request.getAttribute("requestId"));
 }
 @GetMapping("/api/v1/media/{mediaId}/content") public ResponseEntity<ByteArrayResource> content(@PathVariable long mediaId,@RequestHeader(value="Range",required=false) String range,HttpServletRequest request){
  var user=sessions.current(request);return media.content(user==null ? null : user.getId(),mediaId,range);
 }
}
