package com.backend.repository;

import com.backend.entity.Grade;
import org.springframework.data.jpa.repository.JpaRepository;

public interface GradeRepository extends JpaRepository<Grade, Long> {
    void deleteBySubmissionId(Long submissionId);
}