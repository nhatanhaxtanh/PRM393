package com.backend.repository;

import com.backend.entity.Batch;
import com.backend.enums.BatchStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BatchRepository extends JpaRepository<Batch, Long> {
    List<Batch> findByGraderId(Long graderId);

    List<Batch> findByGraderIdAndStatusIn(Long graderId, List<BatchStatus> statuses);
}