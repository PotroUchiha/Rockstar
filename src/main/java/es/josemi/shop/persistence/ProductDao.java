package es.josemi.shop.persistence;

import java.util.List;

public interface ProductDao {

    List<ProductEntity> findAll();
}
