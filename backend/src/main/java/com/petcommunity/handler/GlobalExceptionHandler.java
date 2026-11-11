package com.petcommunity.handler;

import com.petcommunity.common.BusinessException;
import com.petcommunity.common.*;
import jakarta.servlet.http.HttpServletRequest;
import java.util.*;
import org.slf4j.*;
import org.springframework.http.*;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.multipart.*;
import org.springframework.web.servlet.resource.NoResourceFoundException;
import org.springframework.web.HttpRequestMethodNotSupportedException;

@RestControllerAdvice
public class GlobalExceptionHandler {
 private static final Logger LOG=LoggerFactory.getLogger(GlobalExceptionHandler.class);
 private ResponseEntity<ErrorResult> error(int status,String code,String message,List<FieldError> fields,HttpServletRequest req,Map<String,String> headers){
  HttpHeaders h=new HttpHeaders(); headers.forEach(h::set);
  return new ResponseEntity<>(new ErrorResult(code,message,(String)req.getAttribute("requestId"),fields),h,HttpStatusCode.valueOf(status));
 }
 @ExceptionHandler(BusinessException.class)
 public ResponseEntity<ErrorResult> business(BusinessException e,HttpServletRequest req){ return error(e.getStatus(),e.getCode(),e.getMessage(),List.of(),req,e.getHeaders()); }
 @ExceptionHandler(MethodArgumentNotValidException.class)
 public ResponseEntity<ErrorResult> validation(MethodArgumentNotValidException e,HttpServletRequest req){
  var fields=e.getBindingResult().getFieldErrors().stream().map(f->new FieldError(f.getField(),f.getDefaultMessage())).distinct().toList();
  return error(400,"VALIDATION_ERROR","请检查填写的内容",fields,req,Map.of());
 }
 @ExceptionHandler({HttpMessageNotReadableException.class,MethodArgumentTypeMismatchException.class,org.springframework.web.bind.MissingServletRequestParameterException.class,org.springframework.web.multipart.support.MissingServletRequestPartException.class})
 public ResponseEntity<ErrorResult> badInput(Exception e,HttpServletRequest req){ return error(400,"VALIDATION_ERROR","请求字段或格式不正确",List.of(new FieldError("body","请按接口规定填写字段和类型")),req,Map.of()); }
 @ExceptionHandler(MaxUploadSizeExceededException.class)
 public ResponseEntity<ErrorResult> tooLarge(Exception e,HttpServletRequest req){ return error(413,"FILE_TOO_LARGE","头像图片不能超过 5 MB",List.of(),req,Map.of()); }
 @ExceptionHandler({org.springframework.web.HttpMediaTypeNotSupportedException.class,MultipartException.class})
 public ResponseEntity<ErrorResult> type(Exception e,HttpServletRequest req){ return error(415,"UNSUPPORTED_MEDIA_TYPE","请上传支持的图片格式",List.of(),req,Map.of()); }
 @ExceptionHandler(NoResourceFoundException.class)
 public ResponseEntity<ErrorResult> missing(Exception e,HttpServletRequest req){ return error(404,"RESOURCE_NOT_FOUND","内容不存在或不可访问",List.of(),req,Map.of()); }
 @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
 public ResponseEntity<ErrorResult> method(Exception e,HttpServletRequest req){ return error(405,"METHOD_NOT_ALLOWED","该接口不支持此请求方式",List.of(),req,Map.of()); }
 @ExceptionHandler(Exception.class)
 public ResponseEntity<ErrorResult> unexpected(Exception e,HttpServletRequest req){
  LOG.error("Unhandled error requestId={}",req.getAttribute("requestId"),e);
  return error(500,"INTERNAL_ERROR","服务暂时不可用，请稍后再试",List.of(),req,Map.of());
 }
}
