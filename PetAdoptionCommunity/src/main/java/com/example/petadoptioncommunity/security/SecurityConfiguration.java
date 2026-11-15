package com.example.petadoptioncommunity.security;
import com.example.petadoptioncommunity.identity.*;
import com.example.petadoptioncommunity.web.*;
import org.springframework.context.annotation.*;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.*;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.*;
@Configuration
@org.springframework.boot.autoconfigure.condition.ConditionalOnWebApplication(type=org.springframework.boot.autoconfigure.condition.ConditionalOnWebApplication.Type.SERVLET)
public class SecurityConfiguration {
 static void error(HttpServletResponse response,int status,String code,String message)throws IOException{
  response.setStatus(status);response.setContentType("application/json;charset=UTF-8");response.setHeader("Cache-Control","no-store");
  response.getWriter().write("{\"code\":\""+code+"\",\"message\":\""+message+"\",\"requestId\":\""+com.example.petadoptioncommunity.operations.OperationAttemptContext.requestId()+"\"}");
 }
 @Bean org.springframework.security.core.userdetails.UserDetailsService noDefaultUsers(){return username -> {throw new org.springframework.security.core.userdetails.UsernameNotFoundException("No password authentication provider");};}
 @Bean SecurityFilterChain chain(HttpSecurity http,IdentityService identity)throws Exception{
  http.csrf(c->c.disable()).cors(c->c.disable()).requestCache(c->c.disable()).sessionManagement(s->s.sessionCreationPolicy(SessionCreationPolicy.STATELESS));
  http.authorizeHttpRequests(a->a.requestMatchers(org.springframework.http.HttpMethod.GET,"/api/v1/pets","/api/v1/pets/*","/api/v1/products","/api/v1/products/*","/api/v1/health","/media/**","/","/index.html","/assets/**").permitAll().requestMatchers("/api/v1/pets/**","/api/v1/adoptions/**","/api/v1/cart/**","/api/v1/addresses/**","/api/v1/orders/**","/api/v1/uploads").authenticated().requestMatchers(org.springframework.http.HttpMethod.POST,"/api/v1/auth/register","/api/v1/auth/login","/api/v1/auth/logout").permitAll().requestMatchers("/api/v1/me","/api/v1/me/password","/api/v1/me/notifications","/api/v1/me/notifications/**").authenticated().requestMatchers("/api/v1/admin/**").hasRole("ADMIN").anyRequest().denyAll());
  http.exceptionHandling(e->e.authenticationEntryPoint((q,r,x)->error(r,401,"UNAUTHENTICATED","请先登录")).accessDeniedHandler((q,r,x)->error(r,403,"FORBIDDEN","无权限")));
  http.addFilterBefore(new OncePerRequestFilter(){
   protected void doFilterInternal(HttpServletRequest q,HttpServletResponse r,FilterChain chain)throws ServletException,IOException{
    r.setHeader("Cache-Control","no-store");
    boolean management=q.getMethod().equals("POST")&&q.getRequestURI().matches("/api/v1/admin/users/[^/]+/(state|notifications)");
    com.example.petadoptioncommunity.operations.OperationAttemptContext attempt=management?com.example.petadoptioncommunity.operations.OperationAttemptContext.begin(q.getRequestURI().split("/")[5],q.getRequestURI().endsWith("/notifications")?"ADMIN_MESSAGE":"STATE"):null;
    org.springframework.web.util.ContentCachingRequestWrapper cached=management?new org.springframework.web.util.ContentCachingRequestWrapper(q,16384):null;
    if(attempt!=null&&"ADMIN_MESSAGE".equals(attempt.action))attempt.reason="管理员单用户通知";
    if(cached!=null)q=cached;
    try {
    boolean publicAuth=q.getMethod().equals("POST")&&Set.of("/api/v1/auth/login","/api/v1/auth/register","/api/v1/auth/logout").contains(q.getRequestURI());
    if(!publicAuth&&q.getHeader("Authorization")!=null){try{var actor=identity.requireActive(q.getHeader("Authorization"));if(attempt!=null)attempt.actorId=actor.userId();SecurityContextHolder.getContext().setAuthentication(new UsernamePasswordAuthenticationToken(actor,null,List.of(new SimpleGrantedAuthority("ROLE_"+actor.role()))));}catch(ApiFailure e){error(r,e.status,e.code,e.getMessage());return;}catch(org.springframework.dao.DataAccessException e){error(r,503,"DEPENDENCY_UNAVAILABLE","服务暂不可用");return;}}
    if(attempt!=null&&attempt.actorId!=null){
     byte[] body=cached.getInputStream().readNBytes(16385);
     if(body.length>16384){error(r,400,"VALIDATION_ERROR","请求过长");return;}
     q=new HttpServletRequestWrapper(q){@Override public ServletInputStream getInputStream(){var input=new java.io.ByteArrayInputStream(body);return new ServletInputStream(){public int read(){return input.read();}public boolean isFinished(){return input.available()==0;}public boolean isReady(){return true;}public void setReadListener(ReadListener listener){throw new UnsupportedOperationException();}};}@Override public java.io.BufferedReader getReader(){return new java.io.BufferedReader(new java.io.InputStreamReader(getInputStream(),java.nio.charset.StandardCharsets.UTF_8));}};
    }
    chain.doFilter(q,r);
    } finally {if(attempt!=null){try{var body=new tools.jackson.databind.ObjectMapper().readTree(cached.getContentAsByteArray());attempt.fields(body.path("operationId").asString(""),"ADMIN_MESSAGE".equals(attempt.action)?"管理员单用户通知":body.path("reason").asString(""));}catch(Exception ignored){}attempt.finish(r.getStatus());}}
   }
  },UsernamePasswordAuthenticationFilter.class);
  return http.build();
 }
}
