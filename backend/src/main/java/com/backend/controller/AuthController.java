package com.backend.controller;

import com.backend.dto.ApiResponse;
import com.backend.dto.LoginRequestDTO;
import com.backend.entity.User;
import com.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class AuthController {

    private final UserRepository userRepository;

    @PostMapping("/login")
    public ResponseEntity<ApiResponse> login(@RequestBody LoginRequestDTO loginRequest) {
        String targetUsername = loginRequest.getUsername() != null ? loginRequest.getUsername() : loginRequest.getLecturerId();
        User user = userRepository.findByUsername(targetUsername).orElse(null);

        if (user == null || !user.getPasswordHash().equals(loginRequest.getPassword())) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.error(401, "Tài khoản hoặc mật khẩu không chính xác"));
        }
        return ResponseEntity.ok(ApiResponse.success(user));
    }

    @PostMapping("/login/firebase")
    public ResponseEntity<ApiResponse> loginWithFirebase(@RequestBody Map<String, String> request) {
        String email = request.get("email");
        User user = userRepository.findByEmail(email).orElse(null);

        if (user == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.error(401, "Tài khoản không tồn tại trong hệ thống nội bộ."));
        }
        return ResponseEntity.ok(ApiResponse.success(user));
    }
}