package com.petcommunity.controller.user;
import org.springframework.beans.factory.annotation.Autowired;
import com.petcommunity.common.Result;
import com.petcommunity.vo.user.SessionVO;
import com.petcommunity.security.SessionManager;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.*;
@RestController
public class CommonController {
    @Autowired
    private SessionManager sessions;

 @GetMapping("/api/v1/common/session") public Result<SessionVO> session(HttpServletRequest request){
  return Result.ok(new SessionVO(sessions.current(request)!=null,sessions.csrf(request.getSession(true))),(String)request.getAttribute("requestId"));
 }
}
