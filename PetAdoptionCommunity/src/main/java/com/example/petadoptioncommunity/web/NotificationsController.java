package com.example.petadoptioncommunity.web;
import com.example.petadoptioncommunity.identity.IdentityPort;
import com.example.petadoptioncommunity.notification.NotificationService;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import jakarta.servlet.http.HttpServletRequest;
import java.util.Set;
@RestController @RequestMapping("/api/v1/me/notifications")
public class NotificationsController {
 private final NotificationService notifications;
 public NotificationsController(NotificationService notifications){this.notifications=notifications;}
 private void query(HttpServletRequest request,Set<String> allowed){if(request.getParameterMap().entrySet().stream().anyMatch(e->!allowed.contains(e.getKey())||e.getValue().length!=1))throw new ApiFailure(400,"VALIDATION_ERROR","请求参数无效");}
 @GetMapping public Object list(@AuthenticationPrincipal IdentityPort.Actor actor,HttpServletRequest request){
  query(request,Set.of("page","size","filter"));
  try{return notifications.list(actor,Integer.parseInt(request.getParameter("page")==null?"1":request.getParameter("page")),Integer.parseInt(request.getParameter("size")==null?"20":request.getParameter("size")),request.getParameter("filter")==null?"ALL":request.getParameter("filter"));}catch(NumberFormatException e){throw new ApiFailure(400,"VALIDATION_ERROR","分页参数无效");}
 }
 @GetMapping("/{id}") public Object detail(@AuthenticationPrincipal IdentityPort.Actor actor,@PathVariable String id,HttpServletRequest request){query(request,Set.of());return notifications.detail(actor,id);}
 @PutMapping("/{id}/read") public Object read(@AuthenticationPrincipal IdentityPort.Actor actor,@PathVariable String id,HttpServletRequest request)throws java.io.IOException{query(request,Set.of());if(request.getInputStream().read()!=-1)throw new ApiFailure(400,"VALIDATION_ERROR","此请求不接受body");return notifications.read(actor,id);}
}
