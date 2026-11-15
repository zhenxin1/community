package com.example.petadoptioncommunity.media;
import org.springframework.context.annotation.Configuration;import org.springframework.web.servlet.config.annotation.*;import java.nio.file.Path;
@Configuration public class MediaConfiguration implements WebMvcConfigurer {public void addResourceHandlers(ResourceHandlerRegistry r){r.addResourceHandler("/media/**").addResourceLocations(Path.of("../.local/uploads").toAbsolutePath().normalize().toUri().toString());}}
