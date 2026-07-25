package com.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ApiResponse {
    private int status;
    private String message;
    private Object data;

    public static ApiResponse success(Object data) {
        return ApiResponse.builder()
                .status(200)
                .message("Success")
                .data(data)
                .build();
    }

    public static ApiResponse success(String message) {
        return ApiResponse.builder()
                .status(200)
                .message(message)
                .data(null)
                .build();
    }

    public static ApiResponse error(int status, String message) {
        return ApiResponse.builder()
                .status(status)
                .message(message)
                .data(null)
                .build();
    }
}