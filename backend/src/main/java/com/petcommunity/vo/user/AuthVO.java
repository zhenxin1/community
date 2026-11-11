package com.petcommunity.vo.user;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AuthVO {
    private UserVO user;
    private String csrfToken;
    private int expiresInSeconds;
}
