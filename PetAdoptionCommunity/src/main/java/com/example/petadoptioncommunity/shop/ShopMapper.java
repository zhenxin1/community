package com.example.petadoptioncommunity.shop;
import org.apache.ibatis.annotations.*;import java.util.*;
@Mapper public interface ShopMapper {
 @Select("SELECT * FROM product ORDER BY created_at DESC,id")List<Map<String,Object>> products();
 @Select("SELECT * FROM product WHERE id=#{id}")Map<String,Object> product(String id);
 @Select("SELECT * FROM product WHERE id=#{id} FOR UPDATE")Map<String,Object> lockProduct(String id);
 @Insert("INSERT INTO product(id,name,category,description,image,price,stock,listed,recommended) VALUES(#{id},#{name},#{category},#{description},#{image},#{price},#{stock},#{listed},#{recommended})")void insertProduct(Map<String,Object> p);
 @Update("UPDATE product SET name=#{name},category=#{category},description=#{description},image=#{image},price=#{price},stock=#{stock},listed=#{listed},recommended=#{recommended},version=version+1 WHERE id=#{id} AND version=#{version}")int updateProduct(Map<String,Object> p);
 @Update("UPDATE product SET stock=stock-#{quantity},version=version+1 WHERE id=#{id} AND stock>=#{quantity}")int deduct(@Param("id")String id,@Param("quantity")int quantity);
 @Select("SELECT c.*,p.name,p.image,p.price,p.stock,p.listed,p.version product_version FROM cart_item c JOIN product p ON c.product_id=p.id WHERE c.user_id=#{id} ORDER BY c.product_id")List<Map<String,Object>> cart(String id);
 @Insert("INSERT INTO cart_item(user_id,product_id,quantity,selected) VALUES(#{userId},#{id},#{quantity},#{selected}) ON DUPLICATE KEY UPDATE quantity=#{quantity},selected=#{selected}")void cartSet(@Param("userId")String userId,@Param("id")String id,@Param("quantity")int quantity,@Param("selected")boolean selected);
 @Delete("DELETE FROM cart_item WHERE user_id=#{userId} AND product_id=#{id}")void cartDelete(@Param("userId")String userId,@Param("id")String id);
 @Select("SELECT * FROM shipping_address WHERE user_id=#{id} ORDER BY id")List<Map<String,Object>> addresses(String id);
 @Select("SELECT * FROM shipping_address WHERE id=#{id}")Map<String,Object> address(String id);
 @Insert("INSERT INTO shipping_address(id,user_id,recipient,phone,address) VALUES(#{id},#{userId},#{recipient},#{phone},#{address})")void insertAddress(Map<String,Object> p);
 @Update("UPDATE shipping_address SET recipient=#{recipient},phone=#{phone},address=#{address},version=version+1 WHERE id=#{id} AND user_id=#{userId} AND version=#{version}")int updateAddress(Map<String,Object> p);
 @Insert("INSERT INTO shop_order(id,user_id,operation_id,fingerprint,subtotal,discount,subsidy,payable,recipient,phone,address) VALUES(#{id},#{userId},#{operationId},#{fingerprint},#{subtotal},#{discount},#{subsidy},#{payable},#{recipient},#{phone},#{address})")void insertOrder(Map<String,Object> p);
 @Insert("INSERT INTO order_item(order_id,product_id,name,image,price,quantity) VALUES(#{orderId},#{productId},#{name},#{image},#{price},#{quantity})")void insertItem(Map<String,Object> p);
 @Select("SELECT * FROM shop_order WHERE user_id=#{userId} AND operation_id=#{operationId}")Map<String,Object> operation(@Param("userId")String userId,@Param("operationId")String operationId);
 @Select("SELECT * FROM shop_order WHERE id=#{id}")Map<String,Object> order(String id);
 @Select("SELECT * FROM shop_order WHERE id=#{id} FOR UPDATE")Map<String,Object> lockOrder(String id);
 @Select("SELECT * FROM shop_order WHERE user_id=#{id} ORDER BY created_at DESC,id")List<Map<String,Object>> orders(String id);
 @Select("SELECT * FROM shop_order ORDER BY created_at DESC,id")List<Map<String,Object>> allOrders();
 @Select("SELECT * FROM order_item WHERE order_id=#{id} ORDER BY product_id")List<Map<String,Object>> items(String id);
 @Update("UPDATE shop_order SET status=#{status},paid_at=CASE WHEN #{status}='PAID' THEN UTC_TIMESTAMP(3) ELSE paid_at END WHERE id=#{id}")void orderState(@Param("id")String id,@Param("status")String status);
 @Update("UPDATE shop_order SET status='SHIPPED',carrier=#{carrier},tracking=#{tracking} WHERE id=#{id}")void ship(@Param("id")String id,@Param("carrier")String carrier,@Param("tracking")String tracking);
}
