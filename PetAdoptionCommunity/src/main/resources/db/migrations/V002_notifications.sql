CREATE TABLE e4_notification (
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
