package com.petcommunity.config;
import java.time.Clock;
import java.util.Map;
import org.springframework.context.annotation.*;
import org.springframework.security.crypto.password.*;
@Configuration
public class ApplicationConfig {
 @Bean public java.security.SecureRandom secureRandom(){ return new java.security.SecureRandom(); }
 @Bean public Clock clock(){ return Clock.systemUTC(); }
 @Bean public PasswordEncoder passwordEncoder(){
   return new DelegatingPasswordEncoder("pbkdf2",Map.of("pbkdf2",Pbkdf2PasswordEncoder.defaultsForSpringSecurity_v5_8()));
 }
}
