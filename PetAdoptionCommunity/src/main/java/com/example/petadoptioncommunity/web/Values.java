package com.example.petadoptioncommunity.web;
import java.util.*;
public final class Values {
 public static ApiFailure bad(String message){return new ApiFailure(400,"VALIDATION_ERROR",message);}
 public static ApiFailure conflict(String message){return new ApiFailure(409,"CONFLICT",message);}
 public static ApiFailure missing(){return new ApiFailure(404,"NOT_FOUND","记录不存在");}
 public static String text(String value,int max,boolean required){if(value==null)value="";value=value.strip();int n=value.codePointCount(0,value.length());if((required&&n==0)||n>max)throw bad("请检查必填项及字段长度");return value;}
 public static void uuid(String value){try{if(value==null||!UUID.fromString(value).toString().equals(value))throw bad("标识格式无效");}catch(IllegalArgumentException e){throw bad("标识格式无效");}}
 public static void admin(com.example.petadoptioncommunity.identity.IdentityPort.Actor a){if(a==null||!"ADMIN".equals(a.role()))throw new ApiFailure(403,"FORBIDDEN","仅管理员可操作");}
 public static long number(Map<String,Object> m,String key){return ((Number)m.get(key)).longValue();}
 public static boolean bool(Map<String,Object> m,String key){Object v=m.get(key);return Boolean.TRUE.equals(v)||(v instanceof Number n&&n.intValue()!=0);}
 public static Map<String,Object> row(Map<String,Object> m){if(m==null)throw missing();var r=new LinkedHashMap<String,Object>();m.forEach((key,v)->{StringBuilder b=new StringBuilder();boolean up=false;for(char c:key.toCharArray()){if(c=='_')up=true;else{b.append(up?Character.toUpperCase(c):c);up=false;}}r.put(b.toString(),v instanceof java.sql.Timestamp t?t.toInstant().toString():v instanceof java.time.LocalDateTime t?t.toInstant(java.time.ZoneOffset.UTC).toString():v);});return r;}
 public static String image(String value){if(value==null||!value.matches("/(assets|media)/[a-zA-Z0-9_.-]+"))throw bad("请上传有效图片");java.nio.file.Path file=value.startsWith("/assets/")?java.nio.file.Path.of("vue1/public"+value):java.nio.file.Path.of("../.local/uploads",value.substring(7));if(!java.nio.file.Files.isRegularFile(file))throw bad("图片文件不存在，请重新上传");return value;}
}
