package com.backend.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "exams")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Exam {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "exam_code", nullable = false, unique = true)
    private String examCode; // Ví dụ: PE_201_Spring26

    @Column(length = 50)
    private String term; // Spring2026

    @Column(name = "exam_type", length = 50)
    private String examType; // FIRST_ATTEMPT, RETAKE

    @Column(name = "exam_paper_url", length = 500)
    private String examPaperUrl;
}