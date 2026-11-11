package com.petcommunity.dto.user;

import com.petcommunity.validation.CodePointLength;
import jakarta.validation.constraints.*;
import lombok.Data;
import lombok.ToString;

@Data
public class LoginRequest {
    @NotBlank(message="请填写账号")
    @Size(min=3, max=24, message="账号须为 3–24 位")
    private String username;

    @NotNull
    @CodePointLength(min=1, max=64, message="请填写有效密码")
    @ToString.Exclude
    private String password;
}
