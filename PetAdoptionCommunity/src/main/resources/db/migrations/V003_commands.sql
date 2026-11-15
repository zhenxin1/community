CREATE TABLE e4_command (
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
