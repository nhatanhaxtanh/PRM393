package com.backend.dto;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Builder
public class StudentSubmissionDTO {
    private Long submissionId;
    private String studentId;     // VD: SE123456
    private String fullName;
    private LocalDateTime submissionTime;
    private String status;        // NOT_GRADED, DRAFT, GRADED
    private Double totalScore;    // Null nếu chưa chấm
}