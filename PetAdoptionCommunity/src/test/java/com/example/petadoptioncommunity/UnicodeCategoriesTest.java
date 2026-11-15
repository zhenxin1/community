package com.example.petadoptioncommunity;
import com.example.petadoptioncommunity.identity.*;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
class UnicodeCategoriesTest {
 @Test void everyCodePointMatchesJava17(){
  assertEquals(17,Runtime.version().feature(),"Run parity against target Java 17");
  for(int cp=0;cp<=Character.MAX_CODE_POINT;cp++){
   assertEquals(Character.isLetter(cp),UnicodeCategories.isLetter(cp),"letter U+"+Integer.toHexString(cp));
   assertEquals(Character.isDigit(cp),UnicodeCategories.isDecimalDigit(cp),"digit U+"+Integer.toHexString(cp));
  }
 }
 @Test void fixedVersionRegressionAndPasswordBoundaries(){
  for(int cp:new int[]{0x11f04,0x11380}){assertFalse(UnicodeCategories.isLetter(cp));String password=Character.toString(cp)+"1234567";assertThrows(RuntimeException.class,()->AccountRules.password(password));}
  for(int cp:new int[]{0x11f50,0x1e4f0,0x10d40}){assertFalse(UnicodeCategories.isDecimalDigit(cp));String password="abcdefg"+Character.toString(cp);assertThrows(RuntimeException.class,()->AccountRules.password(password));}
  for(int cp:new int[]{'a',0x5b57,0x10400})assertTrue(UnicodeCategories.isLetter(cp));
  for(int cp:new int[]{'1',0x661,0x1d7ce})assertTrue(UnicodeCategories.isDecimalDigit(cp));
  for(int n:new int[]{7,8,32,33}){String password="𐐀١"+"😀".repeat(n-2);if(n==8||n==32)assertDoesNotThrow(()->AccountRules.password(password));else assertThrows(RuntimeException.class,()->AccountRules.password(password));}
 }
}
