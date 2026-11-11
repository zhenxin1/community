package com.petcommunity.vo.user;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SessionVO {
    private boolean authenticated;
    private String csrfToken;
}
