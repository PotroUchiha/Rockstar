package es.josemi.shop.persistence;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import javax.sql.DataSource;

import org.springframework.stereotype.Repository;

@Repository
public class ProductDaoJdbc implements ProductDao {

    private static final String FIND_ALL = """
            SELECT id, catalog_id, name, description, price, stock
            FROM products
            ORDER BY id
            """;

    private final DataSource dataSource;

    public ProductDaoJdbc(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    @Override
    public List<ProductEntity> findAll() {
        try (Connection connection = dataSource.getConnection();
             PreparedStatement statement = connection.prepareStatement(FIND_ALL);
             ResultSet resultSet = statement.executeQuery()) {

            List<ProductEntity> products = new ArrayList<>();
            while (resultSet.next()) {
                products.add(toEntity(resultSet));
            }
            return products;

        } catch (SQLException e) {
            throw new RuntimeException("Could not read products", e);
        }
    }

    private ProductEntity toEntity(ResultSet resultSet) throws SQLException {
        return new ProductEntity(
                resultSet.getLong("id"),
                resultSet.getLong("catalog_id"),
                resultSet.getString("name"),
                resultSet.getString("description"),
                resultSet.getBigDecimal("price"),
                resultSet.getInt("stock")
        );
    }
}
