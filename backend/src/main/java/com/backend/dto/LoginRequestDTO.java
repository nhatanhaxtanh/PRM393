package com.backend.dto;
import lombok.Data;

@Data
public class LoginRequestDTO {
    private String lecturerId;
    private String password;
}