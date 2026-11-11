package com.petcommunity.entity;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class MediaEntity {
    private Long id;
    private Long ownerId;
    private String businessType;
    private Long businessId;
    private Integer sortOrder;
    private String storageKey;
    private String originalName;
    private String mimeType;
    private long sizeBytes;
    private String status;
    private LocalDateTime cleanupAfter;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
