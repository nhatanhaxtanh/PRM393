package com.backend.controller;

import com.backend.dto.ApiResponse;
import com.backend.dto.GradeItemDTO;
import com.backend.dto.GradeRequestDTO;
import com.backend.dto.PageDto;
import com.backend.dto.StudentSubmissionDTO;
import com.backend.entity.Submission;
import com.backend.enums.SubmissionStatus;
import com.backend.repository.SubmissionRepository;
import com.backend.service.AIGradingService;
import com.backend.service.FileProcessingService;
import com.backend.service.GradingService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/submissions")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class SubmissionController {

    private final GradingService gradingService;
    private final FileProcessingService fileProcessingService;
    private final AIGradingService aiGradingService;
    private final SubmissionRepository submissionRepository;

    @GetMapping("/{submissionId}/document")
    public ResponseEntity<ApiResponse> getSubmissionDocument(@PathVariable Long submissionId) {
        Submission submission = submissionRepository.findById(submissionId)
                .orElseThrow(() -> new RuntimeException("Error"));

        String parsedText = fileProcessingService.processSubmissionFile(submission.getFile_url());
        return ResponseEntity.ok(ApiResponse.success(parsedText));
    }

    @PostMapping("/{submissionId}/grade")
    public ResponseEntity<ApiResponse> saveGrade(
            @PathVariable Long submissionId,
            @RequestBody GradeRequestDTO gradeRequest
    ) {
        try {
            gradingService.saveGrades(submissionId, gradeRequest);
            return ResponseEntity.ok(ApiResponse.success("OK"));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(ApiResponse.error(400, "Error: " + e.getMessage()));
        }
    }

    @PostMapping("/{submissionId}/auto-grade")
    public ResponseEntity<ApiResponse> autoGrade(@PathVariable Long submissionId) {
        try {
            Submission submission = submissionRepository.findById(submissionId)
                    .orElseThrow(() -> new RuntimeException("Submission not found"));

            // Get submission text
            String submissionText = fileProcessingService.processSubmissionFile(submission.getFile_url());

            // Get exam ID
            Long examId = submission.getBatch().getExam().getId();

            // Call AI grading service
            List<GradeItemDTO> aiGrades = aiGradingService.autoGrade(examId, submissionText).block();

            // Save the AI grades
            GradeRequestDTO gradeRequest = new GradeRequestDTO();
            gradeRequest.setStatus("GRADED");
            gradeRequest.setGrades(aiGrades);
            gradingService.saveGrades(submissionId, gradeRequest);

            // Mark submission as AI graded
            submission.setIsAIGraded(true);
            submissionRepository.save(submission);

            return ResponseEntity.ok(ApiResponse.success(aiGrades));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(ApiResponse.error(400, "Error: " + e.getMessage()));
        }
    }

    @GetMapping("/batch/{batchId}")
    public ResponseEntity<ApiResponse> getSubmissionsByBatch(
            @PathVariable Long batchId,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) SubmissionStatus status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {

        Pageable pageable = PageRequest.of(page, size);

        // G o trong repository
        Page<Submission> submissionPage = submissionRepository.searchAndFilterSubmissions(batchId, keyword, status, pageable);

        // Convert sang DTO (n ang d ng DTO) v
        Page<StudentSubmissionDTO> dtoPage = submissionPage.map(sub -> StudentSubmissionDTO.builder()
                .submissionId(sub.getId())
                .studentId(sub.getStudent().getStudentId())
                .fullName(sub.getStudent().getFullName())
                .submissionTime(sub.getSubmissionTime())
                .status(sub.getStatus().name())
                .totalScore(sub.getTotalScore())
                .isAIGraded(sub.getIsAIGraded())
                .build());

        PageDto pageDto = PageDto.from(dtoPage);
        return ResponseEntity.ok(ApiResponse.success(pageDto));
    }
}