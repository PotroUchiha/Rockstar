package es.josemi.shop.persistence;

import java.util.List;

import org.springframework.stereotype.Repository;

import es.josemi.shop.domain.Product;
import es.josemi.shop.domain.ProductRepository;

@Repository
public class ProductRepositoryImpl implements ProductRepository {

    private final ProductDao productDao;

    public ProductRepositoryImpl(ProductDao productDao) {
        this.productDao = productDao;
    }

    @Override
    public List<Product> findAll() {
        return productDao.findAll().stream()
                .map(this::toDomain)
                .toList();
    }

    private Product toDomain(ProductEntity entity) {
        return new Product(
                entity.id(),
                entity.catalogId(),
                entity.name(),
                entity.description(),
                entity.price(),
                entity.stock()
        );
    }
}
