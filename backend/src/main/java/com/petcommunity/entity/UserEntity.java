package com.petcommunity.entity;

import java.time.LocalDateTime;
import lombok.Data;
import lombok.ToString;
import com.fasterxml.jackson.annotation.JsonIgnore;

@Data
public class UserEntity {
    private Long id;
    private String username;
    @JsonIgnore
    @ToString.Exclude
    private String passwordHash;
    private String nickname;
    private Long avatarMediaId;
    private String phone;
    private String location;
    private String status;
    private String role;
    private boolean mustChangePassword;
    private int authVersion;
    private int version;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
