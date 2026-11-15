package com.example.petadoptioncommunity.operations;
import java.util.*;
import java.time.Instant;
import java.nio.file.*;
import java.nio.charset.StandardCharsets;
import java.io.IOException;
import tools.jackson.databind.ObjectMapper;
/** Request lifetime only; never retains credentials or raw request bodies. */
public final class OperationAttemptContext {
 private static final ThreadLocal<OperationAttemptContext> CURRENT=new ThreadLocal<>();
 private static final ObjectMapper JSON=new ObjectMapper();private static long missing;private static Instant missingSince;
 public final String requestId=UUID.randomUUID().toString();public String actorId,targetId,action,operationId,reason="",outcome;
 public static OperationAttemptContext begin(String target,String action){var c=new OperationAttemptContext();c.targetId=target;c.action=action;CURRENT.set(c);return c;}
 public static String requestId(){var c=CURRENT.get();return c==null?UUID.randomUUID().toString():c.requestId;}
 public static void result(String result){var c=CURRENT.get();if(c!=null)c.outcome=result;}
 public void fields(String operation,String reason){this.operationId=bounded(operation,36);this.reason=bounded(reason,200);}
 private static String bounded(String value,int max){if(value==null)return "";int n=value.codePointCount(0,value.length());return value.substring(0,value.offsetByCodePoints(0,Math.min(n,max)));}
 public void finish(int status){try{if(actorId!=null){String result=outcome!=null?outcome:switch(status){case 400,415->"VALIDATION_ERROR";case 401->"SESSION_INVALID";case 403->"FORBIDDEN";case 404->"NOT_FOUND";case 409->"CONFLICT";default->"FAILED";};var fields=new LinkedHashMap<String,Object>();fields.put("level","INFO");fields.put("actorId",actorId);fields.put("targetId",targetId);fields.put("action",action);fields.put("result",result);fields.put("reason",reason);fields.put("operationId",operationId);fields.put("requestId",requestId);fields.put("time",Instant.now().toString());write(JSON.writeValueAsString(fields));}else System.err.println("Management request unauthenticated requestId="+requestId);}catch(Exception failure){System.err.println("Operation attempt logging failed requestId="+requestId);}finally{CURRENT.remove();}}
 private static void secure(Path path,boolean directory)throws IOException {
  var acl=Files.getFileAttributeView(path,java.nio.file.attribute.AclFileAttributeView.class);
  if(acl!=null){var owner=path.getFileSystem().getUserPrincipalLookupService().lookupPrincipalByName(System.getProperty("user.name"));var entry=java.nio.file.attribute.AclEntry.newBuilder().setType(java.nio.file.attribute.AclEntryType.ALLOW).setPrincipal(owner).setPermissions(java.nio.file.attribute.AclEntryPermission.values());if(directory)entry.setFlags(java.nio.file.attribute.AclEntryFlag.DIRECTORY_INHERIT,java.nio.file.attribute.AclEntryFlag.FILE_INHERIT);acl.setAcl(List.of(entry.build()));}
  else Files.setPosixFilePermissions(path,java.nio.file.attribute.PosixFilePermissions.fromString(directory?"rwx------":"rw-------"));
 }
 private static synchronized void write(String line){
  try{
   Path directory=Path.of(System.getProperty("e4.operations.directory","logs/operations"));Files.createDirectories(directory);secure(directory,true);Path current=directory.resolve("operations.log");
   if(Files.exists(current)&&Files.size(current)+line.getBytes(StandardCharsets.UTF_8).length>10*1024*1024)Files.move(current,directory.resolve("operations-"+System.currentTimeMillis()+".log"));
   try(var paths=Files.list(directory)){var files=paths.filter(p->p.getFileName().toString().startsWith("operations-")&&p.getFileName().toString().endsWith(".log")).sorted(Comparator.reverseOrder()).toList();long size=Files.exists(current)?Files.size(current):0;for(Path file:files){size+=Files.size(file);if(size>190L*1024*1024||Files.getLastModifiedTime(file).toInstant().isBefore(Instant.now().minusSeconds(14*86400)))Files.delete(file);}}
   Files.writeString(current,line+System.lineSeparator(),StandardCharsets.UTF_8,StandardOpenOption.CREATE,StandardOpenOption.APPEND);secure(current,false);
   if(missing>0){System.err.println("Operation logging recovered missingCount="+missing+" since="+missingSince);missing=0;missingSince=null;}

  }catch(Exception e){if(missing++==0)missingSince=Instant.now();System.err.println("Operation logging unavailable missingCount="+missing);}
 }
}
