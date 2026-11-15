package com.example.petadoptioncommunity;
import com.example.petadoptioncommunity.administration.AdminUsersService;
import com.example.petadoptioncommunity.web.ApiFailure;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
class AdminUsersRulesTest {
 @Test void strictNumbersAndNormalization(){
  assertEquals(1,AdminUsersService.number(null,1));assertEquals(20,AdminUsersService.number("20",1));
  for(String s:new String[]{"","0","-1","1.0","true"," 1","2147483648"})assertEquals(400,assertThrows(ApiFailure.class,()->AdminUsersService.number(s,1)).status);
  assertEquals("a_%",AdminUsersService.contains("\u3000A_%\u00a0"));
  assertEquals(16,AdminUsersService.contains("😀".repeat(16)).codePointCount(0,32));
  assertThrows(ApiFailure.class,()->AdminUsersService.contains("😀".repeat(17)));
 }
}
