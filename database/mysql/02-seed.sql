-- 宠物领养社区精简版 V1.1，2026-11-11。MySQL >=8.0.17（校验环境 8.0.35）。
-- 在完整表结构建立后执行；初始化社区及商品分类，可重复执行，不创建固定账号。
SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;
SET SESSION time_zone = '+00:00';
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

START TRANSACTION;
INSERT INTO community_category (name,sort,enabled) VALUES ('养宠交流',10,1) ON DUPLICATE KEY UPDATE name=name;
INSERT INTO community_category (name,sort,enabled) VALUES ('宠物健康',20,1) ON DUPLICATE KEY UPDATE name=name;
INSERT INTO community_category (name,sort,enabled) VALUES ('成长日记',30,1) ON DUPLICATE KEY UPDATE name=name;
INSERT INTO community_category (name,sort,enabled) VALUES ('求助互助',40,1) ON DUPLICATE KEY UPDATE name=name;
INSERT INTO shop_category (name,sort,enabled) VALUES ('宠物食品',10,1) ON DUPLICATE KEY UPDATE name=name;
INSERT INTO shop_category (name,sort,enabled) VALUES ('日常用品',20,1) ON DUPLICATE KEY UPDATE name=name;
INSERT INTO shop_category (name,sort,enabled) VALUES ('玩具用品',30,1) ON DUPLICATE KEY UPDATE name=name;
INSERT INTO shop_category (name,sort,enabled) VALUES ('清洁护理',40,1) ON DUPLICATE KEY UPDATE name=name;
COMMIT;
