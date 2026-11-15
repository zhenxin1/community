package com.example.petadoptioncommunity.adoption;
import com.example.petadoptioncommunity.identity.*;import org.springframework.security.core.annotation.AuthenticationPrincipal;import org.springframework.web.bind.annotation.*;
@RestController @RequestMapping("/api/v1") public class AdoptionController {
 private final AdoptionService service; public AdoptionController(AdoptionService s){service=s;}
 @GetMapping("/health") public Object health(){return java.util.Map.of("status","ok","project","PetHaven");}
 @GetMapping("/pets") public Object list(@RequestParam(required=false)String keyword,@RequestParam(required=false)String category,@RequestParam(required=false)String region,@RequestParam(required=false)String breed,@RequestParam(defaultValue="1")int page){return service.list(keyword,category,region,breed,page);}
 @GetMapping("/pets/{id}")public Object detail(@PathVariable String id,@AuthenticationPrincipal IdentityPort.Actor a){return service.detail(id,a);}
 @PostMapping("/pets")public Object publish(@AuthenticationPrincipal IdentityPort.Actor a,@RequestBody AdoptionService.Publish b){return service.publish(a,b);}
 @PostMapping("/pets/{id}/applications")public Object apply(@AuthenticationPrincipal IdentityPort.Actor a,@PathVariable String id){return service.apply(a,id);}
 @GetMapping("/adoptions") public Object mine(@AuthenticationPrincipal IdentityPort.Actor a){return service.dashboard(a);}
 @PostMapping("/adoptions/{id}/{action}")public Object act(@AuthenticationPrincipal IdentityPort.Actor a,@PathVariable String id,@PathVariable String action){return service.act(a,id,action);}
}
