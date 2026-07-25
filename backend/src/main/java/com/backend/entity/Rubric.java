package com.backend.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "rubrics")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Rubric {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "exam_id", nullable = false)
    private Exam exam;

    @Column(name = "request_no", nullable = false)
    private Integer requestNo;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(name = "max_score", nullable = false)
    private Double maxScore;
}