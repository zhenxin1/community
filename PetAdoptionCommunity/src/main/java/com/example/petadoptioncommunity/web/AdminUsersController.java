package com.example.petadoptioncommunity.web;
import com.example.petadoptioncommunity.administration.AdminUsersService;
import com.example.petadoptioncommunity.identity.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import jakarta.servlet.http.HttpServletRequest;
import java.util.Set;
@RestController @RequestMapping("/api/v1/admin/users")
public class AdminUsersController {
 private final AdminUsersService service; private final com.example.petadoptioncommunity.administration.StateCommandService commands;
 public AdminUsersController(AdminUsersService service,com.example.petadoptioncommunity.administration.StateCommandService commands){this.service=service;this.commands=commands;}
 private void query(HttpServletRequest r,Set<String> allowed){r.getParameterMap().forEach((k,v)->{if(!allowed.contains(k)||v.length!=1)throw AccountRules.invalid();});}
 @GetMapping public Object list(@AuthenticationPrincipal IdentityPort.Actor actor,HttpServletRequest r){query(r,Set.of("page","size","accountContains","status"));return service.list(actor,r.getParameter("page"),r.getParameter("size"),r.getParameter("accountContains"),r.getParameter("status"));}
 @GetMapping("/{id}") public Object detail(@AuthenticationPrincipal IdentityPort.Actor actor,@PathVariable String id,HttpServletRequest r){query(r,Set.of());return service.detail(actor,id);}
 private Long stateVersion(tools.jackson.databind.JsonNode value){
  if(value==null||!value.isIntegralNumber()||!value.canConvertToLong()||value.longValue()<0)throw AccountRules.invalid();
  return value.longValue();
 }
 public record StateRequest(String operationId,tools.jackson.databind.JsonNode expectedStateVersion,String targetStatus,String reason){}
 @PostMapping("/{id}/state") public Object state(@AuthenticationPrincipal IdentityPort.Actor actor,@PathVariable String id,@RequestBody StateRequest body){var result=commands.execute(actor,id,body.operationId(),stateVersion(body.expectedStateVersion()),body.targetStatus(),body.reason());com.example.petadoptioncommunity.operations.OperationAttemptContext.result(result.replayed()?"REPLAYED":result.outcome());return result;}
 public record NotificationRequest(String operationId,String title,String body){}
 @PostMapping("/{id}/notifications") public Object notification(@AuthenticationPrincipal IdentityPort.Actor actor,@PathVariable String id,@RequestBody NotificationRequest body){var result=commands.send(actor,id,body.operationId(),body.title(),body.body());com.example.petadoptioncommunity.operations.OperationAttemptContext.result(result.replayed()?"REPLAYED":result.outcome());return result;}
}
