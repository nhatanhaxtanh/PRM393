package com.backend.service;

import com.backend.dto.GradeItemDTO;
import com.backend.entity.Rubric;
import com.backend.repository.RubricRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
@RequiredArgsConstructor
@Slf4j
public class AIGradingService {

    private final WebClient.Builder webClientBuilder;
    private final RubricRepository rubricRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Value("${groq.api.url}")
    private String groqApiUrl;

    @Value("${groq.api.key}")
    private String groqApiKey;

    private WebClient getWebClient() {
        return webClientBuilder.build();
    }

    public Mono<List<GradeItemDTO>> autoGrade(Long examId, String studentSubmissionText) {
        // Fetch rubrics for this exam
        List<Rubric> rubrics = rubricRepository.findByExamId(examId).stream()
                .sorted(Comparator.comparing(Rubric::getRequestNo))
                .toList();
        
        if (rubrics.isEmpty()) {
            return Mono.error(new RuntimeException("No rubrics found for exam"));
        }
        if (groqApiKey == null || groqApiKey.isBlank()) {
            return Mono.error(new RuntimeException("Groq API key is not configured"));
        }

        // Build prompt for AI
        String prompt = buildGradingPrompt(rubrics, studentSubmissionText);

        // Call Groq API
        Map<String, Object> requestBody = Map.of(
            "model", "openai/gpt-oss-20b",
            "input", prompt,
            "temperature", 0
        );

        log.info("Sending auto-grading request to Groq API for exam {}", examId);

        return getWebClient().post()
                .uri(groqApiUrl)
                .headers(headers -> {
                    headers.setBearerAuth(groqApiKey);
                    headers.set("Content-Type", "application/json");
                })
                .bodyValue(requestBody)
                .retrieve()
                .onStatus(status -> status.is4xxClientError(), response -> {
                    return response.bodyToMono(String.class)
                        .defaultIfEmpty("No error body")
                        .map(body -> new RuntimeException("Groq API Error: " + response.statusCode() + " - " + body));
                })
                .bodyToMono(String.class)
                .map(response -> {
                    log.debug("Received response from Groq API: {}", response);
                    return parseAIResponse(response, rubrics);
                })
                .onErrorResume(e -> {
                    log.error("Error calling Groq API", e);
                    return Mono.error(new RuntimeException("Failed to get AI grading: " + e.getMessage()));
                });
    }

    private String buildGradingPrompt(List<Rubric> rubrics, String submissionText) {
        StringBuilder prompt = new StringBuilder();
        prompt.append("Please grade the following student submission based on these rubric criteria:\n\n");
        
        for (Rubric rubric : rubrics) {
            prompt.append(String.format(
                "Request %d: %s (Max Score: %.1f)\n",
                rubric.getRequestNo(),
                rubric.getTitle(),
                rubric.getMaxScore()
            ));
        }
        
        prompt.append("\nStudent Submission:\n");
        prompt.append(submissionText);
        prompt.append("\n\nReturn only this valid JSON object. Do not include markdown or explanations:\n");
        prompt.append("{\"grades\":[");
        prompt.append("{\"requestNo\":1,\"awardedScore\":15.5,\"comments\":\"Good work on...\"},");
        prompt.append("{\"requestNo\":2,\"awardedScore\":18.0,\"comments\":\"Excellent...\"}");
        prompt.append("]}\n\n");
        prompt.append("Ensure the awardedScore does not exceed the maxScore for each request.");
        
        return prompt.toString();
    }

    private List<GradeItemDTO> parseAIResponse(String response, List<Rubric> rubrics) {
        try {
            String gradingJson = extractGradingJson(response)
                    .orElseThrow(() -> new RuntimeException("AI response did not contain a JSON grading array"));

            List<GradeItemDTO> rawGrades = objectMapper.readValue(
                    gradingJson,
                    new TypeReference<List<GradeItemDTO>>() {}
            );

            return normalizeGrades(rawGrades, rubrics);
        } catch (Exception e) {
            log.warn("Could not parse AI response as JSON. Falling back to text parsing.", e);
            return parsePlainTextOrManualReview(response, rubrics);
        }
    }

    private Optional<String> extractGradingJson(String response) throws JsonProcessingException {
        JsonNode root = objectMapper.readTree(response);

        if (root.isArray()) {
            return Optional.of(root.toString());
        }

        Optional<String> directGrades = findArrayField(root, "grades")
                .or(() -> findArrayField(root, "items"));
        if (directGrades.isPresent()) {
            return directGrades;
        }

        Optional<String> outputText = findTextField(root, "output_text")
                .or(() -> findTextField(root, "text"))
                .or(() -> Optional.of(response));

        String text = outputText.get().trim();
        Optional<String> jsonArray = extractJsonArray(text);
        if (jsonArray.isPresent()) {
            return jsonArray;
        }

        Optional<String> jsonObject = extractJsonObject(text);
        if (jsonObject.isPresent()) {
            JsonNode object = objectMapper.readTree(jsonObject.get());
            return findArrayField(object, "grades")
                    .or(() -> findArrayField(object, "items"));
        }

        return Optional.empty();
    }

    private Optional<String> extractJsonArray(String text) {
        int start = text.indexOf('[');
        int end = text.lastIndexOf(']');
        if (start < 0 || end <= start) {
            return Optional.empty();
        }
        return Optional.of(text.substring(start, end + 1));
    }

    private Optional<String> extractJsonObject(String text) {
        int start = text.indexOf('{');
        int end = text.lastIndexOf('}');
        if (start < 0 || end <= start) {
            return Optional.empty();
        }
        return Optional.of(text.substring(start, end + 1));
    }

    private Optional<String> findArrayField(JsonNode node, String fieldName) {
        if (node == null || node.isNull()) {
            return Optional.empty();
        }
        if (node.has(fieldName) && node.get(fieldName).isArray()) {
            return Optional.of(node.get(fieldName).toString());
        }
        if (node.isObject()) {
            var fields = node.fields();
            while (fields.hasNext()) {
                Optional<String> result = findArrayField(fields.next().getValue(), fieldName);
                if (result.isPresent()) {
                    return result;
                }
            }
        }
        if (node.isArray()) {
            for (JsonNode child : node) {
                Optional<String> result = findArrayField(child, fieldName);
                if (result.isPresent()) {
                    return result;
                }
            }
        }
        return Optional.empty();
    }

    private Optional<String> findTextField(JsonNode node, String fieldName) {
        if (node == null || node.isNull()) {
            return Optional.empty();
        }
        if (node.has(fieldName) && node.get(fieldName).isTextual()) {
            return Optional.of(node.get(fieldName).asText());
        }
        if (node.isObject()) {
            var fields = node.fields();
            while (fields.hasNext()) {
                Optional<String> result = findTextField(fields.next().getValue(), fieldName);
                if (result.isPresent()) {
                    return result;
                }
            }
        }
        if (node.isArray()) {
            for (JsonNode child : node) {
                Optional<String> result = findTextField(child, fieldName);
                if (result.isPresent()) {
                    return result;
                }
            }
        }
        return Optional.empty();
    }

    private List<GradeItemDTO> parsePlainTextOrManualReview(String response, List<Rubric> rubrics) {
        List<String> textFields = new ArrayList<>();
        try {
            collectTextFields(objectMapper.readTree(response), textFields);
        } catch (Exception ignored) {
            textFields.add(response);
        }

        String text = String.join("\n", textFields);
        List<GradeItemDTO> parsedGrades = new ArrayList<>();

        for (Rubric rubric : rubrics) {
            Optional<Double> score = extractScoreForRequest(text, rubric);
            score.ifPresent(value -> parsedGrades.add(GradeItemDTO.builder()
                    .requestNo(rubric.getRequestNo())
                    .awardedScore(Math.round(Math.max(0.0, Math.min(value, rubric.getMaxScore())) * 10.0) / 10.0)
                    .comments("AI graded from non-JSON response. Please review.")
                    .build()));
        }

        if (!parsedGrades.isEmpty()) {
            return normalizeGrades(parsedGrades, rubrics);
        }

        return rubrics.stream()
                .map(rubric -> GradeItemDTO.builder()
                        .requestNo(rubric.getRequestNo())
                        .awardedScore(0.0)
                        .comments("AI response could not be parsed. Please review and enter score manually.")
                        .build())
                .toList();
    }

    private void collectTextFields(JsonNode node, List<String> values) {
        if (node == null || node.isNull()) {
            return;
        }
        if (node.isTextual()) {
            String value = node.asText();
            if (value.contains("Request") || value.contains("requestNo") || value.contains("score")) {
                values.add(value);
            }
            return;
        }
        if (node.isObject()) {
            var fields = node.fields();
            while (fields.hasNext()) {
                collectTextFields(fields.next().getValue(), values);
            }
            return;
        }
        if (node.isArray()) {
            for (JsonNode child : node) {
                collectTextFields(child, values);
            }
        }
    }

    private Optional<Double> extractScoreForRequest(String text, Rubric rubric) {
        Pattern requestBlockPattern = Pattern.compile(
                "(?is)(?:request\\s*" + rubric.getRequestNo() + "|requestNo\\D*" + rubric.getRequestNo() + ").{0,500}"
        );
        Matcher blockMatcher = requestBlockPattern.matcher(text);
        if (!blockMatcher.find()) {
            return Optional.empty();
        }

        String block = blockMatcher.group();
        Pattern scorePattern = Pattern.compile(
                "(?i)(?:awardedScore|awarded score|score|points?)\\D{0,30}(\\d+(?:\\.\\d+)?)"
        );
        Matcher scoreMatcher = scorePattern.matcher(block);
        if (scoreMatcher.find()) {
            return Optional.of(Double.parseDouble(scoreMatcher.group(1)));
        }

        Pattern slashPattern = Pattern.compile("(\\d+(?:\\.\\d+)?)\\s*/\\s*" + Pattern.quote(rubric.getMaxScore().toString()));
        Matcher slashMatcher = slashPattern.matcher(block);
        if (slashMatcher.find()) {
            return Optional.of(Double.parseDouble(slashMatcher.group(1)));
        }

        return Optional.empty();
    }

    private List<GradeItemDTO> normalizeGrades(List<GradeItemDTO> rawGrades, List<Rubric> rubrics) {
        Map<Integer, GradeItemDTO> byRequestNo = new HashMap<>();
        for (GradeItemDTO grade : rawGrades) {
            if (grade.getRequestNo() != null) {
                byRequestNo.put(grade.getRequestNo(), grade);
            }
        }

        List<GradeItemDTO> grades = new ArrayList<>();
        for (Rubric rubric : rubrics) {
            GradeItemDTO grade = byRequestNo.get(rubric.getRequestNo());
            double awardedScore = grade == null || grade.getAwardedScore() == null
                    ? 0.0
                    : grade.getAwardedScore();
            awardedScore = Math.max(0.0, Math.min(awardedScore, rubric.getMaxScore()));
            awardedScore = Math.round(awardedScore * 10.0) / 10.0;

            String comments = grade == null || grade.getComments() == null || grade.getComments().isBlank()
                    ? "AI did not provide comments for this request."
                    : grade.getComments().trim();

            grades.add(GradeItemDTO.builder()
                    .requestNo(rubric.getRequestNo())
                    .awardedScore(awardedScore)
                    .comments(comments)
                    .build());
        }
        return grades;
    }
}
