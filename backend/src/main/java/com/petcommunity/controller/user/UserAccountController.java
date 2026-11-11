package com.petcommunity.controller.user;

import org.springframework.beans.factory.annotation.Autowired;
import com.petcommunity.common.Result;
import com.petcommunity.dto.user.*;
import com.petcommunity.vo.user.*;
import com.petcommunity.security.SessionManager;
import com.petcommunity.service.UserAccountService;
import jakarta.servlet.http.*;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

@RestController @RequestMapping("/api/v1/user")
public class UserAccountController {
    @Autowired
    private UserAccountService users;

    @Autowired
    private SessionManager sessions;

 private <T> Result<T> ok(T value,HttpServletRequest request){ return Result.ok(value,(String)request.getAttribute("requestId")); }
 @PostMapping("/auth/register") public Result<AuthVO> register(@Valid @RequestBody RegisterRequest body,HttpServletRequest request){
  var user=users.register(body);String token=sessions.signIn(request,user);
  return ok(new AuthVO(users.view(user),token,SessionManager.IDLE_SECONDS),request);
 }
 @PostMapping("/auth/login") public Result<AuthVO> login(@Valid @RequestBody LoginRequest body,HttpServletRequest request){
  var user=users.authenticate(body,request.getRemoteAddr());String token=sessions.signIn(request,user);
  return ok(new AuthVO(users.view(user),token,SessionManager.IDLE_SECONDS),request);
 }
 @GetMapping("/auth/me") public Result<UserVO> me(HttpServletRequest request){ return ok(users.view(sessions.require(request)),request); }
 @PostMapping("/auth/logout") public Result<ActionVO> logout(HttpServletRequest request,HttpServletResponse response){
  sessions.signOut(request);
  response.addHeader("Set-Cookie",org.springframework.http.ResponseCookie.from("JSESSIONID","").path("/api").maxAge(0).httpOnly(true).sameSite("Lax").secure(request.isSecure()).build().toString());
  return ok(new ActionVO(true),request);
 }
 @GetMapping("/profile") public Result<UserVO> profile(HttpServletRequest request){ return ok(users.view(sessions.require(request)),request); }
 @PutMapping("/profile") public Result<UserVO> profile(@Valid @RequestBody ProfileRequest body,HttpServletRequest request){ return ok(users.updateProfile(sessions.require(request),body),request); }
}
