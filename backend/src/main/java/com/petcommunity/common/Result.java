package com.petcommunity.common;
public record Result<T>(String code, String message, T data, String requestId) {
    public static <T> Result<T> ok(T data, String requestId) { return new Result<>("OK", "成功", data, requestId); }
}
