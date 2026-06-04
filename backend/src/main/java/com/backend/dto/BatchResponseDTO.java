package com.backend.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class BatchResponseDTO {
    private Long batchId;
    private String campusCode;   // VD: HCM
    private String examCode;     // VD: PE_201_Spring26
    private String examType;     // VD: RETAKE
    private int totalStudents;
    private int gradedCount;     // Để UI vẽ Progress Bar (VD: 15/30)
}