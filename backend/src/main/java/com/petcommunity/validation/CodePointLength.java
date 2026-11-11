package com.petcommunity.validation;
import jakarta.validation.Constraint;
import jakarta.validation.Payload;
import java.lang.annotation.*;
@Documented @Constraint(validatedBy=CodePointLengthValidator.class)
@Target({ElementType.FIELD,ElementType.PARAMETER,ElementType.RECORD_COMPONENT}) @Retention(RetentionPolicy.RUNTIME)
public @interface CodePointLength {
    int min() default 0; int max(); String message() default "字符数量超出限制";
    Class<?>[] groups() default {}; Class<? extends Payload>[] payload() default {};
}
