package com.petcommunity.dto.user;

import com.petcommunity.validation.CodePointLength;
import jakarta.validation.constraints.*;
import lombok.Data;

@Data
public class ProfileRequest {
    @NotBlank(message="请填写昵称")
    @CodePointLength(min=1, max=24, message="昵称最多 24 个字符")
    private String nickname;

    @NotNull
    @Pattern(regexp="^([1-9][0-9]{0,18})?$", message="头像编号格式不正确")
    private String avatarId;

    @NotNull
    @CodePointLength(max=32, message="联系方式最多 32 个字符")
    private String phone;

    @NotNull
    @CodePointLength(max=100, message="所在地最多 100 个字符")
    private String location;

    @NotNull
    @Min(value=0, message="版本号不正确")
    private Integer version;
}
