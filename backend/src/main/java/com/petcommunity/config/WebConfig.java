package com.petcommunity.config;
import org.springframework.beans.factory.annotation.Autowired;
import com.petcommunity.security.AccountInterceptor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.*;
@Configuration
public class WebConfig implements WebMvcConfigurer {
    @Autowired
    private AccountInterceptor interceptor;

 @Override public void addInterceptors(InterceptorRegistry registry){ registry.addInterceptor(interceptor).addPathPatterns("/api/v1/**"); }
}
