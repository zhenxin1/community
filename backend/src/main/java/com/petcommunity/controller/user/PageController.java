package com.petcommunity.controller.user;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
@Controller
public class PageController {
 @GetMapping({"/","/login","/register","/profile"}) public String page(){ return "forward:/index.html"; }
}
