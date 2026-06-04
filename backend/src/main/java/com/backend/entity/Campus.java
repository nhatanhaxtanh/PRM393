package com.backend.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "campuses")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Campus {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "campus_code", nullable = false, unique = true, length = 10)
    private String campusCode; // HCM, HN, DN

    @Column(name = "campus_name")
    private String campusName;
}