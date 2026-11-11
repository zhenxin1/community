-- 在已选中的项目库执行：只读检查，不修改业务数据。
SELECT VERSION() AS mysql_version, DATABASE() AS selected_database, @@session.time_zone AS connection_time_zone;
SELECT table_name,table_comment FROM information_schema.tables WHERE table_schema=DATABASE() ORDER BY table_name;
SELECT table_name,constraint_name,constraint_type FROM information_schema.table_constraints WHERE table_schema=DATABASE() ORDER BY table_name,constraint_type;
-- 正常应为空：没有默认地址或默认数不为 1 的用户。
SELECT user_id,COUNT(*) AS address_count,SUM(is_default) AS default_count FROM user_address GROUP BY user_id HAVING SUM(is_default)<>1 OR COUNT(*)>20;
-- 正常应为空：订单明细合计与订单总额不一致。
SELECT o.id,o.total_cents,COALESCE(SUM(i.subtotal_cents),0) AS detail_total FROM shop_order o LEFT JOIN shop_order_item i ON i.order_id=o.id GROUP BY o.id,o.total_cents HAVING o.total_cents<>COALESCE(SUM(i.subtotal_cents),0);
SELECT role,COUNT(*) AS user_count FROM sys_user GROUP BY role;
