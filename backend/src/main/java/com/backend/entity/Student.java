package com.backend.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "students")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Student {
    @Id
    @Column(name = "student_id", length = 20)
    private String studentId; // MSSV

    @Column(name = "full_name", nullable = false)
    private String fullName;
}