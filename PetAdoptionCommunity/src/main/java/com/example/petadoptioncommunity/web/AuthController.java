package com.example.petadoptioncommunity.web;
import com.example.petadoptioncommunity.identity.IdentityService;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.*;
@RestController @RequestMapping("/api/v1/auth")
public class AuthController {
 private final IdentityService identity;
 public AuthController(IdentityService identity){this.identity=identity;}
 public record Register(String account,String password,String confirmPassword){@Override public String toString(){return "Register[redacted]";}}
 public record Login(String account,String password){@Override public String toString(){return "Login[redacted]";}}
 @PostMapping(value="/register",consumes="application/json") public ResponseEntity<?> register(@RequestBody Register body){return ResponseEntity.status(201).body(identity.register(body.account(),body.password(),body.confirmPassword()));}
 @PostMapping(value="/login",consumes="application/json") public Object login(@RequestBody Login body){return identity.login(body.account(),body.password());}
 @PostMapping("/logout") public ResponseEntity<Void> logout(@RequestHeader(value="Authorization",required=false) String credential,@RequestBody(required=false) byte[] body){if(body!=null&&body.length>0)throw com.example.petadoptioncommunity.identity.AccountRules.invalid();identity.logout(credential);return ResponseEntity.noContent().build();}
}
