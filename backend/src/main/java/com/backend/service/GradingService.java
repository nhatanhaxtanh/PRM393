package com.backend.service;

import com.backend.dto.GradeRequestDTO;

public interface GradingService {
    void saveGrades(Long submissionId, GradeRequestDTO request);
}