CREATE TABLE catalogs (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(80)  NOT NULL UNIQUE,
    description VARCHAR(240) NOT NULL
);

CREATE TABLE products (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    catalog_id  BIGINT       NOT NULL,
    name        VARCHAR(80)  NOT NULL,
    description VARCHAR(240) NOT NULL,
    price       DECIMAL(8,2) NOT NULL,
    stock       INT          NOT NULL,
    FOREIGN KEY (catalog_id) REFERENCES catalogs (id)
);

INSERT INTO catalogs (name, description) VALUES
    ('Periféricos', 'Entrada y salida para el escritorio'),
    ('Pantallas',   'Monitores y proyección'),
    ('Accesorios',  'El resto del escritorio');

INSERT INTO products (catalog_id, name, description, price, stock) VALUES
    (1, 'Teclado mecánico',       'Mecánico, inalámbrico',           54.90, 20),
    (1, 'Ratón vertical',         'Ergonómico, 6 botones',           39.95, 35),
    (1, 'Ratón inalámbrico',      'Silencioso, 2,4 GHz',             24.90, 40),
    (1, 'Trackball',              'Cursor con pulgar',               44.50, 15),
    (1, 'Teclado numérico',       'Inalámbrico, 19 teclas',          29.90, 18),
    (1, 'Panel de control',       '15 teclas programables',         149.00,  8),
    (1, 'Micrófono USB',          'Cardioide, con soporte',          69.00, 18),
    (1, 'Webcam 1080p',           'Full HD, enfoque automático',     49.90, 25),
    (1, 'Webcam 4K',              'UHD, HDR',                       129.00, 10),
    (1, 'Auriculares con micro',  'Diadema, cancelación',            59.95, 30),
    (1, 'Altavoces 2.1',          'Subwoofer, 40 W',                 79.00, 12),
    (1, 'Auriculares gaming',     'Inalámbricos, 7.1',               89.90, 14),
    (2, 'Monitor 27"',            'IPS, 75 Hz',                     189.00, 12),
    (2, 'Monitor 24"',            'IPS, 100 Hz',                    139.00, 20),
    (2, 'Monitor 32" 4K',         'UHD, 60 Hz',                     329.00,  7),
    (2, 'Monitor 34" ultrawide',  'Curvo, 100 Hz',                  449.00,  5),
    (2, 'Monitor 25" de oficina', 'IPS, pivotante',                 175.00, 16),
    (2, 'Monitor curvo 27"',      'VA, 165 Hz',                     259.00,  9),
    (2, 'Monitor portátil',       '15,6", USB-C',                   219.00, 11),
    (2, 'Proyector compacto',     '1080p, 4000 lúmenes',            499.00,  4),
    (3, 'Base portátil',          'Aluminio, ventilación',           24.50, 50),
    (3, 'Alfombrilla XXL',        '90 x 40 cm, bordes cosidos',      19.95, 60),
    (3, 'Hub USB-C',              '7 en 1, HDMI y Ethernet',         45.00, 28),
    (3, 'Cable HDMI 2.1',         '2 m, 8K',                         14.90, 45),
    (3, 'Cable USB-C',            '1 m, 100 W',                      12.50, 55),
    (3, 'Soporte de monitor',     'Brazo doble, gas',                89.00, 10),
    (3, 'Lámpara de escritorio',  'LED, con cargador',               35.90, 22),
    (3, 'Organizador de cables',  'Felpa con velcro',                 9.90, 80);
