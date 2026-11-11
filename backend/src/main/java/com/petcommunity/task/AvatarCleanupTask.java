package com.petcommunity.task;
import org.springframework.beans.factory.annotation.Autowired;
import com.petcommunity.service.MediaService;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
@Component
public class AvatarCleanupTask {
    @Autowired
    private MediaService media;

 @Scheduled(initialDelay=60000,fixedDelay=3600000) public void run(){ media.cleanup(); }
}
