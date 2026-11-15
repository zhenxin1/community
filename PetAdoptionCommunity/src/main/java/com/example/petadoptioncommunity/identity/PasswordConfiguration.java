package com.example.petadoptioncommunity.identity;
import org.springframework.context.annotation.*;
import org.springframework.security.crypto.password.*;
import java.util.Map;
@Configuration
public class PasswordConfiguration {
 @Bean public PasswordEncoder passwordEncoder(){
  var encoder=new Pbkdf2PasswordEncoder("",16,600000,Pbkdf2PasswordEncoder.SecretKeyFactoryAlgorithm.PBKDF2WithHmacSHA256);
  encoder.setEncodeHashAsBase64(false);
  return new DelegatingPasswordEncoder("pbkdf2-sha256-i600000-s16-v1",Map.of("pbkdf2-sha256-i600000-s16-v1",encoder));
 }
}
