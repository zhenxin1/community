-- 仅升级已实现账号模块：旧六表 -> sys_user + media_file；先备份。
-- 保留全部用户、密码哈希、头像与资料。原有任意管理角色映射为 ADMIN。
-- DDL 会隐式提交；不可用 ROLLBACK 撤销。脚本可重复执行。
SET NAMES utf8mb4;
SET @has_role=(SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='sys_user' AND column_name='role');
SET @sql=IF(@has_role=0,'ALTER TABLE sys_user ADD COLUMN role VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT ''USER'' COMMENT ''身份 USER/ADMIN''','SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @legacy=(SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='sys_user_role');
SET @sql=IF(@legacy=1,'UPDATE sys_user u SET role=''ADMIN'',auth_version=auth_version+1 WHERE role<>''ADMIN'' AND EXISTS (SELECT 1 FROM sys_user_role r WHERE r.user_id=u.id)','SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @has_check=(SELECT COUNT(*) FROM information_schema.check_constraints WHERE constraint_schema=DATABASE() AND constraint_name IN ('ck_sys_user_7','ck_user_fixed_role'));
SET @sql=IF(@has_check=0,'ALTER TABLE sys_user ADD CONSTRAINT ck_user_fixed_role CHECK (role IN (''USER'',''ADMIN''))','SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @has_idx=(SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name='sys_user' AND index_name='idx_user_role_status');
SET @sql=IF(@has_idx=0,'ALTER TABLE sys_user ADD INDEX idx_user_role_status (role,status,id)','SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
DROP TABLE IF EXISTS sys_user_role;
DROP TABLE IF EXISTS sys_role_permission;
DROP TABLE IF EXISTS sys_permission;
DROP TABLE IF EXISTS sys_role;
