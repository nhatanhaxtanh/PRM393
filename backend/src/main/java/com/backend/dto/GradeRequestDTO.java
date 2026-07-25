package com.backend.dto;

import lombok.Data;
import java.util.List;

@Data
public class GradeRequestDTO {
    private String status;
    private List<GradeItemDTO> grades;
}