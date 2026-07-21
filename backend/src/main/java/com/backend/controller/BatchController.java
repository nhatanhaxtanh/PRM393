package com.backend.controller;

import com.backend.dto.ApiResponse;
import com.backend.dto.BatchResponseDTO;
import com.backend.dto.StudentSubmissionDTO;
import com.backend.dto.ExamPaperDTO;
import com.backend.entity.Batch;
import com.backend.entity.Submission;
import com.backend.entity.User;
import com.backend.enums.BatchStatus;
import com.backend.enums.SubmissionStatus;
import com.backend.repository.BatchRepository;
import com.backend.repository.SubmissionRepository;
import com.backend.repository.UserRepository;
import com.backend.service.AIGradingService;
import com.backend.service.FileProcessingService;
import com.backend.service.GradingService;
import com.backend.dto.GradeItemDTO;
import com.backend.dto.GradeRequestDTO;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
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
    private final UserRepository userRepository;

    @GetMapping("/assigned")
    public ResponseEntity<ApiResponse> getAssignedBatches(@RequestParam Long lecturerId) {
        List<Batch> batches = batchRepository.findByGraderIdAndStatusIn(
                lecturerId, Arrays.asList(BatchStatus.PENDING, BatchStatus.IN_PROGRESS));
        return ResponseEntity.ok(ApiResponse.success(mapToBatchResponseList(batches)));
    }

    @GetMapping("/history")
    public ResponseEntity<ApiResponse> getGradingHistory(@RequestParam Long lecturerId) {
        List<Batch> batches = batchRepository.findByGraderIdAndStatusIn(
                lecturerId, Arrays.asList(BatchStatus.COMPLETED));
        return ResponseEntity.ok(ApiResponse.success(mapToBatchResponseList(batches)));
    }

    @GetMapping("/{batchId}/submissions")
    public ResponseEntity<ApiResponse> getStudentsInBatch(@PathVariable Long batchId) {
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
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @GetMapping("/{batchId}/exam-paper")
    public ResponseEntity<ApiResponse> getExamPaper(@PathVariable Long batchId) {
        Optional<Batch> batchOpt = batchRepository.findById(batchId);
        if (batchOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.error(404, "Batch not found"));
        }
        Batch batch = batchOpt.get();
        ExamPaperDTO response = ExamPaperDTO.builder()
                .examCode(batch.getExam().getExamCode())
                .examPaperUrl(batch.getExam().getExamPaperUrl())
                .build();
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @PostMapping("/{batchId}/auto-grade-all")
    public ResponseEntity<ApiResponse> autoGradeAll(@PathVariable Long batchId) {
        try {
            Optional<Batch> batchOpt = batchRepository.findById(batchId);
            if (batchOpt.isEmpty()) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(ApiResponse.error(404, "Batch not found"));
            }
            Batch batch = batchOpt.get();
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

                    String submissionText = fileProcessingService.processSubmissionFile(submission.getFile_url());

                    List<GradeItemDTO> aiGrades = gradeCacheByFile.get(submission.getFile_url());
                    if (aiGrades == null) {
                        aiGrades = aiGradingService.autoGrade(examId, submissionText).block();
                        gradeCacheByFile.put(submission.getFile_url(), aiGrades);
                    }

                    if (aiGrades == null || aiGrades.isEmpty()) {
                        failedSubmissions.add("Submission " + submission.getId() + ": No grades returned from AI");
                        continue;
                    }

                    GradeRequestDTO gradeRequest = new GradeRequestDTO();
                    boolean needsManualReview = requiresManualReview(aiGrades);
                    gradeRequest.setStatus(needsManualReview ? "DRAFT" : "GRADED");
                    gradeRequest.setGrades(aiGrades);

                    gradingService.saveGrades(submission.getId(), gradeRequest);

                    submission.setIsAIGraded(!needsManualReview);
                    submissionRepository.save(submission);

                    if (needsManualReview) {
                        reviewNeededCount++;
                    } else {
                        gradedCount++;
                    }
                } catch (Exception e) {
                    failedSubmissions.add("Submission " + submission.getId() + ": " + e.getMessage());
                    System.err.println("Failed to grade submission " + submission.getId() + ": " + e.getMessage());
                }
            }

            Map<String, Object> responseData = new HashMap<>();
            responseData.put("message", "AI grading completed");
            responseData.put("totalSubmissions", submissions.size());
            responseData.put("gradedCount", gradedCount);
            responseData.put("skippedCount", skippedCount);
            responseData.put("reviewNeededCount", reviewNeededCount);
            responseData.put("failedCount", failedSubmissions.size());
            if (!failedSubmissions.isEmpty()) {
                responseData.put("failedSubmissions", failedSubmissions);
            }

            return ResponseEntity.ok(ApiResponse.success(responseData));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.error(400, "Error: " + e.getMessage()));
        }
    }

    @PutMapping("/{batchId}/assign")
    public ResponseEntity<ApiResponse> assignBatch(@PathVariable Long batchId, @RequestParam Long graderId) {
        Optional<Batch> batchOpt = batchRepository.findById(batchId);
        if (batchOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.error(404, "Không tìm thấy Lô bài (Batch)"));
        }

        Optional<User> graderOpt = userRepository.findById(graderId);
        if (graderOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.error(404, "Không tìm thấy Giảng viên (Grader)"));
        }

        Batch batch = batchOpt.get();
        batch.setGrader(graderOpt.get());
        batchRepository.save(batch);

        return ResponseEntity.ok(ApiResponse.success("Phân công lô bài thành công"));
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