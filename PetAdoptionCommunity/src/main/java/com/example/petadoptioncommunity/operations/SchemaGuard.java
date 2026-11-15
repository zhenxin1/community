package com.example.petadoptioncommunity.operations;
import org.springframework.stereotype.Component;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.ApplicationArguments;
import org.springframework.jdbc.core.JdbcTemplate;
import java.util.Properties;
@Component
public class SchemaGuard implements ApplicationRunner {
 private final JdbcTemplate db;
 public SchemaGuard(JdbcTemplate db){this.db=db;}
 public void run(ApplicationArguments args)throws Exception{
  Properties expected=new Properties();try(var in=getClass().getResourceAsStream("/db/migrations/checksums.properties")){expected.load(in);}
  var rows=db.queryForList("SELECT version,checksum FROM schema_version ORDER BY version");
  String[] files={"V001_identity.sql","V002_notifications.sql","V003_commands.sql","V004_business.sql"};
  if(rows.size()!=files.length)throw new IllegalStateException("Schema mismatch");
  for(int i=0;i<files.length;i++)if(((Number)rows.get(i).get("version")).intValue()!=i+1||!expected.getProperty(files[i]).equals(rows.get(i).get("checksum")))throw new IllegalStateException("Schema mismatch. Stop; execute documented offline migration/recovery.");
 }
}
