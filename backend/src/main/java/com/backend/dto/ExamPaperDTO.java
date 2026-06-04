package com.backend.dto;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class ExamPaperDTO {
    private String examCode;
    private String examPaperUrl;
}