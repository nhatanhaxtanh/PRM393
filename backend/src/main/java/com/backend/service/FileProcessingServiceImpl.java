package com.backend.service.impl;

import com.backend.service.FileProcessingService;
import org.apache.poi.xwpf.extractor.XWPFWordExtractor;
import org.apache.poi.xwpf.usermodel.XWPFDocument;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;

import java.io.InputStream;

@Service
public class FileProcessingServiceImpl implements FileProcessingService {

    @Override
    public String processSubmissionFile(String filePath) {
        try {
            // Lấy file trực tiếp từ thư mục resources của Spring Boot
            ClassPathResource resource = new ClassPathResource(filePath);

            if (!resource.exists()) {
                return "<h2>Lỗi: Không tìm thấy file bài làm!</h2><p>Đường dẫn: " + filePath + "</p>";
            }

            // Đọc nội dung file Word (.docx)
            try (InputStream is = resource.getInputStream();
                 XWPFDocument document = new XWPFDocument(is);
                 XWPFWordExtractor extractor = new XWPFWordExtractor(document)) {

                String rawText = extractor.getText();

                // Format nhẹ lại (đổi \n thành <br>) để Flutter render HTML cho đẹp
                return rawText.replace("\n", "<br>");
            }

        } catch (Exception e) {
            e.printStackTrace();
            return "<h2>Lỗi khi đọc file Word:</h2><p>" + e.getMessage() + "</p>";
        }
    }
}