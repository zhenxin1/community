package com.petcommunity.security;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.UUID;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
@Component
public class RequestFilter extends OncePerRequestFilter {
 @Override protected void doFilterInternal(HttpServletRequest request,HttpServletResponse response,FilterChain chain) throws ServletException,IOException {
  String id="req_"+UUID.randomUUID().toString().replace("-","");
  request.setAttribute("requestId",id); response.setHeader("X-Request-ID",id);
  response.setHeader("X-Content-Type-Options","nosniff"); response.setHeader("X-Frame-Options","DENY");
  response.setHeader("Referrer-Policy","strict-origin-when-cross-origin");
  response.setHeader("Content-Security-Policy","default-src 'self'; img-src 'self' data: blob:; style-src 'self' 'unsafe-inline'; script-src 'self'; connect-src 'self'; object-src 'none'; base-uri 'self'; frame-ancestors 'none'");
  if(request.getRequestURI().startsWith("/api/")) response.setHeader("Cache-Control","private, no-store");
  chain.doFilter(request,response);
 }
}
