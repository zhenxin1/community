-- 002：将精简版账号库（sys_user、media_file）补齐为完整 25 表。
-- 执行前备份；选择 pet_community。仅在其他 23 张业务表都尚未创建时执行一次。
-- 保留原有账号、密码哈希、个人资料、头像元数据；不 ALTER/UPDATE/DELETE 原有两张表。
-- 已完整建库时不要重跑此文件；后续修改使用新的编号迁移。
SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;
SET SESSION time_zone = '+00:00';
CREATE TABLE `user_notice` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键，自增，接口输出十进制字符串',
  `recipient_id` BIGINT NULL DEFAULT NULL COMMENT '收件人',
  `title` VARCHAR(100) NOT NULL COMMENT '标题',
  `content` TEXT NOT NULL COMMENT '接收人可见的摘要正文',
  `business_type` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'ADOPTION' COMMENT '业务类型：ADOPTION/COMMENT/ORDER/REFUND/REPORT/SYSTEM',
  `business_id` BIGINT NULL DEFAULT NULL COMMENT '关联业务 ID，平台公告为 NULL',
  `broadcast_id` BIGINT NULL DEFAULT NULL COMMENT '群发主记录 ID，普通业务消息为空',
  `is_read` TINYINT NOT NULL DEFAULT 0 COMMENT '是否已读',
  `read_at` DATETIME(3) NULL DEFAULT NULL COMMENT '已读时间',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间，UTC',
  `is_broadcast` TINYINT NOT NULL DEFAULT 0 COMMENT '1 群发主记录；0 实际收件消息',
  `target_type` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NULL DEFAULT NULL COMMENT '群发范围，仅群发主记录填写',
  `recipient_count` INT NOT NULL DEFAULT 0 COMMENT '群发主记录的实际收件人数；普通消息为 0',
  `created_by` BIGINT NULL DEFAULT NULL COMMENT '群发管理员；普通业务消息为空',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_notice_broadcast_recipient` (`broadcast_id`, `recipient_id`),
  KEY `idx_notice_recipient_read` (`recipient_id`, `is_read`, `created_at`, `id`),
  KEY `idx_notice_recipient_created` (`recipient_id`, `created_at`, `id`),
  KEY `idx_notice_recipient_type` (`recipient_id`, `business_type`, `created_at`, `id`),
  KEY `idx_notice_broadcast` (`is_broadcast`, `created_at`, `id`),
  CONSTRAINT `ck_user_notice_1` CHECK (`business_type` IN ('ADOPTION', 'COMMENT', 'ORDER', 'REFUND', 'REPORT', 'SYSTEM')),
  CONSTRAINT `ck_user_notice_2` CHECK ((`is_read`=0 AND `read_at` IS NULL) OR (`is_read`=1 AND `read_at` IS NOT NULL)),
  CONSTRAINT `ck_user_notice_3` CHECK (`is_read` IN (0,1)),
  CONSTRAINT `ck_user_notice_4` CHECK (`is_broadcast` IN (0,1)),
  CONSTRAINT `ck_user_notice_5` CHECK (`recipient_count`>=0),
  CONSTRAINT `ck_user_notice_6` CHECK ((`is_broadcast`=1 AND `recipient_id` IS NULL AND `broadcast_id` IS NULL AND `created_by` IS NOT NULL AND `target_type` IS NOT NULL AND `target_type` IN ('ALL','USERS') AND `business_type`='SYSTEM' AND `is_read`=0) OR (`is_broadcast`=0 AND `recipient_id` IS NOT NULL AND `target_type` IS NULL AND `created_by` IS NULL AND `recipient_count`=0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='用户站内消息';
CREATE TABLE `user_favorite` (
  `user_id` BIGINT NOT NULL COMMENT '用户 ID',
  `target_type` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'PET' COMMENT '收藏对象：PET/POST',
  `target_id` BIGINT NOT NULL COMMENT '对象 ID',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间，UTC',
  PRIMARY KEY (`user_id`, `target_type`, `target_id`),
  KEY `idx_favorite_user_created` (`user_id`, `created_at`, `target_type`, `target_id`),
  KEY `idx_favorite_target` (`target_type`, `target_id`),
  CONSTRAINT `ck_user_favorite_1` CHECK (`target_type` IN ('PET', 'POST')),
  CONSTRAINT `ck_user_favorite_2` CHECK (`target_id` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='宠物与社区收藏';
CREATE TABLE `api_idempotency` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键，自增，接口输出十进制字符串',
  `user_id` BIGINT NOT NULL COMMENT '用户 ID',
  `http_method` VARCHAR(8) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT 'HTTP 方法',
  `request_path` VARCHAR(255) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '包含实际 ID 的规范请求路径',
  `idempotency_key` CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '客户端 UUID',
  `request_hash` BINARY(32) NOT NULL COMMENT '规范化请求 SHA-256 摘要，包含请求体和有业务含义的查询参数',
  `state` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'PROCESSING' COMMENT '执行状态：PROCESSING/SUCCEEDED',
  `http_status` INT NULL DEFAULT NULL COMMENT '成功响应 HTTP 状态',
  `response_ciphertext` MEDIUMBLOB NULL DEFAULT NULL COMMENT '成功响应加密字节，含 nonce 与认证标签；PROCESSING 为空',
  `encryption_key_id` VARCHAR(80) CHARACTER SET ascii COLLATE ascii_bin NULL DEFAULT NULL COMMENT '应用侧加密密钥版本标识',
  `expires_at` DATETIME(3) NOT NULL COMMENT '24 小时幂等缓存到期时间',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间，UTC',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '更新时间，UTC，由 Service 显式维护',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_idem_scope` (`user_id`, `http_method`, `request_path`, `idempotency_key`),
  KEY `idx_idem_expiry` (`expires_at`, `id`),
  CONSTRAINT `ck_api_idempotency_1` CHECK (`state` IN ('PROCESSING', 'SUCCEEDED')),
  CONSTRAINT `ck_api_idempotency_2` CHECK ((`state`='PROCESSING' AND `http_status` IS NULL AND `response_ciphertext` IS NULL AND `encryption_key_id` IS NULL) OR (`state`='SUCCEEDED' AND `http_status` IS NOT NULL AND `http_status`=200 AND `response_ciphertext` IS NOT NULL AND `encryption_key_id` IS NOT NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='幂等请求记录';
CREATE TABLE `operation_log` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键，自增，接口输出十进制字符串',
  `operator_id` BIGINT NOT NULL COMMENT '操作管理员',
  `operation` VARCHAR(80) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '固定操作编码',
  `target_type` VARCHAR(40) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '对象类型',
  `target_id` BIGINT NULL DEFAULT NULL COMMENT '对象 ID，可为空',
  `reason` VARCHAR(2000) NOT NULL COMMENT '不含秘密和私人正文的安全操作说明',
  `result` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'SUCCESS' COMMENT '执行结果：SUCCESS/FAILURE',
  `request_id` VARCHAR(80) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '链路追踪号',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间，UTC',
  PRIMARY KEY (`id`),
  KEY `idx_log_created` (`created_at`, `id`),
  KEY `idx_log_operator` (`operator_id`, `created_at`, `id`),
  KEY `idx_log_target` (`target_type`, `target_id`, `created_at`, `id`),
  KEY `idx_log_request` (`request_id`),
  CONSTRAINT `ck_operation_log_1` CHECK (`result` IN ('SUCCESS', 'FAILURE'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='管理员操作日志';
CREATE TABLE `adoption_pet` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键，自增，接口输出十进制字符串',
  `publisher_id` BIGINT NOT NULL COMMENT '发布者',
  `name` VARCHAR(60) NOT NULL COMMENT '宠物名',
  `species` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'CAT' COMMENT '种类：CAT/DOG/OTHER',
  `breed` VARCHAR(60) NOT NULL DEFAULT '' COMMENT '品种',
  `age_months` INT NOT NULL COMMENT '月龄',
  `sex` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'MALE' COMMENT '性别：MALE/FEMALE/UNKNOWN',
  `weight_grams` INT NOT NULL COMMENT '体重克',
  `location` VARCHAR(100) NOT NULL COMMENT '所在地',
  `health` VARCHAR(1000) NOT NULL COMMENT '健康状况',
  `personality` VARCHAR(1000) NOT NULL COMMENT '性格',
  `habits` VARCHAR(1000) NOT NULL DEFAULT '' COMMENT '习惯',
  `medical_history` VARCHAR(1000) NOT NULL DEFAULT '' COMMENT '病史',
  `adoption_requirements` VARCHAR(2000) NOT NULL COMMENT '领养条件',
  `review_status` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'DRAFT' COMMENT '发布审核状态：DRAFT/PENDING/PUBLISHED/REJECTED/OFF_SHELF',
  `adoption_status` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'AVAILABLE' COMMENT '领养状态：AVAILABLE/RESERVED/ADOPTED',
  `review_reason` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '最新审核或下架说明',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁，业务修改时由 Service 显式加 1',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间，UTC',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '更新时间，UTC，由 Service 显式维护',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_pet_id_publisher` (`id`, `publisher_id`),
  KEY `idx_pet_public` (`review_status`, `adoption_status`, `created_at`, `id`),
  KEY `idx_pet_species_age` (`review_status`, `species`, `age_months`, `id`),
  KEY `idx_pet_publisher` (`publisher_id`, `review_status`, `created_at`, `id`),
  CONSTRAINT `ck_adoption_pet_1` CHECK (`species` IN ('CAT', 'DOG', 'OTHER')),
  CONSTRAINT `ck_adoption_pet_2` CHECK (`sex` IN ('MALE', 'FEMALE', 'UNKNOWN')),
  CONSTRAINT `ck_adoption_pet_3` CHECK (`review_status` IN ('DRAFT', 'PENDING', 'PUBLISHED', 'REJECTED', 'OFF_SHELF')),
  CONSTRAINT `ck_adoption_pet_4` CHECK (`adoption_status` IN ('AVAILABLE', 'RESERVED', 'ADOPTED')),
  CONSTRAINT `ck_adoption_pet_5` CHECK (`age_months` BETWEEN 0 AND 600),
  CONSTRAINT `ck_adoption_pet_6` CHECK (`weight_grams` BETWEEN 1 AND 500000),
  CONSTRAINT `ck_adoption_pet_7` CHECK (`version` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='宠物档案与发布';
CREATE TABLE `adoption_need` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键，自增，接口输出十进制字符串',
  `user_id` BIGINT NOT NULL COMMENT '用户 ID',
  `species` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'CAT' COMMENT '希望种类：CAT/DOG/OTHER',
  `sex` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'ANY' COMMENT '性别偏好：ANY/MALE/FEMALE',
  `min_age_months` INT NOT NULL COMMENT '月龄下界',
  `max_age_months` INT NOT NULL COMMENT '月龄上界',
  `location` VARCHAR(100) NOT NULL COMMENT '所在地偏好',
  `description` VARCHAR(2000) NOT NULL COMMENT '需求和饲养说明',
  `expires_at` DATETIME(3) NOT NULL COMMENT '有效截止时间',
  `status` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'ACTIVE' COMMENT '需求状态：ACTIVE/EXPIRED/CLOSED',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁，业务修改时由 Service 显式加 1',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间，UTC',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '更新时间，UTC，由 Service 显式维护',
  PRIMARY KEY (`id`),
  KEY `idx_need_user` (`user_id`, `status`, `created_at`, `id`),
  KEY `idx_need_expire` (`status`, `expires_at`, `id`),
  KEY `idx_need_public` (`status`, `species`, `created_at`, `id`),
  CONSTRAINT `ck_adoption_need_1` CHECK (`species` IN ('CAT', 'DOG', 'OTHER')),
  CONSTRAINT `ck_adoption_need_2` CHECK (`sex` IN ('ANY', 'MALE', 'FEMALE')),
  CONSTRAINT `ck_adoption_need_3` CHECK (`status` IN ('ACTIVE', 'EXPIRED', 'CLOSED')),
  CONSTRAINT `ck_adoption_need_4` CHECK (`min_age_months` BETWEEN 0 AND 600),
  CONSTRAINT `ck_adoption_need_5` CHECK (`max_age_months` BETWEEN `min_age_months` AND 600),
  CONSTRAINT `ck_adoption_need_6` CHECK (`version` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='领养需求与偏好';
CREATE TABLE `adoption_application` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键，自增，接口输出十进制字符串',
  `pet_id` BIGINT NOT NULL COMMENT '申请宠物',
  `applicant_id` BIGINT NOT NULL COMMENT '申请人',
  `publisher_id` BIGINT NOT NULL COMMENT '发布者，保存不可变关联',
  `housing` VARCHAR(1000) NOT NULL COMMENT '住房条件',
  `experience` VARCHAR(1000) NOT NULL COMMENT '养宠经验',
  `reason` VARCHAR(1000) NOT NULL COMMENT '申请说明',
  `contact_phone` VARCHAR(32) NOT NULL COMMENT '仅双方和授权管理端可见',
  `status` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'PENDING' COMMENT '申请状态：PENDING/APPROVED/IN_PROGRESS/COMPLETED/REJECTED/WITHDRAWN/CANCELLED',
  `decision_reason` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '审核或取消说明',
  `active_applicant_id` BIGINT GENERATED ALWAYS AS (CASE WHEN `status` IN ('PENDING','APPROVED','IN_PROGRESS') THEN `applicant_id` ELSE NULL END) STORED COMMENT '同宠物同申请人只能一个有效申请',
  `selected_pet_id` BIGINT GENERATED ALWAYS AS (CASE WHEN `status` IN ('APPROVED','IN_PROGRESS','COMPLETED') THEN `pet_id` ELSE NULL END) STORED COMMENT '同宠物只能一个选定或完成申请',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁，业务修改时由 Service 显式加 1',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间，UTC',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '更新时间，UTC，由 Service 显式维护',
  `progress` JSON NOT NULL DEFAULT (JSON_ARRAY()) COMMENT '小型申请进度数组；每项 id/status/note/createdAt/actorId，禁止含其他申请人资料',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_application_active` (`pet_id`, `active_applicant_id`),
  UNIQUE KEY `uk_application_selected` (`selected_pet_id`),
  UNIQUE KEY `uk_application_participants` (`id`, `applicant_id`, `publisher_id`),
  KEY `idx_application_pet` (`pet_id`, `status`, `created_at`, `id`),
  KEY `idx_application_applicant` (`applicant_id`, `status`, `created_at`, `id`),
  KEY `idx_application_publisher` (`publisher_id`, `status`, `created_at`, `id`),
  CONSTRAINT `ck_adoption_application_1` CHECK (`status` IN ('PENDING', 'APPROVED', 'IN_PROGRESS', 'COMPLETED', 'REJECTED', 'WITHDRAWN', 'CANCELLED')),
  CONSTRAINT `ck_adoption_application_2` CHECK (`applicant_id` <> `publisher_id`),
  CONSTRAINT `ck_adoption_application_3` CHECK (`version` >= 0),
  CONSTRAINT `ck_adoption_application_4` CHECK (JSON_TYPE(`progress`)='ARRAY' AND JSON_LENGTH(`progress`)<=100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='领养申请与完成记录';
CREATE TABLE `adoption_conversation` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键，自增，接口输出十进制字符串',
  `pet_id` BIGINT NOT NULL COMMENT '关联宠物',
  `participant_low_id` BIGINT NOT NULL COMMENT '较小参与者 ID',
  `participant_high_id` BIGINT NOT NULL COMMENT '较大参与者 ID',
  `last_message_id` BIGINT NULL DEFAULT NULL COMMENT '最近消息 ID，无消息为空',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间，UTC',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '更新时间，UTC，由 Service 显式维护',
  `low_last_read_message_id` BIGINT NULL DEFAULT NULL COMMENT '对应参与者的已读位置，NULL 表示未读；仅允许前移',
  `high_last_read_message_id` BIGINT NULL DEFAULT NULL COMMENT '对应参与者的已读位置，NULL 表示未读；仅允许前移',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_conversation_pair` (`pet_id`, `participant_low_id`, `participant_high_id`),
  KEY `idx_conversation_low` (`participant_low_id`, `updated_at`, `id`),
  KEY `idx_conversation_high` (`participant_high_id`, `updated_at`, `id`),
  CONSTRAINT `ck_adoption_conversation_1` CHECK (`participant_low_id` < `participant_high_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='宠物相关双方会话';
CREATE TABLE `adoption_message` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键，自增，接口输出十进制字符串',
  `conversation_id` BIGINT NOT NULL COMMENT '会话',
  `sender_id` BIGINT NOT NULL COMMENT '发送人，Service 校验为参与者',
  `client_message_id` CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '客户端消息 UUID',
  `content` VARCHAR(2000) NOT NULL COMMENT '私信纯文本',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间，UTC',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_message_client` (`sender_id`, `client_message_id`),
  KEY `idx_message_conversation` (`conversation_id`, `id`),
  KEY `idx_message_unread` (`conversation_id`, `sender_id`, `id`),
  CONSTRAINT `ck_adoption_message_1` CHECK (CHAR_LENGTH(`content`) BETWEEN 1 AND 2000)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='会话私信';
CREATE TABLE `adoption_appointment` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键，自增，接口输出十进制字符串',
  `application_id` BIGINT NOT NULL COMMENT '关联申请',
  `applicant_id` BIGINT NOT NULL COMMENT '申请人，来自申请',
  `publisher_id` BIGINT NOT NULL COMMENT '发布者，来自申请',
  `creator_id` BIGINT NOT NULL COMMENT '提出预约者',
  `starts_at` DATETIME(3) NOT NULL COMMENT 'UTC 开始时间',
  `ends_at` DATETIME(3) NOT NULL COMMENT 'UTC 结束时间',
  `location` VARCHAR(200) NOT NULL COMMENT '地点',
  `note` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '补充说明',
  `status` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'REQUESTED' COMMENT '预约状态：REQUESTED/CONFIRMED/CANCELLED/COMPLETED',
  `cancel_reason` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '取消说明',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁，业务修改时由 Service 显式加 1',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间，UTC',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '更新时间，UTC，由 Service 显式维护',
  PRIMARY KEY (`id`),
  KEY `idx_appointment_application` (`application_id`, `status`, `id`),
  KEY `idx_appointment_applicant` (`applicant_id`, `status`, `starts_at`, `id`),
  KEY `idx_appointment_publisher` (`publisher_id`, `status`, `starts_at`, `id`),
  CONSTRAINT `ck_adoption_appointment_1` CHECK (`status` IN ('REQUESTED', 'CONFIRMED', 'CANCELLED', 'COMPLETED')),
  CONSTRAINT `ck_adoption_appointment_2` CHECK (`creator_id` IN (`applicant_id`,`publisher_id`)),
  CONSTRAINT `ck_adoption_appointment_3` CHECK (`starts_at` < `ends_at`),
  CONSTRAINT `ck_adoption_appointment_4` CHECK (TIMESTAMPDIFF(MICROSECOND,`starts_at`,`ends_at`) <= 14400000000),
  CONSTRAINT `ck_adoption_appointment_5` CHECK (`version` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='领养见面预约';
CREATE TABLE `adoption_complaint` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键，自增，接口输出十进制字符串',
  `application_id` BIGINT NOT NULL COMMENT '关联申请',
  `reporter_id` BIGINT NOT NULL COMMENT '投诉人，必须是申请双方之一',
  `reason` VARCHAR(2000) NOT NULL COMMENT '投诉说明',
  `status` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'PENDING' COMMENT '处理状态：PENDING/RESOLVED/REJECTED',
  `result` VARCHAR(2000) NOT NULL DEFAULT '' COMMENT '处理反馈',
  `handled_by` BIGINT NULL DEFAULT NULL COMMENT '处理管理员',
  `handled_at` DATETIME(3) NULL DEFAULT NULL COMMENT '处理时间',
  `pending_reporter_id` BIGINT GENERATED ALWAYS AS (CASE WHEN `status`='PENDING' THEN `reporter_id` ELSE NULL END) STORED COMMENT '同人同申请最多一条待处理投诉',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁，业务修改时由 Service 显式加 1',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间，UTC',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '更新时间，UTC，由 Service 显式维护',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_complaint_pending` (`application_id`, `pending_reporter_id`),
  KEY `idx_complaint_reporter` (`reporter_id`, `created_at`, `id`),
  KEY `idx_complaint_status` (`status`, `created_at`, `id`),
  CONSTRAINT `ck_adoption_complaint_1` CHECK (`status` IN ('PENDING', 'RESOLVED', 'REJECTED')),
  CONSTRAINT `ck_adoption_complaint_2` CHECK (`version` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='领养投诉与反馈';
CREATE TABLE `community_category` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键，自增，接口输出十进制字符串',
  `name` VARCHAR(40) NOT NULL COMMENT '分类名',
  `sort` INT NOT NULL DEFAULT 0 COMMENT '排序值',
  `enabled` TINYINT NOT NULL DEFAULT 1 COMMENT '是否启用',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁，业务修改时由 Service 显式加 1',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间，UTC',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '更新时间，UTC，由 Service 显式维护',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_community_category_name` (`name`),
  KEY `idx_community_category_sort` (`enabled`, `sort`, `id`),
  CONSTRAINT `ck_community_category_1` CHECK (`sort` >= 0),
  CONSTRAINT `ck_community_category_2` CHECK (`enabled` IN (0,1)),
  CONSTRAINT `ck_community_category_3` CHECK (`version` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='社区分类';
CREATE TABLE `community_post` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键，自增，接口输出十进制字符串',
  `author_id` BIGINT NOT NULL COMMENT '作者',
  `kind` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'POST' COMMENT '内容类型：POST/DIARY/HELP',
  `title` VARCHAR(100) NOT NULL COMMENT '标题',
  `content` TEXT NOT NULL COMMENT '正文纯文本，1–10000 字',
  `category_id` BIGINT NOT NULL COMMENT '分类',
  `pet_name` VARCHAR(60) NOT NULL DEFAULT '' COMMENT '日记宠物名，其他类型可为空',
  `visibility` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'PUBLIC' COMMENT '可见范围：PUBLIC/PRIVATE',
  `link` VARCHAR(2048) NOT NULL DEFAULT '' COMMENT '可选 HTTP/HTTPS 链接',
  `review_status` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'DRAFT' COMMENT '审核状态：DRAFT/PENDING/PUBLISHED/REJECTED/OFF_SHELF',
  `review_reason` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '审核或下架说明',
  `resolved` TINYINT NOT NULL DEFAULT 0 COMMENT 'HELP 是否已解决',
  `is_deleted` TINYINT NOT NULL DEFAULT 0 COMMENT '内容逻辑删除标记',
  `deleted_at` DATETIME(3) NULL DEFAULT NULL COMMENT '逻辑删除时间',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁，业务修改时由 Service 显式加 1',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间，UTC',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '更新时间，UTC，由 Service 显式维护',
  `tags` JSON NOT NULL DEFAULT (JSON_ARRAY()) COMMENT '最多 5 个去重标签，每个 1–20 字，由 Service 校验',
  PRIMARY KEY (`id`),
  KEY `idx_post_public` (`is_deleted`, `visibility`, `review_status`, `created_at`, `id`),
  KEY `idx_post_category` (`category_id`, `is_deleted`, `visibility`, `review_status`, `created_at`, `id`),
  KEY `idx_post_author` (`author_id`, `is_deleted`, `created_at`, `id`),
  KEY `idx_post_kind` (`kind`, `is_deleted`, `visibility`, `review_status`, `created_at`, `id`),
  CONSTRAINT `ck_community_post_1` CHECK (`kind` IN ('POST', 'DIARY', 'HELP')),
  CONSTRAINT `ck_community_post_2` CHECK (`visibility` IN ('PUBLIC', 'PRIVATE')),
  CONSTRAINT `ck_community_post_3` CHECK (`review_status` IN ('DRAFT', 'PENDING', 'PUBLISHED', 'REJECTED', 'OFF_SHELF')),
  CONSTRAINT `ck_community_post_4` CHECK (`visibility`='PUBLIC' OR `kind`='DIARY'),
  CONSTRAINT `ck_community_post_5` CHECK (`kind`<>'DIARY' OR CHAR_LENGTH(`pet_name`) BETWEEN 1 AND 60),
  CONSTRAINT `ck_community_post_6` CHECK (`kind`='HELP' OR `resolved`=0),
  CONSTRAINT `ck_community_post_7` CHECK (CHAR_LENGTH(`title`) BETWEEN 1 AND 100),
  CONSTRAINT `ck_community_post_8` CHECK (CHAR_LENGTH(`content`) BETWEEN 1 AND 10000),
  CONSTRAINT `ck_community_post_9` CHECK ((`is_deleted`=0 AND `deleted_at` IS NULL) OR (`is_deleted`=1 AND `deleted_at` IS NOT NULL)),
  CONSTRAINT `ck_community_post_10` CHECK (`resolved` IN (0,1)),
  CONSTRAINT `ck_community_post_11` CHECK (`is_deleted` IN (0,1)),
  CONSTRAINT `ck_community_post_12` CHECK (`version` >= 0),
  CONSTRAINT `ck_community_post_13` CHECK (JSON_TYPE(`tags`)='ARRAY' AND JSON_LENGTH(`tags`)<=5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='帖子日记求助主表';
CREATE TABLE `community_comment` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键，自增，接口输出十进制字符串',
  `post_id` BIGINT NOT NULL COMMENT '所属内容',
  `author_id` BIGINT NOT NULL COMMENT '真实评论作者，删除占位响应中隐藏',
  `parent_id` BIGINT NULL DEFAULT NULL COMMENT '顶级评论 ID，顶级本身为空',
  `content` VARCHAR(1000) NOT NULL COMMENT '正文，删除时改为固定占位且不返回原文',
  `is_deleted` TINYINT NOT NULL DEFAULT 0 COMMENT '逻辑删除标记',
  `deleted_at` DATETIME(3) NULL DEFAULT NULL COMMENT '删除时间',
  `delete_reason` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '本人删除或违规移除说明',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁，业务修改时由 Service 显式加 1',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间，UTC',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '更新时间，UTC，由 Service 显式维护',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_comment_post_id` (`post_id`, `id`),
  KEY `idx_comment_post` (`post_id`, `id`),
  KEY `idx_comment_parent` (`parent_id`, `id`),
  KEY `idx_comment_author` (`author_id`, `created_at`, `id`),
  CONSTRAINT `ck_community_comment_1` CHECK (CHAR_LENGTH(`content`) BETWEEN 1 AND 1000),
  CONSTRAINT `ck_community_comment_2` CHECK ((`is_deleted`=0 AND `deleted_at` IS NULL) OR (`is_deleted`=1 AND `deleted_at` IS NOT NULL)),
  CONSTRAINT `ck_community_comment_3` CHECK (`is_deleted` IN (0,1)),
  CONSTRAINT `ck_community_comment_4` CHECK (`version` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='评论与一层回复';
CREATE TABLE `community_like` (
  `user_id` BIGINT NOT NULL COMMENT '用户 ID',
  `post_id` BIGINT NOT NULL COMMENT '被点赞内容',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间，UTC',
  PRIMARY KEY (`user_id`, `post_id`),
  KEY `idx_like_post` (`post_id`, `user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='社区点赞';
CREATE TABLE `community_report` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键，自增，接口输出十进制字符串',
  `reporter_id` BIGINT NOT NULL COMMENT '举报人',
  `target_type` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'POST' COMMENT '举报对象：POST/COMMENT',
  `target_id` BIGINT NOT NULL COMMENT '帖子或评论 ID',
  `reason` VARCHAR(500) NOT NULL COMMENT '举报说明',
  `status` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'PENDING' COMMENT '处理状态：PENDING/RESOLVED/REJECTED',
  `result` VARCHAR(2000) NOT NULL DEFAULT '' COMMENT '管理员反馈',
  `handled_by` BIGINT NULL DEFAULT NULL COMMENT '处理人',
  `handled_at` DATETIME(3) NULL DEFAULT NULL COMMENT '处理时间',
  `pending_reporter_id` BIGINT GENERATED ALWAYS AS (CASE WHEN `status`='PENDING' THEN `reporter_id` ELSE NULL END) STORED COMMENT '同人同目标最多一个待处理举报',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁，业务修改时由 Service 显式加 1',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间，UTC',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '更新时间，UTC，由 Service 显式维护',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_report_pending` (`target_type`, `target_id`, `pending_reporter_id`),
  KEY `idx_report_reporter` (`reporter_id`, `created_at`, `id`),
  KEY `idx_report_status` (`status`, `created_at`, `id`),
  CONSTRAINT `ck_community_report_1` CHECK (`target_type` IN ('POST', 'COMMENT')),
  CONSTRAINT `ck_community_report_2` CHECK (`status` IN ('PENDING', 'RESOLVED', 'REJECTED')),
  CONSTRAINT `ck_community_report_3` CHECK (`target_id` > 0),
  CONSTRAINT `ck_community_report_4` CHECK (`version` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='内容或评论举报';
CREATE TABLE `shop_category` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键，自增，接口输出十进制字符串',
  `name` VARCHAR(40) NOT NULL COMMENT '分类名称',
  `sort` INT NOT NULL DEFAULT 0 COMMENT '排序值',
  `enabled` TINYINT NOT NULL DEFAULT 1 COMMENT '是否启用',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁，业务修改时由 Service 显式加 1',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间，UTC',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '更新时间，UTC，由 Service 显式维护',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_shop_category_name` (`name`),
  KEY `idx_shop_category_sort` (`enabled`, `sort`, `id`),
  CONSTRAINT `ck_shop_category_1` CHECK (`sort` >= 0),
  CONSTRAINT `ck_shop_category_2` CHECK (`enabled` IN (0,1)),
  CONSTRAINT `ck_shop_category_3` CHECK (`version` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='商品分类';
CREATE TABLE `shop_product` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键，自增，接口输出十进制字符串',
  `category_id` BIGINT NOT NULL COMMENT '分类',
  `name` VARCHAR(100) NOT NULL COMMENT '商品名',
  `description` TEXT NOT NULL COMMENT '商品描述，1–10000 字',
  `price_cents` BIGINT NOT NULL COMMENT '当前单价，分',
  `stock` INT NOT NULL COMMENT '可售库存',
  `status` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'OFF_SHELF' COMMENT '销售状态：OFF_SHELF/ON_SHELF',
  `created_by` BIGINT NOT NULL COMMENT '创建管理员',
  `updated_by` BIGINT NOT NULL COMMENT '最近修改管理员',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁，业务修改时由 Service 显式加 1',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间，UTC',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '更新时间，UTC，由 Service 显式维护',
  PRIMARY KEY (`id`),
  KEY `idx_product_public` (`status`, `created_at`, `id`),
  KEY `idx_product_category` (`category_id`, `status`, `created_at`, `id`),
  KEY `idx_product_price` (`status`, `price_cents`, `id`),
  CONSTRAINT `ck_shop_product_1` CHECK (`status` IN ('OFF_SHELF', 'ON_SHELF')),
  CONSTRAINT `ck_shop_product_2` CHECK (`price_cents` BETWEEN 1 AND 9999999999),
  CONSTRAINT `ck_shop_product_3` CHECK (`stock` BETWEEN 0 AND 1000000),
  CONSTRAINT `ck_shop_product_4` CHECK (CHAR_LENGTH(`description`) BETWEEN 1 AND 10000),
  CONSTRAINT `ck_shop_product_5` CHECK (`version` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='商品与当前可售库存';
CREATE TABLE `shop_cart_item` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键，自增，接口输出十进制字符串',
  `user_id` BIGINT NOT NULL COMMENT '用户 ID',
  `product_id` BIGINT NOT NULL COMMENT '商品',
  `quantity` INT NOT NULL COMMENT '最终数量',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间，UTC',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '更新时间，UTC，由 Service 显式维护',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_cart_user_product` (`user_id`, `product_id`),
  KEY `idx_cart_user` (`user_id`, `id`),
  CONSTRAINT `ck_shop_cart_item_1` CHECK (`quantity` BETWEEN 1 AND 99)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='用户购物车';
CREATE TABLE `user_address` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键，自增，接口输出十进制字符串',
  `user_id` BIGINT NOT NULL COMMENT '用户 ID',
  `recipient` VARCHAR(40) NOT NULL COMMENT '收件人',
  `phone` VARCHAR(32) NOT NULL COMMENT '电话',
  `province` VARCHAR(40) NOT NULL COMMENT '省',
  `city` VARCHAR(40) NOT NULL COMMENT '市',
  `district` VARCHAR(40) NOT NULL COMMENT '区县',
  `detail` VARCHAR(200) NOT NULL COMMENT '详细地址',
  `is_default` TINYINT NOT NULL DEFAULT 0 COMMENT '是否默认',
  `default_user_id` BIGINT GENERATED ALWAYS AS (CASE WHEN `is_default`=1 THEN `user_id` ELSE NULL END) STORED COMMENT '每个用户至多一个默认地址',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁，业务修改时由 Service 显式加 1',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间，UTC',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '更新时间，UTC，由 Service 显式维护',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_address_default` (`default_user_id`),
  KEY `idx_address_user` (`user_id`, `id`),
  CONSTRAINT `ck_user_address_1` CHECK (`is_default` IN (0,1)),
  CONSTRAINT `ck_user_address_2` CHECK (`version` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='用户收货地址';
CREATE TABLE `shop_order` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键，自增，接口输出十进制字符串',
  `order_no` VARCHAR(40) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '唯一业务订单号',
  `buyer_id` BIGINT NOT NULL COMMENT '购买人',
  `total_cents` BIGINT NOT NULL COMMENT '订单总额，含零运费',
  `shipping_fee_cents` BIGINT NOT NULL DEFAULT 0 COMMENT '运费，当前固定 0',
  `status` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'WAIT_SHIPMENT' COMMENT '订单状态：WAIT_SHIPMENT/SHIPPED/COMPLETED/CANCELLED/REFUNDING/REFUNDED',
  `payment_mode` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'MOCK' COMMENT '模拟购买方式：MOCK',
  `paid_at` DATETIME(3) NOT NULL COMMENT '模拟购买成功时间',
  `address_id_snapshot` BIGINT NOT NULL COMMENT '原地址 ID，仅作快照不建立外键',
  `recipient_snapshot` VARCHAR(40) NOT NULL COMMENT '下单时收件人',
  `phone_snapshot` VARCHAR(32) NOT NULL COMMENT '下单时电话',
  `province_snapshot` VARCHAR(40) NOT NULL COMMENT '下单时省',
  `city_snapshot` VARCHAR(40) NOT NULL COMMENT '下单时市',
  `district_snapshot` VARCHAR(40) NOT NULL COMMENT '下单时区县',
  `detail_snapshot` VARCHAR(200) NOT NULL COMMENT '下单时详细地址',
  `address_default_snapshot` TINYINT NOT NULL DEFAULT 0 COMMENT '下单时地址是否默认',
  `address_version_snapshot` INT NOT NULL COMMENT '下单时地址版本',
  `shipping_company` VARCHAR(60) NOT NULL DEFAULT '' COMMENT '物流公司，未发货为空',
  `tracking_number` VARCHAR(100) NOT NULL DEFAULT '' COMMENT '物流单号，未发货为空',
  `shipped_at` DATETIME(3) NULL DEFAULT NULL COMMENT '发货时间',
  `completed_at` DATETIME(3) NULL DEFAULT NULL COMMENT '确认收货时间',
  `cancelled_at` DATETIME(3) NULL DEFAULT NULL COMMENT '取消时间',
  `cancel_reason` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '取消说明',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁，业务修改时由 Service 显式加 1',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间，UTC',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '更新时间，UTC，由 Service 显式维护',
  `payment_status` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'SUCCESS' COMMENT '本版模拟购买成功，不接第三方支付',
  `refund_amount_cents` BIGINT NOT NULL DEFAULT 0 COMMENT '已退金额，分；只支持整单退款',
  `refunded_at` DATETIME(3) NULL DEFAULT NULL COMMENT '模拟退款完成时间，UTC',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_order_no` (`order_no`),
  KEY `idx_order_buyer` (`buyer_id`, `status`, `created_at`, `id`),
  KEY `idx_order_buyer_created` (`buyer_id`, `created_at`, `id`),
  KEY `idx_order_status` (`status`, `created_at`, `id`),
  CONSTRAINT `ck_shop_order_1` CHECK (`status` IN ('WAIT_SHIPMENT', 'SHIPPED', 'COMPLETED', 'CANCELLED', 'REFUNDING', 'REFUNDED')),
  CONSTRAINT `ck_shop_order_2` CHECK (`payment_mode`='MOCK'),
  CONSTRAINT `ck_shop_order_3` CHECK (`total_cents` BETWEEN 1 AND 9999999999),
  CONSTRAINT `ck_shop_order_4` CHECK (`shipping_fee_cents`=0),
  CONSTRAINT `ck_shop_order_5` CHECK (`address_version_snapshot` >= 0),
  CONSTRAINT `ck_shop_order_6` CHECK (`address_default_snapshot` IN (0,1)),
  CONSTRAINT `ck_shop_order_7` CHECK (`version` >= 0),
  CONSTRAINT `ck_shop_order_8` CHECK (`payment_status`='SUCCESS'),
  CONSTRAINT `ck_shop_order_9` CHECK ((`status` IN ('CANCELLED','REFUNDED') AND `refund_amount_cents`=`total_cents` AND `refunded_at` IS NOT NULL) OR (`status` NOT IN ('CANCELLED','REFUNDED') AND `refund_amount_cents`=0 AND `refunded_at` IS NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='订单与收货地址快照';
CREATE TABLE `shop_order_item` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键，自增，接口输出十进制字符串',
  `order_id` BIGINT NOT NULL COMMENT '订单',
  `product_id` BIGINT NOT NULL COMMENT '原商品 ID，商品只下架不删除',
  `name_snapshot` VARCHAR(100) NOT NULL COMMENT '下单时商品名称',
  `quantity` INT NOT NULL COMMENT '购买数量',
  `unit_price_cents` BIGINT NOT NULL COMMENT '下单时单价，分',
  `subtotal_cents` BIGINT NOT NULL COMMENT '行金额，分',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间，UTC',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_order_product` (`order_id`, `product_id`),
  CONSTRAINT `ck_shop_order_item_1` CHECK (`quantity` BETWEEN 1 AND 99),
  CONSTRAINT `ck_shop_order_item_2` CHECK (`unit_price_cents` BETWEEN 1 AND 9999999999),
  CONSTRAINT `ck_shop_order_item_3` CHECK (`subtotal_cents` BETWEEN 1 AND 9999999999),
  CONSTRAINT `ck_shop_order_item_4` CHECK (`subtotal_cents`=`quantity`*`unit_price_cents`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='订单商品快照';
CREATE TABLE `shop_refund` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键，自增，接口输出十进制字符串',
  `order_id` BIGINT NOT NULL COMMENT '订单',
  `applicant_id` BIGINT NOT NULL COMMENT '买家',
  `amount_cents` BIGINT NOT NULL COMMENT '服务端订单全额，分',
  `reason` VARCHAR(500) NOT NULL COMMENT '退款原因',
  `status` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'REQUESTED' COMMENT '退款状态：REQUESTED/APPROVED/REJECTED/SUCCESS',
  `decision_reason` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '审核反馈',
  `restocked` TINYINT NOT NULL DEFAULT 0 COMMENT '是否已恢复库存',
  `previous_order_status` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'SHIPPED' COMMENT '申请前订单状态：SHIPPED/COMPLETED',
  `handled_by` BIGINT NULL DEFAULT NULL COMMENT '处理管理员',
  `handled_at` DATETIME(3) NULL DEFAULT NULL COMMENT '处理时间',
  `open_order_id` BIGINT GENERATED ALWAYS AS (CASE WHEN `status` IN ('REQUESTED','APPROVED','SUCCESS') THEN `order_id` ELSE NULL END) STORED COMMENT '同订单只能有一条处理中或成功退款',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁，业务修改时由 Service 显式加 1',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间，UTC',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '更新时间，UTC，由 Service 显式维护',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_refund_open_order` (`open_order_id`),
  KEY `idx_refund_applicant` (`applicant_id`, `created_at`, `id`),
  KEY `idx_refund_order` (`order_id`, `id`),
  KEY `idx_refund_status` (`status`, `created_at`, `id`),
  CONSTRAINT `ck_shop_refund_1` CHECK (`status` IN ('REQUESTED', 'APPROVED', 'REJECTED', 'SUCCESS')),
  CONSTRAINT `ck_shop_refund_2` CHECK (`previous_order_status` IN ('SHIPPED', 'COMPLETED')),
  CONSTRAINT `ck_shop_refund_3` CHECK (`amount_cents` BETWEEN 1 AND 9999999999),
  CONSTRAINT `ck_shop_refund_4` CHECK (`restocked`=0 OR `status`='SUCCESS'),
  CONSTRAINT `ck_shop_refund_5` CHECK (`restocked` IN (0,1)),
  CONSTRAINT `ck_shop_refund_6` CHECK (`version` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='发货后整单退款申请';

-- 原有 media_file.owner_id 外键保留，不重复添加。
ALTER TABLE `user_notice` ADD CONSTRAINT `fk_user_notice_2` FOREIGN KEY (`recipient_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `user_notice` ADD CONSTRAINT `fk_user_notice_3` FOREIGN KEY (`broadcast_id`) REFERENCES `user_notice` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `user_notice` ADD CONSTRAINT `fk_user_notice_4` FOREIGN KEY (`created_by`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `user_favorite` ADD CONSTRAINT `fk_user_favorite_5` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `api_idempotency` ADD CONSTRAINT `fk_api_idempotency_6` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `operation_log` ADD CONSTRAINT `fk_operation_log_7` FOREIGN KEY (`operator_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `adoption_pet` ADD CONSTRAINT `fk_adoption_pet_8` FOREIGN KEY (`publisher_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `adoption_need` ADD CONSTRAINT `fk_adoption_need_9` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `adoption_application` ADD CONSTRAINT `fk_adoption_application_10` FOREIGN KEY (`pet_id`) REFERENCES `adoption_pet` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `adoption_application` ADD CONSTRAINT `fk_adoption_application_11` FOREIGN KEY (`applicant_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `adoption_application` ADD CONSTRAINT `fk_adoption_application_12` FOREIGN KEY (`publisher_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `adoption_application` ADD CONSTRAINT `fk_adoption_application_13` FOREIGN KEY (`pet_id`, `publisher_id`) REFERENCES `adoption_pet` (`id`, `publisher_id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `adoption_conversation` ADD CONSTRAINT `fk_adoption_conversation_14` FOREIGN KEY (`pet_id`) REFERENCES `adoption_pet` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `adoption_conversation` ADD CONSTRAINT `fk_adoption_conversation_15` FOREIGN KEY (`participant_low_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `adoption_conversation` ADD CONSTRAINT `fk_adoption_conversation_16` FOREIGN KEY (`participant_high_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `adoption_message` ADD CONSTRAINT `fk_adoption_message_17` FOREIGN KEY (`conversation_id`) REFERENCES `adoption_conversation` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `adoption_message` ADD CONSTRAINT `fk_adoption_message_18` FOREIGN KEY (`sender_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `adoption_appointment` ADD CONSTRAINT `fk_adoption_appointment_19` FOREIGN KEY (`application_id`) REFERENCES `adoption_application` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `adoption_appointment` ADD CONSTRAINT `fk_adoption_appointment_20` FOREIGN KEY (`applicant_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `adoption_appointment` ADD CONSTRAINT `fk_adoption_appointment_21` FOREIGN KEY (`publisher_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `adoption_appointment` ADD CONSTRAINT `fk_adoption_appointment_22` FOREIGN KEY (`creator_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `adoption_appointment` ADD CONSTRAINT `fk_adoption_appointment_23` FOREIGN KEY (`application_id`, `applicant_id`, `publisher_id`) REFERENCES `adoption_application` (`id`, `applicant_id`, `publisher_id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `adoption_complaint` ADD CONSTRAINT `fk_adoption_complaint_24` FOREIGN KEY (`application_id`) REFERENCES `adoption_application` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `adoption_complaint` ADD CONSTRAINT `fk_adoption_complaint_25` FOREIGN KEY (`reporter_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `adoption_complaint` ADD CONSTRAINT `fk_adoption_complaint_26` FOREIGN KEY (`handled_by`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `community_post` ADD CONSTRAINT `fk_community_post_27` FOREIGN KEY (`author_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `community_post` ADD CONSTRAINT `fk_community_post_28` FOREIGN KEY (`category_id`) REFERENCES `community_category` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `community_comment` ADD CONSTRAINT `fk_community_comment_29` FOREIGN KEY (`post_id`) REFERENCES `community_post` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `community_comment` ADD CONSTRAINT `fk_community_comment_30` FOREIGN KEY (`author_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `community_comment` ADD CONSTRAINT `fk_community_comment_31` FOREIGN KEY (`parent_id`) REFERENCES `community_comment` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `community_comment` ADD CONSTRAINT `fk_community_comment_32` FOREIGN KEY (`post_id`, `parent_id`) REFERENCES `community_comment` (`post_id`, `id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `community_like` ADD CONSTRAINT `fk_community_like_33` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `community_like` ADD CONSTRAINT `fk_community_like_34` FOREIGN KEY (`post_id`) REFERENCES `community_post` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `community_report` ADD CONSTRAINT `fk_community_report_35` FOREIGN KEY (`reporter_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `community_report` ADD CONSTRAINT `fk_community_report_36` FOREIGN KEY (`handled_by`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `shop_product` ADD CONSTRAINT `fk_shop_product_37` FOREIGN KEY (`category_id`) REFERENCES `shop_category` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `shop_product` ADD CONSTRAINT `fk_shop_product_38` FOREIGN KEY (`created_by`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `shop_product` ADD CONSTRAINT `fk_shop_product_39` FOREIGN KEY (`updated_by`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `shop_cart_item` ADD CONSTRAINT `fk_shop_cart_item_40` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `shop_cart_item` ADD CONSTRAINT `fk_shop_cart_item_41` FOREIGN KEY (`product_id`) REFERENCES `shop_product` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `user_address` ADD CONSTRAINT `fk_user_address_42` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `shop_order` ADD CONSTRAINT `fk_shop_order_43` FOREIGN KEY (`buyer_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `shop_order_item` ADD CONSTRAINT `fk_shop_order_item_44` FOREIGN KEY (`order_id`) REFERENCES `shop_order` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `shop_order_item` ADD CONSTRAINT `fk_shop_order_item_45` FOREIGN KEY (`product_id`) REFERENCES `shop_product` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `shop_refund` ADD CONSTRAINT `fk_shop_refund_46` FOREIGN KEY (`order_id`) REFERENCES `shop_order` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `shop_refund` ADD CONSTRAINT `fk_shop_refund_47` FOREIGN KEY (`applicant_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `shop_refund` ADD CONSTRAINT `fk_shop_refund_48` FOREIGN KEY (`handled_by`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
