package com.backend.config;

import com.backend.entity.*;
import com.backend.enums.BatchStatus;
import com.backend.enums.SubmissionStatus;
import com.backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

@Component
@RequiredArgsConstructor
public class DataInitializer implements CommandLineRunner {

    private final UserRepository userRepository;
    private final CampusRepository campusRepository;
    private final ExamRepository examRepository;
    private final RubricRepository rubricRepository;
    private final StudentRepository studentRepository;
    private final BatchRepository batchRepository;
    private final SubmissionRepository submissionRepository;
    private final GradeRepository gradeRepository; // Thêm Grade Repo

    @Override
    @Transactional
    public void run(String... args) throws Exception {
        if (userRepository.count() == 0) {
            System.out.println("--- ĐANG KHỞI TẠO 40+ DỮ LIỆU MẪU (DEMO DATA) ---");

            Random random = new Random();

            // 1. Tạo Campus
            Campus campusHCM = campusRepository.save(Campus.builder().campusCode("HCM").campusName("FPTU Hồ Chí Minh").build());
            Campus campusHN = campusRepository.save(Campus.builder().campusCode("HN").campusName("FPTU Hà Nội").build());

            // 2. Tạo Users (Admin & Graders)
            User admin = userRepository.save(User.builder()
                    .username("AD0001")
                    .email("admin@fpt.edu.vn")
                    .passwordHash("123456")
                    .fullName("Trần Quản Trị")
                    .role("ADMIN")
                    .status("ACTIVE")
                    .build());

            User grader = userRepository.save(User.builder()
                    .username("GV1234")
                    .email("gv1234@fpt.edu.vn")
                    .passwordHash("123456")
                    .fullName("Nguyễn Giảng Viên")
                    .role("GRADER")
                    .campus(campusHCM)
                    .status("ACTIVE")
                    .build());

            User grader2 = userRepository.save(User.builder()
                    .username("GV1235")
                    .email("gv1235@fpt.edu.vn")
                    .passwordHash("123456")
                    .fullName("Lê Tuấn Anh")
                    .role("GRADER")
                    .campus(campusHN)
                    .status("ACTIVE")
                    .build());

            // 3. Tạo Đề thi PMG
            Exam examPE201 = examRepository.save(Exam.builder()
                    .examCode("PE_201_Spring26")
                    .term("Spring2026")
                    .examType("FIRST_ATTEMPT")
                    .examPaperUrl("https://prm-assignment.s3.ap-southeast-1.amazonaws.com/mock-exam.pdf")
                    .build());

            // 4. Tạo 4 Rubrics (20 - 20 - 30 - 30)
            List<Rubric> rubrics = rubricRepository.saveAll(List.of(
                    Rubric.builder().exam(examPE201).requestNo(1).title("Narrative Charter Statement").maxScore(20.0).build(),
                    Rubric.builder().exam(examPE201).requestNo(2).title("Budget Items").maxScore(20.0).build(),
                    Rubric.builder().exam(examPE201).requestNo(3).title("Project Risks").maxScore(30.0).build(),
                    Rubric.builder().exam(examPE201).requestNo(4).title("Project Schedule/WBS").maxScore(30.0).build()
            ));

            // 5. Tạo Lô bài phân công (Batch)
            Batch batchHCM = batchRepository.save(Batch.builder()
                    .exam(examPE201)
                    .campus(campusHCM)
                    .grader(grader)
                    .status(BatchStatus.IN_PROGRESS) // Trạng thái đang chấm dở
                    .build());

            // 6. Tạo danh sách 40 Sinh viên & Bài nộp
            String dummyFilePath = "mock_data/sample_submission.docx";
            String[] hoList = {"Nguyễn", "Trần", "Lê", "Phạm", "Hoàng", "Huỳnh", "Phan", "Vũ", "Võ", "Đặng"};
            String[] demList = {"Văn", "Thị", "Hữu", "Minh", "Thanh", "Ngọc", "Gia", "Đức", "Anh"};
            String[] tenList = {"An", "Bình", "Cường", "Dung", "Hùng", "Hương", "Linh", "Nam", "Quân", "Trang", "Tuấn"};

            List<Submission> submissionsToSave = new ArrayList<>();

            for (int i = 1; i <= 40; i++) {
                // Random tên tiếng Việt cho giao diện nhìn thực tế
                String ho = hoList[random.nextInt(hoList.length)];
                String dem = demList[random.nextInt(demList.length)];
                String ten = tenList[random.nextInt(tenList.length)];
                String fullName = ho + " " + dem + " " + ten;
                String studentId = "SE" + (130000 + i);

                Student student = studentRepository.save(Student.builder()
                        .studentId(studentId)
                        .fullName(fullName)
                        .build());

                // Random thời gian nộp (trong vòng 7 ngày qua)
                int daysAgo = random.nextInt(7);
                int hoursAgo = random.nextInt(24);
                LocalDateTime subTime = LocalDateTime.now().minusDays(daysAgo).minusHours(hoursAgo);

                // Random trạng thái: 60% GRADED, 10% DRAFT, 30% NOT_GRADED
                int statusChance = random.nextInt(100);
                SubmissionStatus status;
                Double totalScore = null;

                if (statusChance < 60) {
                    status = SubmissionStatus.GRADED;
                } else if (statusChance < 70) {
                    status = SubmissionStatus.DRAFT;
                } else {
                    status = SubmissionStatus.NOT_GRADED;
                }

                Submission submission = Submission.builder()
                        .batch(batchHCM)
                        .student(student)
                        .file_url(dummyFilePath)
                        .submissionTime(subTime)
                        .status(status)
                        .build();

                // Lưu tạm Submission để lấy ID trước khi tạo Grade
                submission = submissionRepository.save(submission);

                // Nếu đã chấm (GRADED) hoặc đang nháp (DRAFT), sinh điểm chi tiết
                if (status == SubmissionStatus.GRADED || status == SubmissionStatus.DRAFT) {
                    double calculatedTotal = 0.0;
                    List<Grade> grades = new ArrayList<>();

                    for (Rubric rubric : rubrics) {
                        // Random điểm cho từng câu (từ 50% đến 100% số điểm tối đa)
                        double minScore = rubric.getMaxScore() * 0.5;
                        double awarded = minScore + (random.nextDouble() * (rubric.getMaxScore() - minScore));
                        // Làm tròn 1 chữ số thập phân (vd: 18.5)
                        awarded = Math.round(awarded * 10.0) / 10.0;

                        calculatedTotal += awarded;

                        grades.add(Grade.builder()
                                .submission(submission)
                                .rubric(rubric)
                                .awardedScore(awarded)
                                .comments(status == SubmissionStatus.GRADED ? "Đã duyệt." : "Cần xem lại phần này.")
                                .build());
                    }
                    gradeRepository.saveAll(grades);

                    // Cập nhật lại tổng điểm cho bài nộp (Làm tròn)
                    submission.setTotalScore(Math.round(calculatedTotal * 10.0) / 10.0);
                    submissionRepository.save(submission);
                }
            }

            // 7. Tạo thêm 1 Lô bài hoàn thành (Batch) 10 bài để test Grading History
            Exam examPE202 = examRepository.save(Exam.builder()
                    .examCode("PE_202_Spring26")
                    .term("Spring2026")
                    .examType("FIRST_ATTEMPT")
                    .examPaperUrl("https://prm-assignment.s3.ap-southeast-1.amazonaws.com/mock-exam.pdf")
                    .build());

            List<Rubric> rubricsPE202 = rubricRepository.saveAll(List.of(
                    Rubric.builder().exam(examPE202).requestNo(1).title("Narrative Charter Statement").maxScore(20.0).build(),
                    Rubric.builder().exam(examPE202).requestNo(2).title("Budget Items").maxScore(20.0).build(),
                    Rubric.builder().exam(examPE202).requestNo(3).title("Project Risks").maxScore(30.0).build(),
                    Rubric.builder().exam(examPE202).requestNo(4).title("Project Schedule/WBS").maxScore(30.0).build()
            ));

            Batch batchHistoryTest = batchRepository.save(Batch.builder()
                    .exam(examPE202)
                    .campus(campusHCM)
                    .grader(grader)
                    .status(BatchStatus.COMPLETED)
                    .build());

            for (int i = 1; i <= 10; i++) {
                String ho = hoList[random.nextInt(hoList.length)];
                String dem = demList[random.nextInt(demList.length)];
                String ten = tenList[random.nextInt(tenList.length)];
                String fullName = ho + " " + dem + " " + ten;
                String studentId = "SE" + (150000 + i);

                Student student = studentRepository.save(Student.builder()
                        .studentId(studentId)
                        .fullName(fullName)
                        .build());

                LocalDateTime subTime = LocalDateTime.now().minusDays(5).minusHours(i);

                Submission submission = Submission.builder()
                        .batch(batchHistoryTest)
                        .student(student)
                        .file_url(dummyFilePath)
                        .submissionTime(subTime)
                        .status(SubmissionStatus.GRADED)
                        .build();

                submission = submissionRepository.save(submission);

                double calculatedTotal = 0.0;
                List<Grade> grades = new ArrayList<>();

                for (Rubric rubric : rubricsPE202) {
                    double minScore = rubric.getMaxScore() * 0.7;
                    double awarded = minScore + (random.nextDouble() * (rubric.getMaxScore() - minScore));
                    awarded = Math.round(awarded * 10.0) / 10.0;

                    calculatedTotal += awarded;

                    grades.add(Grade.builder()
                            .submission(submission)
                            .rubric(rubric)
                            .awardedScore(awarded)
                            .comments("Đã hoàn thành chấm bài.")
                            .build());
                }
                gradeRepository.saveAll(grades);

                submission.setTotalScore(Math.round(calculatedTotal * 10.0) / 10.0);
                submissionRepository.save(submission);
            }

            Exam examPE203 = examRepository.save(Exam.builder()
                    .examCode("PE_203_Spring26")
                    .term("Spring2026")
                    .examType("FIRST_ATTEMPT")
                    .examPaperUrl("https://prm-assignment.s3.ap-southeast-1.amazonaws.com/mock-exam.pdf")
                    .build());

            Batch batchNew = batchRepository.save(Batch.builder()
                    .exam(examPE203)
                    .campus(campusHCM)
                    .grader(grader)
                    .status(BatchStatus.IN_PROGRESS)
                    .build());

            for (int i = 1; i <= 10; i++) {
                String ho = hoList[random.nextInt(hoList.length)];
                String dem = demList[random.nextInt(demList.length)];
                String ten = tenList[random.nextInt(tenList.length)];
                String fullName = ho + " " + dem + " " + ten;
                String studentId = "SE" + (160000 + i);

                Student student = studentRepository.save(Student.builder()
                        .studentId(studentId)
                        .fullName(fullName)
                        .build());

                LocalDateTime subTime = LocalDateTime.now().minusDays(1).minusHours(i);

                Submission submission = Submission.builder()
                        .batch(batchNew)
                        .student(student)
                        .file_url(dummyFilePath)
                        .submissionTime(subTime)
                        .status(SubmissionStatus.NOT_GRADED) // Toàn bộ đều chưa chấm
                        .build();

                submissionRepository.save(submission);
            }

            System.out.println("--- KHỞI TẠO DỮ LIỆU THÀNH CÔNG ---");
            System.out.println("Đã tạo 1 lô bài gồm 40 sinh viên, 1 lô lịch sử 10 bài hoàn thành, và 1 lô bài mới 10 bài chưa chấm.");
        }
    }
}