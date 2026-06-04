package com.backend.controller;

import com.backend.dto.LoginRequestDTO;
import com.backend.entity.User;
import com.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class AuthController {
    private final UserRepository userRepository;

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequestDTO request) {
        User user = userRepository.findAll().stream()
                .filter(u -> u.getUsername().equalsIgnoreCase(request.getLecturerId()))
                .findFirst()
                .orElse(null);

        // Code Lab: Xác thực mật khẩu cơ bản (Hardcode kiểm tra)
        if (user != null && request.getPassword().equals("123456")) {
            return ResponseEntity.ok().body("{\"message\": \"Login successful\", \"userId\": " + user.getId() + "}");
        } else {
            return ResponseEntity.status(401).body("{\"message\": \"Sai tài khoản hoặc mật khẩu\"}");
        }
    }
}