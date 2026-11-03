package es.josemi.shop.domain;

import java.util.List;

public interface ProductRepository {

    List<Product> findAll();
}
