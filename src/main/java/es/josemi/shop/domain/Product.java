package es.josemi.shop.domain;

import java.math.BigDecimal;

public record Product(
        Long id,
        Long catalogId,
        String name,
        String description,
        BigDecimal price,
        int stock
) {
}
