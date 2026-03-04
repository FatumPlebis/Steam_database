-- Creacion de base de datos
CREATE DATABASE IF NOT EXISTS Steam_database;
USE Steam_database;
-- Tabla principal: Videojuegos
CREATE TABLE IF NOT EXISTS games (
    app_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    release_date VARCHAR(20) NULL,
    positive_reviews INT NULL,
    negative_reviews INT NULL,
    min_owners INT NULL,
    max_owners INT NULL,
    PRIMARY KEY (app_id)
);
-- Tabla de categorias asociadas a videojuegos
CREATE TABLE IF NOT EXISTS game_categories (
  app_id INT NOT NULL,
  category VARCHAR(255) NOT NULL,
  PRIMARY KEY (app_id, category),
  CONSTRAINT fk_game_categories_game
	FOREIGN KEY (app_id) REFERENCES games(app_id)
);
-- Tabla de etiquetas asociadas a los videojuegos
CREATE TABLE IF NOT EXISTS game_tags (
  app_id INT NOT NULL,
  tag VARCHAR(255) NOT NULL,
  PRIMARY KEY (app_id, tag),
  CONSTRAINT fk_game_tags_game
	FOREIGN KEY (app_id) REFERENCES games(app_id)
);
-- Tabla auditoria ligada a trigger
CREATE TABLE IF NOT EXISTS games_audit (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    app_id INT,
    inserted_at DATETIME,
    action_type VARCHAR(50)
);

DROP FUNCTION IF EXISTS fn_approval_percentage;
DROP FUNCTION IF EXISTS fn_avg_owners;
DELIMITER $$

CREATE FUNCTION fn_approval_percentage(
    pos INT,
    neg INT
)
RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
    DECLARE total INT;
    DECLARE result DECIMAL(5,2);

    SET total = pos + neg;

    IF total = 0 THEN
        RETURN 0;
    END IF;

    SET result = (pos / total) * 100;

    RETURN ROUND(result,2);
END $$

CREATE FUNCTION fn_avg_owners(
    min_val INT,
    max_val INT
)
RETURNS INT
DETERMINISTIC
BEGIN
    RETURN (min_val + max_val) / 2;
END $$
DELIMITER ;

-- Vista 1: Juegos con mejor aprobacion
DROP VIEW IF EXISTS view_game_approval;
CREATE OR REPLACE VIEW view_game_approval AS
SELECT
    app_id,
    title,
    release_date,
    positive_reviews,
    negative_reviews,
    (positive_reviews + negative_reviews) AS total_reviews,
    fn_approval_percentage(positive_reviews, negative_reviews) AS approval_percentage
FROM games
WHERE (positive_reviews + negative_reviews) >= 10000;

-- Vista 2: Juegos mas relevantes del mercado
DROP VIEW IF EXISTS view_market_relevance;
CREATE OR REPLACE VIEW view_market_relevance AS
SELECT
    app_id,
    title,
    release_date,
    min_owners,
    max_owners,
    (positive_reviews + negative_reviews) AS total_reviews,
    fn_approval_percentage(positive_reviews, negative_reviews) AS approval_percentage
FROM games
WHERE 
    (positive_reviews + negative_reviews) >= 10000
    AND min_owners >= 100000;
        
    -- Stored procedure #1: Juegos con mejor aprobacion
DROP PROCEDURE IF EXISTS sp_games_by_market_criteria;     
DELIMITER $$
CREATE PROCEDURE sp_games_by_market_criteria(
    IN min_reviews INT,
    IN min_owners_param INT
)
BEGIN
    SELECT
        app_id,
        title,
        release_date,
        min_owners,
        max_owners,
        (positive_reviews + negative_reviews) AS total_reviews,
        fn_approval_percentage(positive_reviews, negative_reviews) AS approval_percentage
    FROM games
    WHERE 
        (positive_reviews + negative_reviews) >= min_reviews
        AND min_owners >= min_owners_param
    ORDER BY approval_percentage DESC;
END $$
DELIMITER ;

-- Stored procedure #2: Top juegos por ventas
DROP PROCEDURE IF EXISTS sp_top_games_by_market;
DELIMITER $$
CREATE PROCEDURE sp_top_games_by_market(
    IN limit_number INT
)
BEGIN
    SELECT
        app_id,
        title,
        fn_avg_owners(min_owners, max_owners) AS avg_estimated_owners,
        fn_approval_percentage(positive_reviews, negative_reviews) AS approval_percentage,
        (positive_reviews + negative_reviews) AS total_reviews
    FROM games
    WHERE (positive_reviews + negative_reviews) >= 10000
    ORDER BY avg_estimated_owners DESC
    LIMIT limit_number;
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS trg_before_insert_games_validation;
DROP TRIGGER IF EXISTS trg_after_insert_games_audit;
DELIMITER $$

CREATE TRIGGER trg_before_insert_games_validation
BEFORE INSERT ON games
FOR EACH ROW
BEGIN
    IF NEW.positive_reviews < 0 OR NEW.negative_reviews < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Reviews cannot be negative';
    END IF;
END $$

CREATE TRIGGER trg_after_insert_games_audit
AFTER INSERT ON games
FOR EACH ROW
BEGIN
    INSERT INTO games_audit (
        app_id,
        inserted_at,
        action_type
    )
    VALUES (
        NEW.app_id,
        NOW(),
        'INSERT'
    );
END $$

DELIMITER ;

SHOW FUNCTION STATUS WHERE Db = 'Steam_database';

SHOW TABLES;

SHOW TRIGGERS;

SHOW DATABASES;