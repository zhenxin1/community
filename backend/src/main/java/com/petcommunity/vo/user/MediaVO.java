package com.petcommunity.vo.user;
import java.time.OffsetDateTime;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class MediaVO {
    private String id;
    private String businessType;
    private String mimeType;
    private long sizeBytes;
    private String contentPath;
    private OffsetDateTime createdAt;
}
