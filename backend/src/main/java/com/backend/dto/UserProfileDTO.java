package com.backend.dto;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class UserProfileDTO {
    private String username;
    private String fullName;
    private String role;
}