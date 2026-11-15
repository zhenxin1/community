package com.example.petadoptioncommunity.web;
import com.example.petadoptioncommunity.administration.StateCommandService;
import com.example.petadoptioncommunity.identity.IdentityPort;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
@RestController @RequestMapping("/api/v1/admin/operations") public class AdminOperationsController {
 private final StateCommandService service;public AdminOperationsController(StateCommandService service){this.service=service;}
 @GetMapping("/{id}") public Object get(@AuthenticationPrincipal IdentityPort.Actor actor,@PathVariable String id){return service.get(actor,id);}
}
