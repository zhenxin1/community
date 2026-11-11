package com.petcommunity;
import com.petcommunity.common.BusinessException;
import com.petcommunity.config.ApplicationConfig;
import com.petcommunity.security.LoginLimiter;
import com.petcommunity.utils.AvatarStorage;
import com.petcommunity.service.impl.MediaServiceImpl;
import java.time.*;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.junit.jupiter.SpringJUnitConfig;
import com.petcommunity.entity.UserEntity;
import com.petcommunity.dto.user.RegisterRequest;
import com.petcommunity.dto.user.LoginRequest;

@SpringJUnitConfig(classes={ApplicationConfig.class,LoginLimiter.class})
class AccountBoundaryTest {
    @Autowired
    private PasswordEncoder encoder;
    @Autowired
    private LoginLimiter limiter;
 @Test void lombokDoesNotExposePasswordsInToString(){
  String secret="SensitiveExample123!";
  var user=new UserEntity(); user.setPasswordHash(secret);
  var register=new RegisterRequest(); register.setPassword(secret);
  var login=new LoginRequest(); login.setPassword(secret);
  assertFalse(user.toString().contains(secret));
  assertFalse(register.toString().contains(secret));
  assertFalse(login.toString().contains(secret));
 }
 @Test void unicodePasswordsAreNotTruncated(){
  String password="小爪".repeat(32),hash=encoder.encode(password);
  assertTrue(encoder.matches(password,hash));
  assertFalse(encoder.matches(password.substring(0,62)+"小狗",hash));
  assertNotEquals(hash,encoder.encode(password));assertTrue(hash.startsWith("{pbkdf2}"));
 }
 @Test void passwordWhitespaceIsSignificant(){
  String hash=encoder.encode("  pet12345  ");
  assertTrue(encoder.matches("  pet12345  ",hash));assertFalse(encoder.matches("pet12345",hash));
 }
 @Test void failedAttemptsAreLimitedForBothAccountAndAddress(){
  for(int n=0;n<10;n++){limiter.check("pet","127.0.0.1");limiter.failed("pet","127.0.0.1");}
  assertEquals("TOO_MANY_REQUESTS",assertThrows(BusinessException.class,()->limiter.check("pet","127.0.0.2")).getCode());
  limiter.succeeded("pet");
  assertThrows(BusinessException.class,()->limiter.check("different","127.0.0.1"));
  assertDoesNotThrow(()->limiter.check("pet","127.0.0.2"));
 }
 @Test void rangesHandleSuffixAndClamp(){
  assertArrayEquals(new long[]{0,9},MediaServiceImpl.parseRange("bytes=0-99",10));
  assertArrayEquals(new long[]{7,9},MediaServiceImpl.parseRange("bytes=-3",10));
  assertArrayEquals(new long[]{5,9},MediaServiceImpl.parseRange("bytes=5-",10));
  assertEquals(416,assertThrows(BusinessException.class,()->MediaServiceImpl.parseRange("bytes=20-30",10)).getStatus());
  assertThrows(BusinessException.class,()->MediaServiceImpl.parseRange("bytes=0-1,3-4",10));
 }
 @Test void filesAreDetectedByContent(){
  assertEquals("image/png",AvatarStorage.detect(new byte[]{(byte)137,80,78,71,13,10,26,10}));
  assertThrows(BusinessException.class,()->AvatarStorage.detect("<svg onload=alert(1)>".getBytes()));
 }
}
