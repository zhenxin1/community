package com.example.petadoptioncommunity.identity;
import java.util.Locale;
import com.example.petadoptioncommunity.web.ApiFailure;
public final class AccountRules {
 private AccountRules() {}
 public static String account(String value) {
  if(value==null) throw invalid();
  String account=trimAccount(value).toLowerCase(Locale.ROOT);
  if(!account.matches("[a-z0-9_]{4,16}")) throw invalid();
  return account;
 }
 private static boolean trimSpace(char c) { return c==0x09||c==0x0a||c==0x0b||c==0x0c||c==0x0d||c==0x20||c==0xa0||c==0x1680||(c>=0x2000&&c<=0x200a)||c==0x2028||c==0x2029||c==0x202f||c==0x205f||c==0x3000||c==0xfeff; }
 public static String trimAccount(String value) { int start=0,end=value.length();while(start<end&&trimSpace(value.charAt(start)))start++;while(end>start&&trimSpace(value.charAt(end-1)))end--;return value.substring(start,end); }
 public static void password(String value) {
  if(value==null) throw invalid();
  int count=value.codePointCount(0,value.length());
  if(count<8||count>32||!value.codePoints().anyMatch(UnicodeCategories::isLetter)||!value.codePoints().anyMatch(UnicodeCategories::isDecimalDigit)) throw invalid();
 }
 public static void loginPassword(String value) { if(value==null||value.isEmpty()||value.codePointCount(0,value.length())>32) throw invalid(); }
 public static ApiFailure invalid(){return new ApiFailure(400,"VALIDATION_ERROR","输入不符合规范");}
}
