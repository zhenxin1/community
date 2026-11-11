package com.petcommunity.security;

import org.springframework.beans.factory.annotation.Autowired;
import com.petcommunity.common.BusinessException;
import com.petcommunity.mapper.user.UserMapper;
import com.petcommunity.entity.UserEntity;
import jakarta.servlet.http.*;
import java.io.Serializable;
import java.nio.charset.StandardCharsets;
import java.security.*;
import java.util.Base64;
import org.springframework.stereotype.Component;

@Component
public class SessionManager {
    public static final int IDLE_SECONDS=28800;
    private static final String IDENTITY="pet.identity", CSRF="pet.csrf", CURRENT="pet.currentUser";
    @Autowired
    private SecureRandom random;
    @Autowired
    private UserMapper users;

    private record Identity(long userId,int authVersion) implements Serializable {}

    public UserEntity inspect(HttpServletRequest request){
        HttpSession session=request.getSession(false);
        if(session==null || !(session.getAttribute(IDENTITY) instanceof Identity identity)) return null;
        UserEntity user=users.findById(identity.userId());
        if(user==null || !"ACTIVE".equals(user.getStatus()) || user.getAuthVersion()!=identity.authVersion()){
            session.invalidate(); return null;
        }
        request.setAttribute(CURRENT,user); return user;
    }
    public UserEntity current(HttpServletRequest request){ return (UserEntity)request.getAttribute(CURRENT); }
    public UserEntity require(HttpServletRequest request){
        UserEntity user=current(request);
        if(user==null) throw new BusinessException(401,"UNAUTHENTICATED","请先登录后再继续");
        return user;
    }
    public String csrf(HttpSession session){
        synchronized(session){
            Object existing=session.getAttribute(CSRF);
            if(existing instanceof String token) return token;
            String token=newToken(); session.setAttribute(CSRF,token); return token;
        }
    }
    public void checkCsrf(HttpServletRequest request){
        HttpSession session=request.getSession(false);
        String supplied=request.getHeader("X-CSRF-Token");
        Object expected=session==null ? null : session.getAttribute(CSRF);
        if(!(expected instanceof String token) || supplied==null || supplied.length()>128 ||
           !MessageDigest.isEqual(token.getBytes(StandardCharsets.US_ASCII),supplied.getBytes(StandardCharsets.US_ASCII)))
            throw new BusinessException(403,"CSRF_INVALID","页面登录状态已更新，请刷新后重试");
    }
    public String signIn(HttpServletRequest request,UserEntity user){
        HttpSession session=request.getSession(true);
        request.changeSessionId();
        session.setMaxInactiveInterval(IDLE_SECONDS);
        session.setAttribute(IDENTITY,new Identity(user.getId(),user.getAuthVersion()));
        String token=newToken(); session.setAttribute(CSRF,token); request.setAttribute(CURRENT,user);
        return token;
    }
    public void signOut(HttpServletRequest request){
        HttpSession session=request.getSession(false);
        if(session!=null) session.invalidate();
        request.removeAttribute(CURRENT);
    }
    private String newToken(){
        byte[] bytes=new byte[32]; random.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }
}
