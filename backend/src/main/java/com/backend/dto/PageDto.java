package com.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.domain.Page;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PageDto {
    private int size;
    private int page;
    private int totalPage;
    private long totalElements;
    private boolean first;
    private boolean last;
    private Object content;

    public static PageDto from(Page<?> springPage) {
        return PageDto.builder()
                .size(springPage.getSize())
                .page(springPage.getNumber())
                .totalPage(springPage.getTotalPages())
                .totalElements(springPage.getTotalElements())
                .first(springPage.isFirst())
                .last(springPage.isLast())
                .content(springPage.getContent())
                .build();
    }
}