package com.backend.controller;

import com.backend.dto.BatchResponseDTO;
import com.backend.dto.StudentSubmissionDTO;
import com.backend.dto.ExamPaperDTO;
import com.backend.entity.Batch;
import com.backend.entity.Submission;
import com.backend.enums.BatchStatus;
import com.backend.repository.BatchRepository;
import com.backend.repository.SubmissionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/batches")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class BatchController {

    private final BatchRepository batchRepository;
    private final SubmissionRepository submissionRepository;

    @GetMapping("/assigned")
    public ResponseEntity<List<BatchResponseDTO>> getAssignedBatches() {
        Long currentLecturerId = 1L;
        List<Batch> batches = batchRepository.findByGraderIdAndStatusIn(
                currentLecturerId, Arrays.asList(BatchStatus.PENDING, BatchStatus.IN_PROGRESS));
        return ResponseEntity.ok(mapToBatchResponseList(batches));
    }

    @GetMapping("/history")
    public ResponseEntity<List<BatchResponseDTO>> getGradingHistory() {
        Long currentLecturerId = 1L;
        List<Batch> batches = batchRepository.findByGraderIdAndStatusIn(
                currentLecturerId, Arrays.asList(BatchStatus.COMPLETED));
        return ResponseEntity.ok(mapToBatchResponseList(batches));
    }

    @GetMapping("/{batchId}/submissions")
    public ResponseEntity<List<StudentSubmissionDTO>> getStudentsInBatch(@PathVariable Long batchId) {
        List<Submission> submissions = submissionRepository.findByBatchId(batchId);
        List<StudentSubmissionDTO> response = submissions.stream().map(sub ->
                StudentSubmissionDTO.builder()
                        .submissionId(sub.getId())
                        .studentId(sub.getStudent().getStudentId())
                        .fullName(sub.getStudent().getFullName())
                        .submissionTime(sub.getSubmissionTime())
                        .status(sub.getStatus().name())
                        .totalScore(sub.getTotalScore())
                        .build()
        ).collect(Collectors.toList());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{batchId}/exam-paper")
    public ResponseEntity<ExamPaperDTO> getExamPaper(@PathVariable Long batchId) {
        Batch batch = batchRepository.findById(batchId)
                .orElseThrow(() -> new RuntimeException("Error"));

        ExamPaperDTO response = ExamPaperDTO.builder()
                .examCode(batch.getExam().getExamCode())
                .examPaperUrl(batch.getExam().getExamPaperUrl())
                .build();
        return ResponseEntity.ok(response);
    }

    private List<BatchResponseDTO> mapToBatchResponseList(List<Batch> batches) {
        return batches.stream().map(batch -> {
            int total = submissionRepository.findByBatchId(batch.getId()).size();
            int graded = (int) submissionRepository.countGradedByBatchId(batch.getId());
            return BatchResponseDTO.builder()
                    .batchId(batch.getId())
                    .campusCode(batch.getCampus().getCampusCode())
                    .examCode(batch.getExam().getExamCode())
                    .examType(batch.getExam().getExamType())
                    .totalStudents(total)
                    .gradedCount(graded)
                    .build();
        }).collect(Collectors.toList());
    }
}