package com.example.petadoptioncommunity.web;
import com.example.petadoptioncommunity.identity.IdentityService;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.*;
import org.springframework.dao.DataAccessException;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.HttpMediaTypeNotSupportedException;
import java.util.*;
@RestControllerAdvice
public class Errors {
 public static Map<String,Object> body(String code,String message){return new LinkedHashMap<>(Map.of("code",code,"message",message,"requestId",com.example.petadoptioncommunity.operations.OperationAttemptContext.requestId()));}
 @ExceptionHandler(ApiFailure.class) public ResponseEntity<?> failure(ApiFailure e){var result=body(e.code,e.getMessage());if(e instanceof IdentityService.Frozen frozen){result.put("reason",frozen.reason);result.put("actionAt",frozen.actionAt);}return ResponseEntity.status(e.status).body(result);}
 @ExceptionHandler(HttpMessageNotReadableException.class) public ResponseEntity<?> badBody(){return ResponseEntity.badRequest().body(body("VALIDATION_ERROR","请求字段或JSON格式无效"));}
 @ExceptionHandler(HttpMediaTypeNotSupportedException.class) public ResponseEntity<?> media(){return ResponseEntity.status(415).body(body("VALIDATION_ERROR","请使用application/json"));}
 @ExceptionHandler(DataAccessException.class) public ResponseEntity<?> database(){return ResponseEntity.status(503).body(body("DEPENDENCY_UNAVAILABLE","服务暂不可用，结果未确认"));}
 @ExceptionHandler(org.springframework.transaction.TransactionException.class) public ResponseEntity<?> transaction(){return ResponseEntity.status(503).body(body("DEPENDENCY_UNAVAILABLE","服务暂不可用，结果未确认"));}
 @ExceptionHandler(org.springframework.web.method.annotation.MethodArgumentTypeMismatchException.class) public ResponseEntity<?> queryType(){return ResponseEntity.badRequest().body(body("VALIDATION_ERROR","查询参数类型无效"));}
 @ExceptionHandler(org.springframework.web.multipart.MaxUploadSizeExceededException.class) public ResponseEntity<?> uploadSize(){return ResponseEntity.status(413).body(body("VALIDATION_ERROR","图片不得超过8MB"));}
 @ExceptionHandler(Exception.class) public ResponseEntity<?> unexpected(){return ResponseEntity.status(500).body(body("INTERNAL_ERROR","请求处理失败"));}
}
