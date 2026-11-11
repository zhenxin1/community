package com.petcommunity.common;
import java.util.List;
public record ErrorResult(String code, String message, String requestId, List<FieldError> fieldErrors) {}
