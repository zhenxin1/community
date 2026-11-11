package com.petcommunity.config;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.MapperFeature;
import org.springframework.boot.autoconfigure.jackson.Jackson2ObjectMapperBuilderCustomizer;
import org.springframework.context.annotation.*;
@Configuration
public class JsonConfig {
 @Bean public Jackson2ObjectMapperBuilderCustomizer strictJson(){
  return builder->builder.featuresToDisable(MapperFeature.ALLOW_COERCION_OF_SCALARS,DeserializationFeature.ACCEPT_FLOAT_AS_INT);
 }
}
