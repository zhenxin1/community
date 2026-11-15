package com.example.petadoptioncommunity.identity;
import tools.jackson.databind.ObjectMapper;
/** Fixed Java 17 / Unicode 13.0 categories shared with the browser. */
public final class UnicodeCategories {
 private UnicodeCategories() {}
 private record Data(String version,String classificationSha256,int[][] letters,int[][] decimalDigits) {}
 private static final Data DATA=load();
 private static Data load(){
  try(var input=UnicodeCategories.class.getResourceAsStream("/identity/unicode-java17.json")){
   var result=new ObjectMapper().readValue(input,Data.class);
   if(!"Java17-Unicode13.0".equals(result.version()))throw new IllegalStateException("Unicode data version mismatch");
   return result;
  }catch(Exception failure){throw new ExceptionInInitializerError(failure);}
 }
 private static boolean contains(int[][] ranges,int cp){
  int low=0,high=ranges.length-1;
  while(low<=high){int mid=(low+high)>>>1;if(cp<ranges[mid][0])high=mid-1;else if(cp>ranges[mid][1])low=mid+1;else return true;}
  return false;
 }
 public static boolean isLetter(int cp){return contains(DATA.letters(),cp);}
 public static boolean isDecimalDigit(int cp){return contains(DATA.decimalDigits(),cp);}
}
