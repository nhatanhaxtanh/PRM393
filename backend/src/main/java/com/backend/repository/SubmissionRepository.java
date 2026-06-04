package com.backend.repository;

import com.backend.entity.Submission;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SubmissionRepository extends JpaRepository<Submission, Long> {
    // Lấy toàn bộ bài nộp trong 1 lô
    List<Submission> findByBatchId(Long batchId);

    // Đếm số lượng bài đã chấm xong (hỗ trợ vẽ thanh Progress bar trên UI)
    @Query("SELECT COUNT(s) FROM Submission s WHERE s.batch.id = :batchId AND s.status = 'GRADED'")
    long countGradedByBatchId(@Param("batchId") Long batchId);
}