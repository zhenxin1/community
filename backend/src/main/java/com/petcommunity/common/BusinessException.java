package com.petcommunity.common;
import java.util.Map;
public class BusinessException extends RuntimeException {
    private final int status; private final String code; private final Map<String,String> headers;
    public BusinessException(int status, String code, String message) { this(status,code,message,Map.of()); }
    public BusinessException(int status, String code, String message, Map<String,String> headers) {
        super(message); this.status=status; this.code=code; this.headers=Map.copyOf(headers);
    }
    public int getStatus(){ return status; } public String getCode(){ return code; }
    public Map<String,String> getHeaders(){ return headers; }
}
