package com.petcommunity.dto.user;

import com.petcommunity.validation.CodePointLength;
import jakarta.validation.constraints.*;
import lombok.Data;
import lombok.ToString;

@Data
public class RegisterRequest {
    @NotNull
    @Pattern(regexp="^[A-Za-z0-9_]{3,24}$", message="账号须为 3–24 位字母、数字或下划线")
    private String username;

    @NotNull
    @CodePointLength(min=8, max=64, message="密码须为 8–64 个字符")
    @ToString.Exclude
    private String password;

    @NotBlank(message="请填写昵称")
    @CodePointLength(min=1, max=24, message="昵称最多 24 个字符")
    private String nickname;
}
