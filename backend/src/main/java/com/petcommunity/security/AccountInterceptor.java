package com.petcommunity.security;

import org.springframework.beans.factory.annotation.Autowired;
import com.petcommunity.common.BusinessException;
import jakarta.servlet.http.*;
import java.util.Set;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

@Component
public class AccountInterceptor implements HandlerInterceptor {
    @Autowired
    private SessionManager sessions;
    private static final Set<String> PUBLIC=Set.of("/api/v1/common/session","/api/v1/user/auth/login","/api/v1/user/auth/register","/api/v1/user/auth/logout");

    @Override public boolean preHandle(HttpServletRequest request,HttpServletResponse response,Object handler){
        sessions.inspect(request);
        String path=request.getRequestURI();
        boolean read=Set.of("GET","HEAD","OPTIONS").contains(request.getMethod());
        if(!read) sessions.checkCsrf(request);
        boolean media=read && path.matches("/api/v1/media/[1-9][0-9]{0,18}/content");
        if(!PUBLIC.contains(path) && !media){
            var user=sessions.require(request);
            if(user.isMustChangePassword() && !path.equals("/api/v1/user/auth/me"))
                throw new BusinessException(403,"PASSWORD_CHANGE_REQUIRED","该账号需要修改临时密码，请联系管理员");
        }
        return true;
    }
}
