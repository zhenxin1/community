package com.petcommunity.utils;

import com.petcommunity.common.BusinessException;
import java.io.*;
import java.nio.file.*;
import java.util.*;
import javax.imageio.ImageIO;
import javax.imageio.stream.ImageInputStream;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

@Component
public class AvatarStorage {
 public record Stored(String key,String mime,long size,String originalName) {}
 @Value("${app.storage-root}")
 private String storageRoot;
 public Stored save(MultipartFile file){
  if(file.isEmpty()) throw invalid("请选择一张图片");
  if(file.getSize()>5242880) throw new BusinessException(413,"FILE_TOO_LARGE","头像图片不能超过 5 MB");
  String original=Optional.ofNullable(file.getOriginalFilename()).orElse("").replace('\\','/');
  original=original.substring(original.lastIndexOf('/')+1);
  if(original.codePointCount(0,original.length())>255) throw invalid("图片文件名过长");
  String ext=original.contains(".") ? original.substring(original.lastIndexOf('.')+1).toLowerCase(Locale.ROOT) : "";
  try{
   byte[] bytes=file.getBytes(); String mime=detect(bytes);
   boolean matches=switch(mime){
    case "image/jpeg" -> Set.of("jpg","jpeg").contains(ext);
    case "image/png" -> ext.equals("png");
    case "image/gif" -> ext.equals("gif");
    case "image/webp" -> ext.equals("webp");
    default -> false;
   };
   String supplied=file.getContentType();
   if(!matches || supplied!=null && !supplied.equals("application/octet-stream") && !supplied.equals(mime)) throw invalid("图片格式与文件内容不一致");
   if(!mime.equals("image/webp")){
    try(ImageInputStream image=ImageIO.createImageInputStream(new ByteArrayInputStream(bytes))){
     var readers=ImageIO.getImageReaders(image);
     if(!readers.hasNext()) throw invalid("这张图片无法读取，请换一张");
     var reader=readers.next();
     try{ reader.setInput(image); int w=reader.getWidth(0),h=reader.getHeight(0);
      if(w<=0 || h<=0 || (long)w*h>40000000) throw invalid("图片尺寸过大，请压缩后再上传");
     }finally{ reader.dispose(); }
    }catch(IOException e){ throw invalid("图片内容不完整，请换一张"); }
   }
   String key="avatars/"+UUID.randomUUID()+"."+(mime.equals("image/jpeg")?"jpg":ext);
   Path destination=resolve(key); Files.createDirectories(destination.getParent());
   Files.write(destination,bytes,StandardOpenOption.CREATE_NEW);
   return new Stored(key,mime,bytes.length,original);
  }catch(IOException e){ throw new BusinessException(500,"INTERNAL_ERROR","图片保存失败，请稍后重试"); }
 }
 public byte[] read(String key){
  try{ return Files.readAllBytes(resolve(key)); }
  catch(IOException e){ throw new BusinessException(404,"RESOURCE_NOT_FOUND","图片不存在或不可访问"); }
 }
 public void delete(String key) throws IOException { Files.deleteIfExists(resolve(key)); }
 private Path resolve(String key){
  Path root=Path.of(storageRoot).toAbsolutePath().normalize();
  Path path=root.resolve(key).normalize();
  if(!path.startsWith(root)) throw new BusinessException(404,"RESOURCE_NOT_FOUND","图片不可访问");
  return path;
 }
 public static String detect(byte[] b){
  if(b.length>=8 && Arrays.equals(Arrays.copyOf(b,8),new byte[]{(byte)137,80,78,71,13,10,26,10})) return "image/png";
  if(b.length>=3 && (b[0]&255)==255 && (b[1]&255)==216 && (b[2]&255)==255) return "image/jpeg";
  if(b.length>=6){ String signature=new String(b,0,6,java.nio.charset.StandardCharsets.US_ASCII); if(signature.equals("GIF87a") || signature.equals("GIF89a")) return "image/gif"; }
  if(b.length>=12 && new String(b,0,4,java.nio.charset.StandardCharsets.US_ASCII).equals("RIFF") && new String(b,8,4,java.nio.charset.StandardCharsets.US_ASCII).equals("WEBP")) return "image/webp";
  throw invalid("支持 JPG、PNG、GIF、WebP 图片");
 }
 private static BusinessException invalid(String message){ return new BusinessException(415,"UNSUPPORTED_MEDIA_TYPE",message); }
}
