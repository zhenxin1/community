package com.petcommunity.vo.user;
import java.time.OffsetDateTime;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserVO {
    private String id;
    private String username;
    private String nickname;
    private String avatarId;
    private String phone;
    private String location;
    private String status;
    private String role;
    private boolean mustChangePassword;
    private int version;
    private OffsetDateTime createdAt;
}
