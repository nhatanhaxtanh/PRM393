package com.backend.repository;

import com.backend.entity.Submission;
import com.backend.enums.SubmissionStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
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

    @Query("SELECT s FROM Submission s WHERE s.batch.id = :batchId " +
            "AND (:keyword IS NULL OR s.student.studentId LIKE %:keyword% OR s.student.fullName LIKE %:keyword%) " +
            "AND (:status IS NULL OR s.status = :status)")
    Page<Submission> searchAndFilterSubmissions(
            @Param("batchId") Long batchId,
            @Param("keyword") String keyword,
            @Param("status") SubmissionStatus status,
            Pageable pageable);
}