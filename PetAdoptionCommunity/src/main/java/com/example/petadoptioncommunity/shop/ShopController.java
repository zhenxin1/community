package com.example.petadoptioncommunity.shop;
import com.example.petadoptioncommunity.identity.*;import org.springframework.security.core.annotation.AuthenticationPrincipal;import org.springframework.web.bind.annotation.*;
@RestController @RequestMapping("/api/v1") public class ShopController {
 private final ShopService service;public ShopController(ShopService s){service=s;}
 @GetMapping("/products")public Object products(@RequestParam(required=false)String keyword,@RequestParam(required=false)String category,@RequestParam(defaultValue="1")int page){return service.catalog(keyword,category,page,false,null);}
 @GetMapping("/products/{id}")public Object product(@PathVariable String id){return service.detail(id);}
 @GetMapping("/admin/products")public Object manage(@AuthenticationPrincipal IdentityPort.Actor a,@RequestParam(required=false)String keyword,@RequestParam(defaultValue="1")int page){return service.catalog(keyword,null,page,true,a);}
 @PostMapping("/admin/products")public Object add(@AuthenticationPrincipal IdentityPort.Actor a,@RequestBody ShopService.ProductInput v){return service.saveProduct(a,null,v);}
 @PutMapping("/admin/products/{id}")public Object save(@AuthenticationPrincipal IdentityPort.Actor a,@PathVariable String id,@RequestBody ShopService.ProductInput v){return service.saveProduct(a,id,v);}
 @GetMapping("/cart")public Object cart(@AuthenticationPrincipal IdentityPort.Actor a){return service.cart(a);}
 public record CartInput(Integer quantity,Boolean selected){}
 @PostMapping("/cart/{id}")public Object cartAdd(@AuthenticationPrincipal IdentityPort.Actor a,@PathVariable String id,@RequestBody CartInput v){return service.setCart(a,id,v.quantity,v.selected,true);}
 @PutMapping("/cart/{id}")public Object cartSet(@AuthenticationPrincipal IdentityPort.Actor a,@PathVariable String id,@RequestBody CartInput v){return service.setCart(a,id,v.quantity,v.selected,false);}
 @DeleteMapping("/cart/{id}")public Object cartDelete(@AuthenticationPrincipal IdentityPort.Actor a,@PathVariable String id){return service.deleteCart(a,id);}
 @GetMapping("/addresses")public Object addresses(@AuthenticationPrincipal IdentityPort.Actor a){return service.addresses(a);}
 @PostMapping("/addresses")public Object addAddress(@AuthenticationPrincipal IdentityPort.Actor a,@RequestBody ShopService.AddressInput v){return service.saveAddress(a,null,v);}
 @PutMapping("/addresses/{id}")public Object saveAddress(@AuthenticationPrincipal IdentityPort.Actor a,@PathVariable String id,@RequestBody ShopService.AddressInput v){return service.saveAddress(a,id,v);}
 @GetMapping("/orders/quote")public Object quote(@AuthenticationPrincipal IdentityPort.Actor a,@RequestParam String addressId){return service.getQuote(a,addressId);}
 @PostMapping("/orders")public Object create(@AuthenticationPrincipal IdentityPort.Actor a,@RequestBody ShopService.Checkout v){return service.create(a,v);}
 @GetMapping("/orders")public Object orders(@AuthenticationPrincipal IdentityPort.Actor a){return service.orders(a,false);}
 @GetMapping("/orders/{id}")public Object order(@AuthenticationPrincipal IdentityPort.Actor a,@PathVariable String id){return service.order(a,id);}
 @GetMapping("/admin/orders")public Object all(@AuthenticationPrincipal IdentityPort.Actor a){return service.orders(a,true);}
 public record Payment(Boolean success){} public record Shipping(String carrier,String tracking){}
 @PostMapping("/orders/{id}/pay")public Object pay(@AuthenticationPrincipal IdentityPort.Actor a,@PathVariable String id,@RequestBody Payment v){if(v.success==null)throw com.example.petadoptioncommunity.web.Values.bad("请选择模拟结果");return service.action(a,id,"pay",null,null,v.success);}
 @PostMapping("/orders/{id}/cancel")public Object cancel(@AuthenticationPrincipal IdentityPort.Actor a,@PathVariable String id){return service.action(a,id,"cancel",null,null,false);}
 @PostMapping("/orders/{id}/receive")public Object receive(@AuthenticationPrincipal IdentityPort.Actor a,@PathVariable String id){return service.action(a,id,"receive",null,null,false);}
 @PostMapping("/admin/orders/{id}/ship")public Object ship(@AuthenticationPrincipal IdentityPort.Actor a,@PathVariable String id,@RequestBody Shipping v){return service.action(a,id,"ship",v.carrier,v.tracking,false);}
}
