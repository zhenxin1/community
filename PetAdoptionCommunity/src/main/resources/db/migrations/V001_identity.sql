CREATE TABLE schema_version (version INT PRIMARY KEY, checksum CHAR(64) NOT NULL, applied_at DATETIME(3) NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE e4_user (
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
CREATE TABLE e4_session (
 token_hash BINARY(32) PRIMARY KEY,
 user_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 auth_version BIGINT NOT NULL, state_version BIGINT NOT NULL,
 expires_at DATETIME(3) NOT NULL, revoked_at DATETIME(3),
 FOREIGN KEY(user_id) REFERENCES e4_user(id), INDEX(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
