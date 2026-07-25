package com.backend.controller;

import com.backend.entity.*;
import com.backend.enums.BatchStatus;
import com.backend.repository.*;
import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.UserRecord;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.io.InputStream;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
@CrossOrigin("*")
public class AdminController {

    private final BatchRepository batchRepository;
    private final ExamRepository examRepository;
    private final UserRepository userRepository;
    private final CampusRepository campusRepository;
    private final SubmissionRepository submissionRepository;
    private final GradeRepository gradeRepository;

    @PostConstruct
    public void initFirebase() {
        try {
            if (FirebaseApp.getApps().isEmpty()) {
                InputStream serviceAccount = getClass().getClassLoader().getResourceAsStream("serviceAccountKey.json");

                if (serviceAccount == null) {
                    System.err.println("❌ LỖI NGHIÊM TRỌNG: Không tìm thấy file serviceAccountKey.json trong thư mục resources!");
                    return;
                }

                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                        .build();
                FirebaseApp.initializeApp(options);
                System.out.println("✅ FIREBASE ADMIN SDK KHỞI TẠO THÀNH CÔNG!");
            }
        } catch (Exception e) {
            System.err.println("❌ LỖI KHỞI TẠO FIREBASE:");
            e.printStackTrace();
        }
    }

    @PostMapping("/assign")
    public ResponseEntity<?> assignBatchAndNotify(@RequestBody Map<String, Object> payload) {
        Long batchId = Long.valueOf(payload.get("batchId").toString());
        String lecturerId = (String) payload.get("lecturerId");

        try {
            Optional<User> graderOpt = userRepository.findByUsername(lecturerId);
            if (graderOpt.isEmpty()) {
                return ResponseEntity.status(404).body(Map.of("status", 404, "error", "Khong tim thay giang vien " + lecturerId));
            }
            User grader = graderOpt.get();

            Optional<Batch> batchOpt = batchRepository.findById(batchId);
            if (batchOpt.isEmpty()) {
                return ResponseEntity.status(404).body(Map.of("status", 404, "error", "Khong tim thay lo bai " + batchId));
            }
            Batch batch = batchOpt.get();

            batch.setGrader(grader);
            batch.setStatus(BatchStatus.IN_PROGRESS);
            batchRepository.save(batch);

            String examCode = batch.getExam().getExamCode();
            String targetDeviceToken = System.getenv("TOKEN");
            if (targetDeviceToken != null) {
                Message message = Message.builder()
                        .setToken(targetDeviceToken)
                        .setNotification(Notification.builder()
                                .setTitle("Phan cong lo bai: " + examCode)
                                .setBody("He thong vua giao cho ban lo bai " + examCode + ". Mo app de xem ngay!")
                                .build())
                        .build();
                FirebaseMessaging.getInstance().send(message);
            }
            return ResponseEntity.ok(Map.of("status", 200, "message", "Assign successfully"));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(Map.of("status", 500, "error", "Loi server: " + e.getMessage()));
        }
    }

    @PostMapping("/create-user")
    public ResponseEntity<?> createUser(@RequestBody Map<String, String> payload) {
        String username = payload.get("username");
        String email = payload.get("email");
        String password = payload.get("password");
        String fullName = payload.get("fullName");
        String role = payload.get("role");
        String campusCode = payload.get("campusCode");

        try {
            // 1. TẠO TÀI KHOẢN TRÊN FIREBASE AUTH (Quyền Admin)
            UserRecord.CreateRequest request = new UserRecord.CreateRequest()
                    .setEmail(email)
                    .setPassword(password) // Firebase yêu cầu mật khẩu tối thiểu 6 ký tự
                    .setDisplayName(fullName);

            UserRecord firebaseUser = FirebaseAuth.getInstance().createUser(request);

            // 2. LƯU ĐỒNG BỘ VÀO DATABASE SPRING BOOT
            // Tìm thông tin Cơ sở (Campus)
            Campus campus = campusRepository.findByCampusCode(campusCode).orElse(null);

            User newUser = User.builder()
                    .username(username)
                    .email(email)
                    .passwordHash(password)
                    .fullName(fullName)
                    .role(role)
                    .campus(campus)
                    .status("ACTIVE")
                    .build();

            userRepository.save(newUser);

            return ResponseEntity.ok(Map.of(
                    "status", 200,
                    "message", "Đã tạo tài khoản thành công trên cả Firebase và DB!",
                    "firebaseUid", firebaseUser.getUid()
            ));

        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(Map.of("status", 500, "error", "Lỗi tạo tài khoản: " + e.getMessage()));
        }
    }

    // API Sửa thông tin User
    @PutMapping("/update-user")
    public ResponseEntity<?> updateUser(@RequestBody Map<String, String> payload) {
        String email = payload.get("email");
        String fullName = payload.get("fullName");
        String role = payload.get("role");

        try {
            // 1. Cập nhật trong DB SQL
            Optional<User> userOpt = userRepository.findByEmail(email);
            if (userOpt.isEmpty()) {
                return ResponseEntity.status(404).body(Map.of("error", "Không tìm thấy User trong Database"));
            }
            User user = userOpt.get();
            user.setFullName(fullName);
            user.setRole(role);
            userRepository.save(user);

            // 2. Cập nhật Display Name trên Firebase
            UserRecord firebaseUser = FirebaseAuth.getInstance().getUserByEmail(email);
            UserRecord.UpdateRequest request = new UserRecord.UpdateRequest(firebaseUser.getUid())
                    .setDisplayName(fullName);
            FirebaseAuth.getInstance().updateUser(request);

            return ResponseEntity.ok(Map.of("status", 200, "message", "Cập nhật thành công"));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(Map.of("error", "Lỗi: " + e.getMessage()));
        }
    }

    @PostMapping("/disable-user")
    public ResponseEntity<?> disableUser(@RequestBody Map<String, String> payload) {
        String email = payload.get("email");

        try {
            UserRecord firebaseUser = FirebaseAuth.getInstance().getUserByEmail(email);
            UserRecord.UpdateRequest request = new UserRecord.UpdateRequest(firebaseUser.getUid())
                    .setDisabled(true);
            FirebaseAuth.getInstance().updateUser(request);

            Optional<User> userOpt = userRepository.findByEmail(email);
            if (userOpt.isPresent()) {
                User user = userOpt.get();
                user.setStatus("DISABLED");
                userRepository.save(user);
            }

            return ResponseEntity.ok(Map.of("status", 200, "message", "Tài khoản đã bị vô hiệu hóa"));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(Map.of("error", "Lỗi khóa tài khoản: " + e.getMessage()));
        }
    }

    @PostMapping("/enable-user")
    public ResponseEntity<?> enableUser(@RequestBody Map<String, String> payload) {
        String email = payload.get("email");

        try {
            UserRecord firebaseUser = FirebaseAuth.getInstance().getUserByEmail(email);
            UserRecord.UpdateRequest request = new UserRecord.UpdateRequest(firebaseUser.getUid())
                    .setDisabled(false);
            FirebaseAuth.getInstance().updateUser(request);

            Optional<User> userOpt = userRepository.findByEmail(email);
            if (userOpt.isPresent()) {
                User user = userOpt.get();
                user.setStatus("ACTIVE");
                userRepository.save(user);
            }

            return ResponseEntity.ok(Map.of("status", 200, "message", "Tài khoản đã được mở khóa"));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(Map.of("error", "Lỗi mở khóa tài khoản: " + e.getMessage()));
        }
    }

    @PostMapping("/cancel-batch")
    public ResponseEntity<?> cancelBatch(@RequestBody Map<String, Integer> payload) {
        Long batchId = payload.get("batchId").longValue();
        try {
            Optional<Batch> batchOpt = batchRepository.findById(batchId);
            if (batchOpt.isEmpty()) {
                return ResponseEntity.status(404).body(Map.of("error", "Không tìm thấy lô bài"));
            }

            // FIX LỖI FOREIGN KEY: Xóa toàn bộ Grade và Submission con trước khi xóa Batch
            List<Submission> submissions = submissionRepository.findByBatchId(batchId);
            for (Submission sub : submissions) {
                gradeRepository.deleteBySubmissionId(sub.getId());
                submissionRepository.delete(sub);
            }

            // Cuối cùng mới an toàn xóa Batch
            batchRepository.deleteById(batchId);
            return ResponseEntity.ok(Map.of("status", 200, "message", "Hủy lô bài thành công"));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(Map.of("error", "Lỗi hủy: " + e.getMessage()));
        }
    }

    @PostMapping("/reassign-batch")
    public ResponseEntity<?> reassignBatch(@RequestBody Map<String, Object> payload) {
        Long batchId = ((Integer) payload.get("batchId")).longValue();
        String lecturerUsername = (String) payload.get("lecturerId");
        try {
            Optional<Batch> batchOpt = batchRepository.findById(batchId);
            if (batchOpt.isEmpty()) {
                return ResponseEntity.status(404).body(Map.of("error", "Không tìm thấy lô bài"));
            }
            Optional<User> newGraderOpt = userRepository.findByUsername(lecturerUsername);
            if (newGraderOpt.isEmpty()) {
                return ResponseEntity.status(404).body(Map.of("error", "Không tìm thấy Giảng viên mới"));
            }

            Batch batch = batchOpt.get();
            User newGrader = newGraderOpt.get();

            batch.setGrader(newGrader);
            batch.setCampus(newGrader.getCampus());

            batchRepository.save(batch);
            return ResponseEntity.ok(Map.of("status", 200, "message", "Đổi người chấm thành công"));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(Map.of("error", "Lỗi đổi người: " + e.getMessage()));
        }
    }

    @PostMapping("/remind")
    public ResponseEntity<?> sendReminder(@RequestBody Map<String, String> payload) {
        String examCode = payload.get("examCode");
        String targetDeviceToken = System.getenv("TOKEN");
        try {
            Message message = Message.builder()
                    .setToken(targetDeviceToken)
                    .setNotification(Notification.builder()
                            .setTitle("Nhắc nhở chấm bài: " + examCode)
                            .setBody("Quản trị viên nhắc bạn chấm gấp lô bài " + examCode + "!")
                            .build())
                    .build();
            String response = FirebaseMessaging.getInstance().send(message);
            return ResponseEntity.ok(Map.of("status", 200, "message", "Push sent: " + response));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(Map.of("status", 500, "error", "Lỗi FCM: " + e.getMessage()));
        }
    }
}