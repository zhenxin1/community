-- 宠物领养社区：精简版 V1.1。新建空库用；不会覆盖已有表。
-- MySQL >=8.0.17（JSON 默认表达式及 CHECK）；验证环境 8.0.35。
SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;
SET SESSION time_zone = '+00:00';
CREATE TABLE `sys_user` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键，自增，接口输出十进制字符串',
  `username` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '小写账号，唯一',
  `password_hash` VARCHAR(255) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '带算法标识的单向密码哈希，绝不返回接口',
  `nickname` VARCHAR(24) NOT NULL COMMENT '昵称',
  `avatar_media_id` BIGINT NULL DEFAULT NULL COMMENT '头像媒体 ID，未设置为 NULL',
  `phone` VARCHAR(32) NOT NULL DEFAULT '' COMMENT '联系方式，可为空字符串',
  `location` VARCHAR(100) NOT NULL DEFAULT '' COMMENT '所在地，可为空字符串',
  `status` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'ACTIVE' COMMENT '账号状态：ACTIVE/FROZEN',
  `must_change_password` TINYINT NOT NULL DEFAULT 0 COMMENT '管理员重置后是否必须修改密码',
  `auth_version` INT NOT NULL DEFAULT 0 COMMENT '会话认证版本，冻结或改密时递增',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁，业务修改时由 Service 显式加 1',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间，UTC',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '更新时间，UTC，由 Service 显式维护',
  `role` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'USER' COMMENT '身份：USER 普通用户，ADMIN 管理员',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_username` (`username`),
  KEY `idx_user_status_created` (`status`, `created_at`, `id`),
  KEY `idx_user_role_status` (`role`, `status`, `id`),
  CONSTRAINT `ck_sys_user_1` CHECK (REGEXP_LIKE(`username`, '^[a-z0-9_]{3,24}$', 'c')),
  CONSTRAINT `ck_sys_user_2` CHECK (CHAR_LENGTH(`nickname`) BETWEEN 1 AND 24),
  CONSTRAINT `ck_sys_user_3` CHECK (`auth_version` >= 0),
  CONSTRAINT `ck_sys_user_4` CHECK (`status` IN ('ACTIVE', 'FROZEN')),
  CONSTRAINT `ck_sys_user_5` CHECK (`must_change_password` IN (0,1)),
  CONSTRAINT `ck_sys_user_6` CHECK (`version` >= 0),
  CONSTRAINT `ck_sys_user_7` CHECK (`role` IN ('USER','ADMIN'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='用户账号与资料';

CREATE TABLE `media_file` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键，自增，接口输出十进制字符串',
  `owner_id` BIGINT NOT NULL COMMENT '上传者 ID',
  `business_type` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'AVATAR' COMMENT '业务用途：AVATAR/PET/POST/DIARY/HELP/PRODUCT',
  `business_id` BIGINT NULL DEFAULT NULL COMMENT '绑定业务 ID；未绑定为 NULL',
  `sort_order` SMALLINT NULL DEFAULT NULL COMMENT '资源内展示顺序，头像 0，其余 1–9',
  `storage_key` VARCHAR(255) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '文件存储相对键，不返回磁盘路径',
  `original_name` VARCHAR(255) NOT NULL COMMENT '原文件名，仅供管理内部使用',
  `mime_type` VARCHAR(80) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '经文件特征校验后的 MIME',
  `size_bytes` BIGINT NOT NULL COMMENT '文件字节数',
  `status` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'TEMP' COMMENT '生命周期：TEMP/BOUND/DELETED',
  `active_business_id` BIGINT GENERATED ALWAYS AS (CASE WHEN `status`='BOUND' THEN `business_id` ELSE NULL END) STORED COMMENT '仅有效绑定参与展示位置唯一约束',
  `cleanup_after` DATETIME(3) NULL DEFAULT NULL COMMENT '允许清理文件的 UTC 时间；有效绑定为空',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间，UTC',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '更新时间，UTC，由 Service 显式维护',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_media_storage_key` (`storage_key`),
  UNIQUE KEY `uk_media_bound_sort` (`business_type`, `active_business_id`, `sort_order`),
  KEY `idx_media_owner` (`owner_id`, `status`, `created_at`),
  KEY `idx_media_cleanup` (`status`, `cleanup_after`, `id`),
  CONSTRAINT `ck_media_file_1` CHECK (`business_type` IN ('AVATAR', 'PET', 'POST', 'DIARY', 'HELP', 'PRODUCT')),
  CONSTRAINT `ck_media_file_2` CHECK (`status` IN ('TEMP', 'BOUND', 'DELETED')),
  CONSTRAINT `ck_media_file_3` CHECK ((`status`='TEMP' AND `business_id` IS NULL AND `sort_order` IS NULL) OR (`status`='BOUND' AND `business_id` IS NOT NULL AND `sort_order` IS NOT NULL) OR `status`='DELETED'),
  CONSTRAINT `ck_media_file_4` CHECK (`sort_order` IS NULL OR (`business_type`='AVATAR' AND `sort_order`=0) OR (`business_type`<>'AVATAR' AND `sort_order` BETWEEN 1 AND 9)),
  CONSTRAINT `ck_media_file_5` CHECK ((`mime_type` IN ('image/jpeg','image/png','image/webp','image/gif') AND `size_bytes` BETWEEN 1 AND 5242880) OR (`business_type` NOT IN ('AVATAR','PRODUCT') AND `mime_type` IN ('video/mp4','video/webm') AND `size_bytes` BETWEEN 1 AND 20971520))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='文件元信息与业务绑定';
ALTER TABLE `media_file` ADD CONSTRAINT `fk_media_file_1` FOREIGN KEY (`owner_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
