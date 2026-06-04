package com.backend.service.impl;

import com.backend.dto.GradeItemDTO;
import com.backend.dto.GradeRequestDTO;
import com.backend.entity.Grade;
import com.backend.entity.Rubric;
import com.backend.entity.Submission;
import com.backend.enums.SubmissionStatus;
import com.backend.repository.GradeRepository;
import com.backend.repository.RubricRepository;
import com.backend.repository.SubmissionRepository;
import com.backend.service.GradingService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class GradingServiceImpl implements GradingService {

    private final SubmissionRepository submissionRepository;
    private final GradeRepository gradeRepository;
    private final RubricRepository rubricRepository;

    @Override
    @Transactional // Đảm bảo nếu lỗi thì rollback toàn bộ, không lưu nửa vời
    public void saveGrades(Long submissionId, GradeRequestDTO request) {
        // 1. Tìm bài nộp
        Submission submission = submissionRepository.findById(submissionId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy bài nộp với ID: " + submissionId));

        Long examId = submission.getBatch().getExam().getId();

        // 2. Xóa các điểm chi tiết cũ (nếu có) để chuẩn bị ghi đè
        gradeRepository.deleteBySubmissionId(submissionId);

        // 3. Xử lý từng câu điểm (Grades)
        double totalScore = 0.0;
        List<Grade> gradesToSave = new ArrayList<>();

        for (GradeItemDTO item : request.getGrades()) {
            // Tìm Barem (Rubric) tương ứng với câu hỏi này trong đề thi
            Rubric rubric = rubricRepository.findByExamIdAndRequestNo(examId, item.getRequestNo())
                    .orElseThrow(() -> new RuntimeException("Không tìm thấy Barem cho Request No: " + item.getRequestNo()));

            // Validate: Không được cho điểm vượt mức tối đa của câu
            if (item.getAwardedScore() > rubric.getMaxScore() || item.getAwardedScore() < 0) {
                throw new IllegalArgumentException("Điểm của Request " + item.getRequestNo() + " không hợp lệ.");
            }

            totalScore += item.getAwardedScore();

            Grade grade = Grade.builder()
                    .submission(submission)
                    .rubric(rubric)
                    .awardedScore(item.getAwardedScore())
                    .comments(item.getComments())
                    .build();

            gradesToSave.add(grade);
        }

        // Lưu toàn bộ điểm chi tiết vào DB
        gradeRepository.saveAll(gradesToSave);

        // 4. Cập nhật trạng thái và tổng điểm cho bài nộp (Submission)
        submission.setTotalScore(Math.round(totalScore * 10.0) / 10.0); // Làm tròn 1 chữ số thập phân

        if ("GRADED".equalsIgnoreCase(request.getStatus())) {
            submission.setStatus(SubmissionStatus.GRADED);
        } else {
            submission.setStatus(SubmissionStatus.DRAFT);
        }

        submissionRepository.save(submission);
    }
}