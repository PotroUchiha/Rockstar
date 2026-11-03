package es.josemi.shop.persistence;

import java.math.BigDecimal;

public record ProductEntity(
        Long id,
        Long catalogId,
        String name,
        String description,
        BigDecimal price,
        int stock
) {
}
