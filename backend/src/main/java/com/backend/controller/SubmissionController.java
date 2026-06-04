package com.backend.controller;

import com.backend.dto.GradeRequestDTO;
import com.backend.entity.Submission;
import com.backend.repository.SubmissionRepository;
import com.backend.service.FileProcessingService;
import com.backend.service.GradingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/submissions")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class SubmissionController {

    private final GradingService gradingService;
    private final FileProcessingService fileProcessingService;
    private final SubmissionRepository submissionRepository;

    @GetMapping("/{submissionId}/document")
    public ResponseEntity<String> getSubmissionDocument(@PathVariable Long submissionId) {
        Submission submission = submissionRepository.findById(submissionId)
                .orElseThrow(() -> new RuntimeException("Error"));
        String parsedText = fileProcessingService.processSubmissionFile(submission.getFile_url());
        return ResponseEntity.ok(parsedText);
    }

    @PostMapping("/{submissionId}/grade")
    public ResponseEntity<String> saveGrade(
            @PathVariable Long submissionId,
            @RequestBody GradeRequestDTO gradeRequest
    ) {
        try {
            gradingService.saveGrades(submissionId, gradeRequest);
            return ResponseEntity.ok("OK");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error: " + e.getMessage());
        }
    }
}