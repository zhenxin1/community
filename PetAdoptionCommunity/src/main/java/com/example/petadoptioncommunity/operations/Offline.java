package com.example.petadoptioncommunity.operations;
import com.example.petadoptioncommunity.PetAdoptionCommunityApplication;
import com.example.petadoptioncommunity.identity.IdentityService;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.boot.WebApplicationType;
import java.util.*;
import java.sql.*;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Instant;
public final class Offline {
 public static void main(String[] args)throws Exception{
  try { execute(args); } catch(Exception failure) { result("FAILED");throw new IllegalStateException("Offline operation failed; inspect schema and configuration safely before retrying."); }
 }
 private static void result(String outcome){System.out.println("executor="+System.getProperty("user.name").replaceAll("[\\r\\n\\t]","_")+" version=1 time="+Instant.now()+" result="+outcome);}
 private static void execute(String[] args)throws Exception{
  if(args.length!=1||!Set.of("migrate","admin","admin-stdin").contains(args[0]))throw new IllegalArgumentException("Use migrate or admin; no credentials in arguments");
  TimeZone.setDefault(TimeZone.getTimeZone("UTC"));
  if(args[0].equals("migrate")){migrate();return;}
  boolean stdin=args[0].equals("admin-stdin"); var input=new java.io.BufferedReader(new java.io.InputStreamReader(System.in,StandardCharsets.UTF_8)); var console=System.console();if(!stdin&&console==null)throw new IllegalStateException("A private interactive console is required");
  try(var app=new SpringApplicationBuilder(PetAdoptionCommunityApplication.class).web(WebApplicationType.NONE).run()){
   String account=stdin?input.readLine():console.readLine("Admin account: ");char[] password=stdin?Objects.requireNonNull(input.readLine(),"Missing private stdin password").toCharArray():console.readPassword("Password: ");
   String result;
   try{result=app.getBean(IdentityService.class).initializeAdmin(account,new String(password));}finally{Arrays.fill(password,'\0');}
   result(result);
  }
 }
 private static void migrate()throws Exception{
  var expected=new Properties();try(var in=Offline.class.getResourceAsStream("/db/migrations/checksums.properties")){expected.load(in);}
  String[] files={"V001_identity.sql","V002_notifications.sql","V003_commands.sql","V004_business.sql"};
  var scripts=new ArrayList<byte[]>();var checksums=new ArrayList<String>();
  for(String file:files){byte[] sql;try(var in=Offline.class.getResourceAsStream("/db/migrations/"+file)){sql=in.readAllBytes();}
   String checksum=HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(sql));
   if(!checksum.equals(expected.getProperty(file)))throw new IllegalStateException("Migration checksum mismatch");scripts.add(sql);checksums.add(checksum);
  }
  try(var connection=DriverManager.getConnection(required("DB_URL"),required("DB_USERNAME"),required("DB_PASSWORD"));var statement=connection.createStatement()){
   String catalog=connection.getCatalog();
   if(catalog==null||catalog.isBlank()||Set.of("mysql","sys","information_schema","performance_schema").contains(catalog.toLowerCase(Locale.ROOT)))throw new IllegalStateException("Refusing system or missing database");
   statement.execute("SET time_zone = '+00:00'");int applied=0;
   try(var tables=connection.getMetaData().getTables(connection.getCatalog(),null,"schema_version",new String[]{"TABLE"})){
    if(tables.next())try(var rows=statement.executeQuery("SELECT version,checksum FROM schema_version ORDER BY version")){
     while(rows.next()){if(applied>=files.length||rows.getInt(1)!=applied+1||!checksums.get(applied).equals(rows.getString(2)))throw new IllegalStateException("Partial/mismatched schema");applied++;}
     if(applied==0)throw new IllegalStateException("Partial schema");
    }
   }
   if(applied==files.length){result("SCHEMA_ALREADY_CURRENT");return;}
   for(int i=applied;i<files.length;i++){
    for(String part:new String(scripts.get(i),StandardCharsets.UTF_8).split(";"))if(!part.isBlank())statement.execute(part);
    try(var insert=connection.prepareStatement("INSERT INTO schema_version VALUES(?,?,UTC_TIMESTAMP(3))")){insert.setInt(1,i+1);insert.setString(2,checksums.get(i));insert.executeUpdate();}
   }
   result("MIGRATED");
  }
 }
 private static String required(String name){var value=System.getenv(name);if(value==null||value.isBlank())throw new IllegalStateException("Missing "+name);return value;}
}
