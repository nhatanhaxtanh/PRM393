package com.backend.dto;

import lombok.Data;

@Data
public class GradeItemDTO {
    private Integer requestNo;
    private Double awardedScore;
    private String comments;
}