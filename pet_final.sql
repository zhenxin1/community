-- 寻爪宠物领养社区：MySQL 8.0.16+ 建库、建表与教学演示数据
-- 在新环境导入：mysql --default-character-set=utf8mb4 -u root -p < pet_final.sql
-- PowerShell 可先进入 mysql，再执行：SOURCE D:/Code/temp/final/pet_final.sql;
-- 数据库名 pet_final，与应用默认配置一致。时间使用 UTC，金额单位为分。
-- 本文件不删除数据库、不清空表、不修改已有账号密码或业务记录。
-- 演示数据仅在迁移表、账号表、商品表与宠物表均为空时载入；重复导入不重复插入。
-- 公开教学账号：管理员 admin / Admin123456
-- 发布者 linlin / User123456；买家 xiaoyu / User123456；另一申请人 anan / User123456。
-- 以上为本文件的公开演示凭据，不是现有安装环境的私人密码。
-- 不含登录会话、管理命令、通知、订单、真实联系方式或测试过程中产生的业务记录。

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;
SET time_zone = '+00:00';
CREATE DATABASE IF NOT EXISTS `pet_final` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE `pet_final`;

-- 一、表结构：与应用 V001—V004 迁移保持一致。
-- V001_identity.sql
CREATE TABLE IF NOT EXISTS schema_version (version INT PRIMARY KEY, checksum CHAR(64) NOT NULL, applied_at DATETIME(3) NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS e4_user (
 id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY,
 account VARCHAR(16) CHARACTER SET ascii COLLATE ascii_bin NOT NULL UNIQUE,
 password_hash VARCHAR(255) NOT NULL,
 role VARCHAR(5) NOT NULL CHECK(role IN ('USER','ADMIN')),
 status VARCHAR(6) NOT NULL CHECK(status IN ('ACTIVE','FROZEN')),
 nickname VARCHAR(30) NOT NULL, bio VARCHAR(200) NOT NULL DEFAULT '',
 profile_version BIGINT NOT NULL DEFAULT 0 CHECK(profile_version>=0),
 state_version BIGINT NOT NULL DEFAULT 0 CHECK(state_version>=0),
 auth_version BIGINT NOT NULL DEFAULT 0 CHECK(auth_version>=0),
 latest_reason VARCHAR(200), latest_action_at DATETIME(3), created_at DATETIME(3) NOT NULL,
 INDEX(created_at,id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS e4_session (
 token_hash BINARY(32) PRIMARY KEY,
 user_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 auth_version BIGINT NOT NULL, state_version BIGINT NOT NULL,
 expires_at DATETIME(3) NOT NULL, revoked_at DATETIME(3),
 FOREIGN KEY(user_id) REFERENCES e4_user(id), INDEX(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- V002_notifications.sql
CREATE TABLE IF NOT EXISTS e4_notification (
 id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY,
 recipient_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 title VARCHAR(60) NOT NULL, body VARCHAR(500) NOT NULL,
 type VARCHAR(14) NOT NULL CHECK(type IN ('STATUS_CHANGE','ADMIN_MESSAGE')),
 operation_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 actor_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 created_at DATETIME(3) NOT NULL, read_at DATETIME(3),
 FOREIGN KEY(recipient_id) REFERENCES e4_user(id), FOREIGN KEY(actor_id) REFERENCES e4_user(id),
 INDEX(recipient_id,created_at,id), INDEX(recipient_id,read_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- V003_commands.sql
CREATE TABLE IF NOT EXISTS e4_command (
 actor_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 operation_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 action VARCHAR(32) NOT NULL,
 target_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 payload_hash BINARY(32) NOT NULL,
 result_json JSON NOT NULL,
 created_at DATETIME(3) NOT NULL,
 PRIMARY KEY(actor_id,operation_id),
 FOREIGN KEY(actor_id) REFERENCES e4_user(id),
 FOREIGN KEY(target_id) REFERENCES e4_user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- V004_business.sql
CREATE TABLE IF NOT EXISTS pet (
 id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY,
 publisher_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 name VARCHAR(80) NOT NULL, category VARCHAR(3) NOT NULL, province VARCHAR(30) NOT NULL, region VARCHAR(120) NOT NULL, breed VARCHAR(80) NOT NULL,
 description VARCHAR(1000) NOT NULL, image VARCHAR(255) NOT NULL, phone VARCHAR(32) NOT NULL DEFAULT '', wechat VARCHAR(40) NOT NULL DEFAULT '', email VARCHAR(100) NOT NULL DEFAULT '',
 status VARCHAR(16) NOT NULL DEFAULT 'AVAILABLE', created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
 FOREIGN KEY(publisher_id) REFERENCES e4_user(id), INDEX(status,created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS adoption_application (
 id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY,
 pet_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, applicant_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 status VARCHAR(16) NOT NULL DEFAULT 'PENDING', publisher_confirmed BOOLEAN NOT NULL DEFAULT FALSE, applicant_confirmed BOOLEAN NOT NULL DEFAULT FALSE,
 created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
 FOREIGN KEY(pet_id) REFERENCES pet(id), FOREIGN KEY(applicant_id) REFERENCES e4_user(id), INDEX(pet_id,applicant_id,status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS adoption_result (
 pet_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY, application_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL UNIQUE,
 created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3), FOREIGN KEY(pet_id) REFERENCES pet(id), FOREIGN KEY(application_id) REFERENCES adoption_application(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS product (
 id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY, name VARCHAR(100) NOT NULL, category VARCHAR(40) NOT NULL, description VARCHAR(1000) NOT NULL,
 image VARCHAR(255) NOT NULL, price BIGINT NOT NULL CHECK(price>0), stock INT NOT NULL CHECK(stock>=0), listed BOOLEAN NOT NULL DEFAULT FALSE, recommended BOOLEAN NOT NULL DEFAULT FALSE,
 version BIGINT NOT NULL DEFAULT 0, created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS cart_item (
 user_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, product_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 quantity INT NOT NULL CHECK(quantity>0), selected BOOLEAN NOT NULL DEFAULT TRUE,
 PRIMARY KEY(user_id,product_id), FOREIGN KEY(user_id) REFERENCES e4_user(id), FOREIGN KEY(product_id) REFERENCES product(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS shipping_address (
 id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY, user_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 recipient VARCHAR(50) NOT NULL, phone VARCHAR(32) NOT NULL, address VARCHAR(300) NOT NULL, version BIGINT NOT NULL DEFAULT 0,
 FOREIGN KEY(user_id) REFERENCES e4_user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS shop_order (
 id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY, user_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 operation_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, fingerprint CHAR(64) NOT NULL,
 subtotal BIGINT NOT NULL, discount BIGINT NOT NULL, subsidy BIGINT NOT NULL, payable BIGINT NOT NULL,
 recipient VARCHAR(50) NOT NULL, phone VARCHAR(32) NOT NULL, address VARCHAR(300) NOT NULL,
 status VARCHAR(16) NOT NULL DEFAULT 'PENDING', carrier VARCHAR(50), tracking VARCHAR(80),
 created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3), paid_at DATETIME(3),
 FOREIGN KEY(user_id) REFERENCES e4_user(id), UNIQUE(user_id,operation_id), INDEX(user_id,created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS order_item (
 order_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, product_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 name VARCHAR(100) NOT NULL, image VARCHAR(255) NOT NULL, price BIGINT NOT NULL, quantity INT NOT NULL,
 PRIMARY KEY(order_id,product_id), FOREIGN KEY(order_id) REFERENCES shop_order(id), FOREIGN KEY(product_id) REFERENCES product(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 二、迁移记录及演示数据。SQL导入后可以直接通过应用的 SchemaGuard 校验。
SET @seed_demo = IF(
    (SELECT COUNT(*) FROM schema_version) = 0
    AND (SELECT COUNT(*) FROM e4_user) = 0
    AND (SELECT COUNT(*) FROM product) = 0
    AND (SELECT COUNT(*) FROM pet) = 0,
    1, 0
);
START TRANSACTION;
INSERT INTO schema_version (version,checksum,applied_at) SELECT 1,'d3d6c24919827c6eaf71ff06ade6264c189a23ccadaad5cd12951b2ffa2b5f13',UTC_TIMESTAMP(3) WHERE NOT EXISTS (SELECT 1 FROM schema_version WHERE version=1);
INSERT INTO schema_version (version,checksum,applied_at) SELECT 2,'124b52b3e833940ec4e936636df4ecaa79d4ae81b3cb0add51ef0ad4800fdf01',UTC_TIMESTAMP(3) WHERE NOT EXISTS (SELECT 1 FROM schema_version WHERE version=2);
INSERT INTO schema_version (version,checksum,applied_at) SELECT 3,'483806f7c71720408d0dedfad1dd79ff83992ae6ce8ed93431e5a68f7565db98',UTC_TIMESTAMP(3) WHERE NOT EXISTS (SELECT 1 FROM schema_version WHERE version=3);
INSERT INTO schema_version (version,checksum,applied_at) SELECT 4,'e62d9ecd66c57515b445935aca7b15b7b91e0eff606fb80219570fa7fb08561d',UTC_TIMESTAMP(3) WHERE NOT EXISTS (SELECT 1 FROM schema_version WHERE version=4);

-- 三、4个演示账号，密码以应用兼容的 PBKDF2-SHA256 哈希保存。
INSERT INTO e4_user (id,account,password_hash,role,status,nickname,bio,created_at) SELECT 'e2a6b706-e4f2-55ca-bd4b-70e351be7855','admin','{pbkdf2-sha256-i600000-s16-v1}81939e0b812f59e8713eefa8b373c30b4cb8a49d596b280d8c636059fd7baa72383418841fb2884d129ea5041bf12796','ADMIN','ACTIVE','管理员','教学演示账号',UTC_TIMESTAMP(3) WHERE @seed_demo=1;
INSERT INTO e4_user (id,account,password_hash,role,status,nickname,bio,created_at) SELECT '7dd14c88-aff1-5ad7-9d7e-96455688248f','linlin','{pbkdf2-sha256-i600000-s16-v1}19cb092921f6a86c012cdc9959a6ba363a8c8e464f58d092def97476f520af47254e120287209fc14f767f7fae120c15','USER','ACTIVE','林林','教学演示账号',UTC_TIMESTAMP(3) WHERE @seed_demo=1;
INSERT INTO e4_user (id,account,password_hash,role,status,nickname,bio,created_at) SELECT 'a2e10f41-8e28-5f47-9fd1-55f840aba989','xiaoyu','{pbkdf2-sha256-i600000-s16-v1}9031a560df677158b3b9aec91ded0af622d9e04573e06ffa9209f83ad9c7d532eb8fee25cf14a221efabdbe33870679b','USER','ACTIVE','小鱼','教学演示账号',UTC_TIMESTAMP(3) WHERE @seed_demo=1;
INSERT INTO e4_user (id,account,password_hash,role,status,nickname,bio,created_at) SELECT '9ac35905-7b33-5a1a-9db1-a2b3256be990','anan','{pbkdf2-sha256-i600000-s16-v1}cabe222bb967f77df5a4773bc752e3311faae9f6292a827e57840079723714706d786169da9476423e990fbc49eb4f79','USER','ACTIVE','安安','教学演示账号',UTC_TIMESTAMP(3) WHERE @seed_demo=1;

-- 四、6只待领养宠物。联系渠道为教学占位信息，图片均使用随项目提交的资源。
INSERT INTO pet (id,publisher_id,name,category,province,region,breed,description,image,phone,wechat,email,status) SELECT 'c17fc5cf-d850-5e7d-9857-79f8b80f8a9b','7dd14c88-aff1-5ad7-9d7e-96455688248f','芋圆','cat','湖北省','武汉市','中华田园猫','有一点慢热，也很喜欢靠着人睡觉。希望找到耐心、稳定的家庭。【教学演示资料】','/assets/taro.webp','','demo_contact_only','','AVAILABLE' WHERE @seed_demo=1;
INSERT INTO pet (id,publisher_id,name,category,province,region,breed,description,image,phone,wechat,email,status) SELECT '97849a72-33b1-529c-bbcd-e9dfaa7b509e','7dd14c88-aff1-5ad7-9d7e-96455688248f','芝麻','cat','浙江省','杭州市','中华田园猫','活泼好奇，喜欢窗边的阳光。请做好封窗与长期陪伴准备。【教学演示资料】','/assets/sesame.webp','','demo_contact_only','','AVAILABLE' WHERE @seed_demo=1;
INSERT INTO pet (id,publisher_id,name,category,province,region,breed,description,image,phone,wechat,email,status) SELECT '45045dee-46f5-5d45-8e1b-8a04cbcecc97','7dd14c88-aff1-5ad7-9d7e-96455688248f','麦芽','dog','江苏省','南京市','混种犬','温柔亲人，喜欢散步。希望你能每天留出陪伴和运动的时间。【教学演示资料】','/assets/malt.webp','','demo_contact_only','','AVAILABLE' WHERE @seed_demo=1;
INSERT INTO pet (id,publisher_id,name,category,province,region,breed,description,image,phone,wechat,email,status) SELECT 'b69c6e0e-a73a-52e5-9560-8a9437fb8ede','7dd14c88-aff1-5ad7-9d7e-96455688248f','云朵','cat','上海市','浦东新区','长毛猫','安静乖巧，需要定期梳毛和耐心照料。【教学演示资料】','/assets/cloud.webp','','demo_contact_only','','AVAILABLE' WHERE @seed_demo=1;
INSERT INTO pet (id,publisher_id,name,category,province,region,breed,description,image,phone,wechat,email,status) SELECT '3be972ab-5b46-587a-a034-03101c24e9e4','7dd14c88-aff1-5ad7-9d7e-96455688248f','栗子','cat','湖北省','武汉市','中华田园猫','对世界充满好奇，喜欢探索和奔跑。【教学演示资料】','/assets/chestnut.webp','','demo_contact_only','','AVAILABLE' WHERE @seed_demo=1;
INSERT INTO pet (id,publisher_id,name,category,province,region,breed,description,image,phone,wechat,email,status) SELECT 'f6ad02bd-abee-51d7-a642-662c61e08f7c','7dd14c88-aff1-5ad7-9d7e-96455688248f','豆豆','dog','四川省','成都市','混种犬','亲人爱玩，期待一个稳定温暖的家。【教学演示资料】','/assets/bean.webp','','demo_contact_only','','AVAILABLE' WHERE @seed_demo=1;

-- 五、14类28件商品：库存均为30，金额单位为分，前3类作为首页推荐。
INSERT INTO product (id,name,category,description,image,price,stock,listed,recommended,version) SELECT '0cb99994-639a-57da-a262-e9978bd45d02','均衡营养主粮 · 经典款','主粮','为日常陪伴准备的一份贴心选择。适用情况请在购买前认真核对。此为教学演示商品，不提供实际商品或医疗建议。','/assets/cat.webp',4900,30,TRUE,TRUE,0 WHERE @seed_demo=1;
INSERT INTO product (id,name,category,description,image,price,stock,listed,recommended,version) SELECT '7ae0e68b-aa61-5130-acea-7e5937037899','均衡营养主粮 · 轻享款','主粮','为日常陪伴准备的一份贴心选择。适用情况请在购买前认真核对。此为教学演示商品，不提供实际商品或医疗建议。','/assets/dog.webp',5900,30,TRUE,TRUE,0 WHERE @seed_demo=1;
INSERT INTO product (id,name,category,description,image,price,stock,listed,recommended,version) SELECT '98915877-eddf-5ab5-80ff-a58cfa341d0a','训练奖励小零食 · 经典款','零食','为日常陪伴准备的一份贴心选择。适用情况请在购买前认真核对。此为教学演示商品，不提供实际商品或医疗建议。','/assets/snack-1.svg',6000,30,TRUE,TRUE,0 WHERE @seed_demo=1;
INSERT INTO product (id,name,category,description,image,price,stock,listed,recommended,version) SELECT '9e9f2e61-ed18-54c9-80b5-c623a5655347','训练奖励小零食 · 轻享款','零食','为日常陪伴准备的一份贴心选择。适用情况请在购买前认真核对。此为教学演示商品，不提供实际商品或医疗建议。','/assets/snack-2.svg',7000,30,TRUE,TRUE,0 WHERE @seed_demo=1;
INSERT INTO product (id,name,category,description,image,price,stock,listed,recommended,version) SELECT 'dd432f61-321e-5656-9ee1-6f1c606fee6f','日常营养补充 · 经典款','营养保健品','为日常陪伴准备的一份贴心选择。适用情况请在购买前认真核对。此为教学演示商品，不提供实际商品或医疗建议。','/assets/nutrition-1.svg',7100,30,TRUE,TRUE,0 WHERE @seed_demo=1;
INSERT INTO product (id,name,category,description,image,price,stock,listed,recommended,version) SELECT '40ad1c06-5fc9-51ee-8fcd-35dd702939fc','日常营养补充 · 轻享款','营养保健品','为日常陪伴准备的一份贴心选择。适用情况请在购买前认真核对。此为教学演示商品，不提供实际商品或医疗建议。','/assets/nutrition-2.svg',8100,30,TRUE,TRUE,0 WHERE @seed_demo=1;
INSERT INTO product (id,name,category,description,image,price,stock,listed,recommended,version) SELECT 'e4736db2-fe3d-520e-b482-36edd592a81e','易清洁宠物食盆 · 经典款','食具','为日常陪伴准备的一份贴心选择。适用情况请在购买前认真核对。此为教学演示商品，不提供实际商品或医疗建议。','/assets/bowl-1.svg',8200,30,TRUE,FALSE,0 WHERE @seed_demo=1;
INSERT INTO product (id,name,category,description,image,price,stock,listed,recommended,version) SELECT '63514586-789a-54e6-9349-e35a33201f74','易清洁宠物食盆 · 轻享款','食具','为日常陪伴准备的一份贴心选择。适用情况请在购买前认真核对。此为教学演示商品，不提供实际商品或医疗建议。','/assets/bowl-2.svg',9200,30,TRUE,FALSE,0 WHERE @seed_demo=1;
INSERT INTO product (id,name,category,description,image,price,stock,listed,recommended,version) SELECT 'e6349439-6442-5c15-b8db-dd9bc303cc94','柔软舒适睡垫 · 经典款','窝垫','为日常陪伴准备的一份贴心选择。适用情况请在购买前认真核对。此为教学演示商品，不提供实际商品或医疗建议。','/assets/bed-1.svg',9300,30,TRUE,FALSE,0 WHERE @seed_demo=1;
INSERT INTO product (id,name,category,description,image,price,stock,listed,recommended,version) SELECT 'bd535a5f-e64a-5ed4-82ce-9e6688630593','柔软舒适睡垫 · 轻享款','窝垫','为日常陪伴准备的一份贴心选择。适用情况请在购买前认真核对。此为教学演示商品，不提供实际商品或医疗建议。','/assets/bed-2.svg',10300,30,TRUE,FALSE,0 WHERE @seed_demo=1;
INSERT INTO product (id,name,category,description,image,price,stock,listed,recommended,version) SELECT 'ebfa39f8-87f0-5619-9cc3-1996b32b5020','家用宠物围栏 · 经典款','围栏','为日常陪伴准备的一份贴心选择。适用情况请在购买前认真核对。此为教学演示商品，不提供实际商品或医疗建议。','/assets/fence-1.svg',10400,30,TRUE,FALSE,0 WHERE @seed_demo=1;
INSERT INTO product (id,name,category,description,image,price,stock,listed,recommended,version) SELECT '64d8d3e7-261f-544d-ac0e-f593ed216012','家用宠物围栏 · 轻享款','围栏','为日常陪伴准备的一份贴心选择。适用情况请在购买前认真核对。此为教学演示商品，不提供实际商品或医疗建议。','/assets/fence-2.svg',11400,30,TRUE,FALSE,0 WHERE @seed_demo=1;
INSERT INTO product (id,name,category,description,image,price,stock,listed,recommended,version) SELECT '35fff488-8117-55ab-ac3b-dfda3e6dee0e','宠物家居小物 · 经典款','环境用品','为日常陪伴准备的一份贴心选择。适用情况请在购买前认真核对。此为教学演示商品，不提供实际商品或医疗建议。','/assets/environment-1.svg',11500,30,TRUE,FALSE,0 WHERE @seed_demo=1;
INSERT INTO product (id,name,category,description,image,price,stock,listed,recommended,version) SELECT '2255642e-96e5-5abc-8fb8-d5c723ebb3fd','宠物家居小物 · 轻享款','环境用品','为日常陪伴准备的一份贴心选择。适用情况请在购买前认真核对。此为教学演示商品，不提供实际商品或医疗建议。','/assets/environment-2.svg',12500,30,TRUE,FALSE,0 WHERE @seed_demo=1;
INSERT INTO product (id,name,category,description,image,price,stock,listed,recommended,version) SELECT '1d771b97-09c3-5163-a515-975b0c6d993b','温和宠物洗护 · 经典款','洗护','为日常陪伴准备的一份贴心选择。适用情况请在购买前认真核对。此为教学演示商品，不提供实际商品或医疗建议。','/assets/wash-1.svg',12600,30,TRUE,FALSE,0 WHERE @seed_demo=1;
INSERT INTO product (id,name,category,description,image,price,stock,listed,recommended,version) SELECT 'd1d69aac-4142-576d-a24c-0157f2fc3a2c','温和宠物洗护 · 轻享款','洗护','为日常陪伴准备的一份贴心选择。适用情况请在购买前认真核对。此为教学演示商品，不提供实际商品或医疗建议。','/assets/wash-2.svg',13600,30,TRUE,FALSE,0 WHERE @seed_demo=1;
INSERT INTO product (id,name,category,description,image,price,stock,listed,recommended,version) SELECT 'f6e87391-b85e-5037-b0a5-538851bb31ac','日常梳毛工具 · 经典款','工具','为日常陪伴准备的一份贴心选择。适用情况请在购买前认真核对。此为教学演示商品，不提供实际商品或医疗建议。','/assets/brush-1.svg',13700,30,TRUE,FALSE,0 WHERE @seed_demo=1;
INSERT INTO product (id,name,category,description,image,price,stock,listed,recommended,version) SELECT '50d3b074-ae7b-59ca-a5a4-f50b69b67570','日常梳毛工具 · 轻享款','工具','为日常陪伴准备的一份贴心选择。适用情况请在购买前认真核对。此为教学演示商品，不提供实际商品或医疗建议。','/assets/brush-2.svg',14700,30,TRUE,FALSE,0 WHERE @seed_demo=1;
INSERT INTO product (id,name,category,description,image,price,stock,listed,recommended,version) SELECT 'dab42af6-dd27-50df-b332-7f81fe4cd969','宠物环境清洁 · 经典款','除味消毒','为日常陪伴准备的一份贴心选择。适用情况请在购买前认真核对。此为教学演示商品，不提供实际商品或医疗建议。','/assets/clean-1.svg',14800,30,TRUE,FALSE,0 WHERE @seed_demo=1;
INSERT INTO product (id,name,category,description,image,price,stock,listed,recommended,version) SELECT '92814868-1221-54f4-b5e7-a934a22ae2d6','宠物环境清洁 · 轻享款','除味消毒','为日常陪伴准备的一份贴心选择。适用情况请在购买前认真核对。此为教学演示商品，不提供实际商品或医疗建议。','/assets/clean-2.svg',15800,30,TRUE,FALSE,0 WHERE @seed_demo=1;
INSERT INTO product (id,name,category,description,image,price,stock,listed,recommended,version) SELECT '020d4b76-920d-5939-a7e8-dba939ec5265','日常出行牵引 · 经典款','牵引','为日常陪伴准备的一份贴心选择。适用情况请在购买前认真核对。此为教学演示商品，不提供实际商品或医疗建议。','/assets/leash-1.svg',15900,30,TRUE,FALSE,0 WHERE @seed_demo=1;
INSERT INTO product (id,name,category,description,image,price,stock,listed,recommended,version) SELECT '197ab91a-e165-5814-a31d-013f65c752ce','日常出行牵引 · 轻享款','牵引','为日常陪伴准备的一份贴心选择。适用情况请在购买前认真核对。此为教学演示商品，不提供实际商品或医疗建议。','/assets/leash-2.svg',16900,30,TRUE,FALSE,0 WHERE @seed_demo=1;
INSERT INTO product (id,name,category,description,image,price,stock,listed,recommended,version) SELECT 'f5bc1d80-084a-5dbc-95a0-d35de6d8afc6','互动陪伴玩具 · 经典款','玩具','为日常陪伴准备的一份贴心选择。适用情况请在购买前认真核对。此为教学演示商品，不提供实际商品或医疗建议。','/assets/toy-1.svg',17000,30,TRUE,FALSE,0 WHERE @seed_demo=1;
INSERT INTO product (id,name,category,description,image,price,stock,listed,recommended,version) SELECT '9aef33f3-6aea-5b32-a3f5-e47dda2a83cd','互动陪伴玩具 · 轻享款','玩具','为日常陪伴准备的一份贴心选择。适用情况请在购买前认真核对。此为教学演示商品，不提供实际商品或医疗建议。','/assets/toy-2.svg',18000,30,TRUE,FALSE,0 WHERE @seed_demo=1;
INSERT INTO product (id,name,category,description,image,price,stock,listed,recommended,version) SELECT 'd8589154-28d5-5cb1-b91f-277d1d0bc28a','舒适宠物衣物 · 经典款','服饰','为日常陪伴准备的一份贴心选择。适用情况请在购买前认真核对。此为教学演示商品，不提供实际商品或医疗建议。','/assets/clothes-1.svg',18100,30,TRUE,FALSE,0 WHERE @seed_demo=1;
INSERT INTO product (id,name,category,description,image,price,stock,listed,recommended,version) SELECT '9e2628a7-1bf4-550d-94dd-620a11fb885b','舒适宠物衣物 · 轻享款','服饰','为日常陪伴准备的一份贴心选择。适用情况请在购买前认真核对。此为教学演示商品，不提供实际商品或医疗建议。','/assets/clothes-2.svg',19100,30,TRUE,FALSE,0 WHERE @seed_demo=1;
INSERT INTO product (id,name,category,description,image,price,stock,listed,recommended,version) SELECT 'cfe9d65c-c3cc-56d7-aef6-f839650e034a','日常护理用品 · 经典款','驱虫护理','为日常陪伴准备的一份贴心选择。适用情况请在购买前认真核对。此为教学演示商品，不提供实际商品或医疗建议。','/assets/care-1.svg',19200,30,TRUE,FALSE,0 WHERE @seed_demo=1;
INSERT INTO product (id,name,category,description,image,price,stock,listed,recommended,version) SELECT '57ea6fe0-9725-5754-a5e2-6570ceb14ee9','日常护理用品 · 轻享款','驱虫护理','为日常陪伴准备的一份贴心选择。适用情况请在购买前认真核对。此为教学演示商品，不提供实际商品或医疗建议。','/assets/care-2.svg',20200,30,TRUE,FALSE,0 WHERE @seed_demo=1;

-- 六、教学收货地址。可通过页面修改；不含真实姓名、电话或地址。
INSERT INTO shipping_address (id,user_id,recipient,phone,address,version) SELECT '15c89d65-9d7a-574c-9abb-76641eed7ae4','a2e10f41-8e28-5f47-9fd1-55f840aba989','演示买家甲','demo-phone','教学演示地址，仅供课程测试，不提供实际配送',0 WHERE @seed_demo=1;
INSERT INTO shipping_address (id,user_id,recipient,phone,address,version) SELECT '32aaaaa3-243c-54a0-81d8-8cb1ed4ba287','9ac35905-7b33-5a1a-9db1-a2b3256be990','演示买家乙','demo-phone','教学演示地址，仅供课程测试，不提供实际配送',0 WHERE @seed_demo=1;

COMMIT;

-- 导入结果检查。
SELECT 'schema_version' AS table_name, COUNT(*) AS row_count FROM schema_version
UNION ALL SELECT 'e4_user', COUNT(*) FROM e4_user
UNION ALL SELECT 'pet', COUNT(*) FROM pet
UNION ALL SELECT 'product', COUNT(*) FROM product
UNION ALL SELECT 'shipping_address', COUNT(*) FROM shipping_address;
