package com.example.petadoptioncommunity.shop;
import java.util.Map;import com.example.petadoptioncommunity.web.Values;
public final class Pricing {
 public static Map<String,Long> calculate(long subtotal){if(subtotal<0||subtotal>100000000000L)throw Values.bad("金额超出范围");long discount=subtotal>=150000?30000:subtotal>=60000?8000:subtotal>=30000?3000:0;long payable=((subtotal-discount)*80+50)/100;return Map.of("subtotal",subtotal,"discount",discount,"subsidy",subtotal-discount-payable,"payable",payable);}
}
