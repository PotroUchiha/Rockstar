# Hito de partida: la tienda por capas

Apuntes del hito de partida de la práctica guiada de DWS.

- Enunciado: <https://cesguiro.es/doku.php/clase/daw/dws/practicas/p3>
- Especificación de la tienda: <https://cesguiro.es/doku.php/clase/daw/dws/practicas/p2>

## Qué pide el hito

Una aplicación Spring Boot como en 1.º DAW, con **un único endpoint**: `GET /api/products`, que devuelve los 28 productos de la base de datos en JSON.

| Pieza | Qué se usa |
|---|---|
| Lenguaje y framework | Java 25, Spring Boot 4, Maven |
| Base de datos | MariaDB 12 en Docker |
| Persistencia | JDBC a mano (`PreparedStatement` y `ResultSet`) |
| Capas | `controller` → `domain` → `persistence` |
| Pruebas | Manuales, con `curl` |

## Cómo arrancarlo

```
docker compose up -d          # levanta MariaDB y carga la semilla (3 catálogos, 28 productos)
.\mvnw spring-boot:run        # arranca la aplicación en el puerto 8080
curl http://localhost:8080/api/products
```

No hace falta tener Maven instalado: `mvnw` (el *Maven wrapper*) lo descarga solo.

## La idea general: un restaurante

| Capa | En el restaurante | En el código |
|---|---|---|
| `controller` | El **camarero**: atiende al cliente | Recibe la petición web y devuelve JSON |
| `domain` | La **cocina**: sabe qué es cada plato | Sabe qué es un producto y qué se hace con él |
| `persistence` | El **almacén**: donde se guardan las cosas | Habla con MariaDB |

El almacén tiene dos trabajadores:

- El **mozo** (`ProductDaoJdbc`) baja a la base de datos y saca las filas con SQL.
- El **encargado** (`ProductRepositoryImpl`) convierte esas filas en productos que entiende la cocina.

Recorrido de una petición:

```
curl GET /api/products
  → ProductController.getAll()         (camarero)
  → ProductServiceImpl.getAll()        (cocina)
  → ProductRepositoryImpl.findAll()    (encargado: ProductEntity → Product)
  → ProductDaoJdbc.findAll()           (mozo: SQL con PreparedStatement)
  → MariaDB
```

## Estructura del código

```
es.josemi.shop
├── ShopApplication.java
├── controller
│   └── ProductController.java
├── domain
│   ├── Product.java
│   ├── ProductService.java
│   ├── ProductServiceImpl.java
│   └── ProductRepository.java
└── persistence
    ├── ProductRepositoryImpl.java
    ├── ProductDao.java
    ├── ProductDaoJdbc.java
    └── ProductEntity.java
```

## Las dos ideas más importantes

### 1. Inversión de dependencias

La cocina **no sabe cómo funciona el almacén**. Solo dice "tráeme los productos".

Por eso la interfaz `ProductRepository` está en `domain`, aunque quien la implementa (`ProductRepositoryImpl`) esté en `persistence`:

```
SIN inversión:   domain ──usa──▶ persistence         (el dominio depende de JDBC)

CON inversión:   domain ◀──implementa── persistence  (persistence depende del dominio)
                 [ProductRepository]    [ProductRepositoryImpl]
```

**Para qué sirve:** en el hito 07 se cambia JDBC por JPA y solo se toca `persistence`. `domain` no cambia.

**Cómo comprobarlo:** en los `import` de `domain` no aparece nada de `java.sql`.

### 2. Inyección de dependencias

Ninguna clase hace `new` de las otras. Cada una pide lo que necesita **en su constructor**, y Spring se lo entrega:

```java
public ProductServiceImpl(ProductRepository productRepository) {
    this.productRepository = productRepository;
}
```

Para que Spring cree un objeto (un *bean*), la clase lleva una anotación:

| Anotación | Dónde | Significado |
|---|---|---|
| `@RestController` | `ProductController` | Atiende peticiones web y devuelve JSON |
| `@Service` | `ProductServiceImpl` | Lógica de negocio |
| `@Repository` | `ProductRepositoryImpl`, `ProductDaoJdbc` | Acceso a datos |

Las tres hacen lo mismo ("Spring, crea esto tú"); el nombre indica el papel de la clase.

Si falta una pieza, la aplicación no arranca y Spring da un error como:
*"required a bean of type ProductRepository that could not be found"*.

## Clase por clase

### `domain/Product.java`: el modelo

```java
public record Product(Long id, Long catalogId, String name,
                      String description, BigDecimal price, int stock) { }
```

- Es la ficha de un producto, con los campos de la tabla `products` en camelCase (`catalog_id` → `catalogId`).
- **`record`**: una clase que solo guarda datos. Java crea solo el constructor, los getters (`product.name()`, sin `get`), `equals`, `hashCode` y `toString`. Es **inmutable**: no tiene setters.
- **`BigDecimal` para el precio, no `double`**: `double` comete errores con los decimales (`0.1 + 0.2` da `0.30000000000000004`). Con dinero no vale. `BigDecimal` es exacto y encaja con `DECIMAL(8,2)`.
- **`Long id` (con mayúscula)**: admite `null`, útil para productos nuevos que aún no tienen id, porque lo pone la base de datos con `AUTO_INCREMENT`.
- Todavía no hay validaciones (precio positivo, stock no negativo): llegan en el hito 05 con los value objects `Money` y `Stock`.

### `domain/ProductRepository.java`: lo que el dominio necesita

```java
public interface ProductRepository {
    List<Product> findAll();
}
```

Un contrato: "quien sea el repositorio tiene que saber devolver todos los productos". Dice el **qué**, no el **cómo**. No menciona SQL ni JDBC.

### `domain/ProductService.java` y `ProductServiceImpl.java`: lo que el dominio ofrece

- `ProductRepository` es lo que el dominio **necesita** de fuera.
- `ProductService` es lo que el dominio **ofrece** hacia fuera, al controlador.

`ProductServiceImpl` de momento solo delega en el repositorio. Aquí irá la lógica de negocio cuando la haya (por ejemplo, reservar stock en el hito 06).

### `persistence/ProductEntity.java`: una fila de la tabla

Ahora es igual que `Product`, pero se separan a propósito: en el hito 05 `Product` usará `Money` y `Stock`, mientras que `ProductEntity` seguirá siendo una copia exacta de la tabla.

### `persistence/ProductDao.java` y `ProductDaoJdbc.java`: el SQL

```java
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
```

- **`DataSource`**: el "grifo" de conexiones. Spring lo crea con los datos de `application.properties` (por eso el proyecto lleva el starter `jdbc`) y lo inyecta.
- **`Connection`** abre la conexión, **`PreparedStatement`** prepara la consulta y **`ResultSet`** es el resultado, que se recorre fila a fila con `next()`.
- **`try (...)`** (*try-with-resources*): cierra los tres automáticamente, aunque haya error. Si no se cierran, la aplicación se queda sin conexiones.
- **`catch (SQLException e)`**: JDBC lanza `SQLException` y Java obliga a tratarla. Se envuelve en una `RuntimeException` para que las capas de arriba no tengan que saber nada de SQL. Los errores bonitos (404, 409…) llegan en el hito 05.
- **`toEntity`** lee cada columna por su nombre: `getLong("catalog_id")`, `getBigDecimal("price")`…
- El SQL va en un *text block* (`"""`) y lleva `ORDER BY id` para que el orden sea siempre el mismo.

### `persistence/ProductRepositoryImpl.java`: el encargado

```java
public class ProductRepositoryImpl implements ProductRepository {
    ...
    public List<Product> findAll() {
        return productDao.findAll().stream()
                .map(this::toDomain)
                .toList();
    }
}
```

- `implements ProductRepository`: aquí se ve la inversión de dependencias. `persistence` conoce a `domain`, pero no al revés.
- Pide las filas al DAO y convierte cada `ProductEntity` en `Product` con `toDomain`.

### `controller/ProductController.java`: el camarero

```java
@RestController
@RequestMapping("/api/products")
public class ProductController {
    ...
    @GetMapping
    public List<Product> getAll() {
        return productService.getAll();
    }
}
```

- `@RequestMapping("/api/products")`: la dirección que atiende.
- `@GetMapping`: responde a peticiones `GET` ("dame datos").
- Spring convierte la lista a JSON automáticamente.
- Solo conoce la interfaz `ProductService`. No piensa: traslada el pedido a la cocina.

## Comprobación del hito

| Criterio | Resultado |
|---|---|
| `docker compose up -d` carga 3 catálogos y 28 productos | ✔ |
| `curl http://localhost:8080/api/products` devuelve los 28 productos con `catalogId` | ✔ |
| `domain` no menciona JDBC; `persistence` implementa su interfaz | ✔ |
| Commit y tag `partida` | ✔ |

## Notas del entorno

- Solo está instalado el JDK 27; compila sin problema para Java 25 (`<java.version>25</java.version>` en el `pom.xml`).
- El contenedor `game-store-mysql` de otro proyecto también usa el puerto 3306. Para arrancar este hay que pararlo (`docker stop game-store-mysql`) y luego se puede volver a arrancar (`docker start game-store-mysql`).

## Siguiente: hito 04 (API First)

`GET /api/products` desaparece. Se diseña **primero el contrato OpenAPI** de catálogos y productos, con listado paginado y Swagger UI, y luego se implementa.
