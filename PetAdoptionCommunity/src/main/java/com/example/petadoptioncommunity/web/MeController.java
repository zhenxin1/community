package com.example.petadoptioncommunity.web;
import com.example.petadoptioncommunity.identity.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.ResponseEntity;
import jakarta.servlet.http.HttpServletRequest;
@RestController @RequestMapping("/api/v1/me")
public class MeController {
 private final IdentityService identity;
 public MeController(IdentityService identity){this.identity=identity;}
 public record Update(String nickname,String bio,tools.jackson.databind.JsonNode expectedProfileVersion){}
 public record Password(String oldPassword,String newPassword,String confirmPassword){@Override public String toString(){return "Password[redacted]";}}
 private Long profileVersion(tools.jackson.databind.JsonNode value){
  if(value==null||!value.isIntegralNumber()||!value.canConvertToLong()||value.longValue()<0)throw AccountRules.invalid();
  return value.longValue();
 }
 private void noQuery(HttpServletRequest request){if(!request.getParameterMap().isEmpty())throw AccountRules.invalid();}
 @GetMapping public Object get(@AuthenticationPrincipal IdentityPort.Actor actor,HttpServletRequest request){noQuery(request);return identity.me(actor);}
 @PutMapping(consumes="application/json") public Object update(@AuthenticationPrincipal IdentityPort.Actor actor,@RequestBody Update body,HttpServletRequest request){noQuery(request);return identity.updateProfile(actor,body.nickname(),body.bio(),profileVersion(body.expectedProfileVersion()));}
 @PostMapping(value="/password",consumes="application/json") public ResponseEntity<Void> password(@AuthenticationPrincipal IdentityPort.Actor actor,@RequestBody Password body,HttpServletRequest request){noQuery(request);identity.changePassword(actor,body.oldPassword(),body.newPassword(),body.confirmPassword());return ResponseEntity.noContent().build();}
}
