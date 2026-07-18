package com.backend.controller;

import com.backend.dto.BatchResponseDTO;
import com.backend.dto.StudentSubmissionDTO;
import com.backend.dto.ExamPaperDTO;
import com.backend.entity.Batch;
import com.backend.entity.Submission;
import com.backend.enums.BatchStatus;
import com.backend.enums.SubmissionStatus;
import com.backend.repository.BatchRepository;
import com.backend.repository.SubmissionRepository;
import com.backend.service.AIGradingService;
import com.backend.service.FileProcessingService;
import com.backend.service.GradingService;
import com.backend.dto.GradeItemDTO;
import com.backend.dto.GradeRequestDTO;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/batches")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class BatchController {

    private final BatchRepository batchRepository;
    private final SubmissionRepository submissionRepository;
    private final AIGradingService aiGradingService;
    private final FileProcessingService fileProcessingService;
    private final GradingService gradingService;

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
                        .isAIGraded(sub.getIsAIGraded())
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

    @PostMapping("/{batchId}/auto-grade-all")
    public ResponseEntity<?> autoGradeAll(@PathVariable Long batchId) {
        try {
            Batch batch = batchRepository.findById(batchId)
                    .orElseThrow(() -> new RuntimeException("Batch not found"));

            List<Submission> submissions = submissionRepository.findByBatchId(batchId);
            Long examId = batch.getExam().getId();

            int gradedCount = 0;
            int skippedCount = 0;
            int reviewNeededCount = 0;
            List<String> failedSubmissions = new java.util.ArrayList<>();
            Map<String, List<GradeItemDTO>> gradeCacheByFile = new HashMap<>();

            for (Submission submission : submissions) {
                try {
                    if (submission.getStatus() != SubmissionStatus.NOT_GRADED) {
                        skippedCount++;
                        continue;
                    }

                    // Get submission text
                    String submissionText = fileProcessingService.processSubmissionFile(submission.getFile_url());

                    // Reuse AI result for duplicate files in demo data to avoid rate limits.
                    List<GradeItemDTO> aiGrades = gradeCacheByFile.get(submission.getFile_url());
                    if (aiGrades == null) {
                        aiGrades = aiGradingService.autoGrade(examId, submissionText).block();
                        gradeCacheByFile.put(submission.getFile_url(), aiGrades);
                    }

                    if (aiGrades == null || aiGrades.isEmpty()) {
                        failedSubmissions.add("Submission " + submission.getId() + ": No grades returned from AI");
                        continue;
                    }

                    // Save the AI grades with GRADED status
                    GradeRequestDTO gradeRequest = new GradeRequestDTO();
                    boolean needsManualReview = requiresManualReview(aiGrades);
                    gradeRequest.setStatus(needsManualReview ? "DRAFT" : "GRADED");
                    gradeRequest.setGrades(aiGrades);

                    gradingService.saveGrades(submission.getId(), gradeRequest);

                    // Mark submission as AI graded
                    submission.setIsAIGraded(!needsManualReview);
                    submissionRepository.save(submission);

                    if (needsManualReview) {
                        reviewNeededCount++;
                    } else {
                        gradedCount++;
                    }
                } catch (Exception e) {
                    // Continue with next submission if one fails
                    failedSubmissions.add("Submission " + submission.getId() + ": " + e.getMessage());
                    System.err.println("Failed to grade submission " + submission.getId() + ": " + e.getMessage());
                }
            }

            Map<String, Object> response = new java.util.HashMap<>();
            response.put("message", "AI grading completed");
            response.put("totalSubmissions", submissions.size());
            response.put("gradedCount", gradedCount);
            response.put("skippedCount", skippedCount);
            response.put("reviewNeededCount", reviewNeededCount);
            response.put("failedCount", failedSubmissions.size());
            if (!failedSubmissions.isEmpty()) {
                response.put("failedSubmissions", failedSubmissions);
            }

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error: " + e.getMessage());
        }
    }

    private boolean requiresManualReview(List<GradeItemDTO> grades) {
        return grades.stream().anyMatch(grade ->
                grade.getComments() != null && grade.getComments().contains("could not be parsed"));
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
