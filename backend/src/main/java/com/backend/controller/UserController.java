package com.backend.controller;

import com.backend.dto.UserProfileDTO;
import com.backend.entity.User;
import com.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class UserController {

    private final UserRepository userRepository;

    @GetMapping("/me")
    public ResponseEntity<UserProfileDTO> getMyProfile() {
        Long currentLecturerId = 1L; // Mock ID đang đăng nhập

        User user = userRepository.findById(currentLecturerId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy User"));

        UserProfileDTO profile = UserProfileDTO.builder()
                .username(user.getUsername())
                .fullName(user.getFullName())
                .role(user.getRole())
                .build();

        return ResponseEntity.ok(profile);
    }
}