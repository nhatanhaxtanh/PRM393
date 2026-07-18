package com.backend.repository;

import com.backend.entity.Rubric;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface RubricRepository extends JpaRepository<Rubric, Long> {
    Optional<Rubric> findByExamIdAndRequestNo(Long examId, Integer requestNo);
    List<Rubric> findByExamId(Long examId);
}