package com.backend.controller;

import com.backend.dto.ApiResponse;
import com.backend.dto.UserProfileDTO;
import com.backend.entity.User;
import com.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class UserController {

    private final UserRepository userRepository;

    @GetMapping("/me")
    public ResponseEntity<ApiResponse> getMyProfile(@RequestParam Long lecturerId) {
        User user = userRepository.findById(lecturerId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy User"));

        UserProfileDTO profile = UserProfileDTO.builder()
                .username(user.getUsername())
                .fullName(user.getFullName())
                .role(user.getRole())
                .build();

        return ResponseEntity.ok(ApiResponse.success(profile));
    }

    @GetMapping
    public ResponseEntity<ApiResponse> getAllUsers() {
        List<UserProfileDTO> users = userRepository.findAll().stream()
                .map(u -> UserProfileDTO.builder()
                        .username(u.getUsername())
                        .email(u.getEmail())
                        .fullName(u.getFullName())
                        .role(u.getRole())
                        .campusName(u.getCampus() != null ? u.getCampus().getCampusName() : "System / Global")
                        .build())
                .toList();
        return ResponseEntity.ok(ApiResponse.success(users));
    }
}