package com.petcommunity.security;

import org.springframework.beans.factory.annotation.Autowired;
import com.petcommunity.common.BusinessException;
import java.time.*;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
public class LoginLimiter {
 private static final int LIMIT=10;
 private static final Duration WINDOW=Duration.ofMinutes(10);
 private record Attempts(int count,Instant started) {}
 private final Map<String,Attempts> attempts=new ConcurrentHashMap<>();
    @Autowired
    private Clock clock;

 public void check(String username,String ip){
  for(String key:List.of("account:"+username,"ip:"+ip)){
   Attempts a=attempts.get(key);
   if(a!=null && clock.instant().isBefore(a.started().plus(WINDOW)) && a.count()>=LIMIT){
    long seconds=Math.max(1,Duration.between(clock.instant(),a.started().plus(WINDOW)).toSeconds());
    throw new BusinessException(429,"TOO_MANY_REQUESTS","尝试次数较多，请稍后再登录",Map.of("Retry-After",Long.toString(seconds)));
   }
  }
 }
 public void failed(String username,String ip){
  for(String key:List.of("account:"+username,"ip:"+ip)){
   if(attempts.size()>20000 && !attempts.containsKey(key)) cleanup();
   if(attempts.size()>20000 && !attempts.containsKey(key)) throw new BusinessException(429,"TOO_MANY_REQUESTS","请稍后再试",Map.of("Retry-After","60"));
   attempts.compute(key,(k,a)->a==null || !clock.instant().isBefore(a.started().plus(WINDOW)) ? new Attempts(1,clock.instant()) : new Attempts(a.count()+1,a.started()));
  }
 }
 public void succeeded(String username){ attempts.remove("account:"+username); }
 @Scheduled(fixedDelay=600000) public void cleanup(){ attempts.entrySet().removeIf(e->!clock.instant().isBefore(e.getValue().started().plus(WINDOW))); }
}
