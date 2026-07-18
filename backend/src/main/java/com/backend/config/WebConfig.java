package com.backend.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Bean
    public WebClient.Builder webClientBuilder() {
        return WebClient.builder();
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // Serve static files from classpath
        registry.addResourceHandler("/**")
                .addResourceLocations("classpath:/static/");
        
        // Explicitly map PDF files
        registry.addResourceHandler("/mock-exam.pdf")
                .addResourceLocations("classpath:/static/mock-exam.pdf");
    }
}
