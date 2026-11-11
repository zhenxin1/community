package com.petcommunity.validation;
import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;
public class CodePointLengthValidator implements ConstraintValidator<CodePointLength,String> {
    private int min,max;
    public void initialize(CodePointLength a){ min=a.min(); max=a.max(); }
    public boolean isValid(String value, ConstraintValidatorContext c){
        return value==null || (value.codePointCount(0,value.length())>=min && value.codePointCount(0,value.length())<=max);
    }
}
