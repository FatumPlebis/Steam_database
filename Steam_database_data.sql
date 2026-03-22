-- Creacion de base de datos
DROP DATABASE IF EXISTS Steam_database;
CREATE DATABASE Steam_database;
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
-- Tabla de tipos de juego (clasificación por mercado)
CREATE TABLE IF NOT EXISTS game_types (
    type_id INT PRIMARY KEY,
    type_name VARCHAR(100) NOT NULL
);
-- Tabla puente: relación juegos ↔ tipos
CREATE TABLE IF NOT EXISTS game_type_map (
    app_id INT,
    type_id INT,
    PRIMARY KEY (app_id, type_id),
    FOREIGN KEY (app_id) REFERENCES games(app_id),
    FOREIGN KEY (type_id) REFERENCES game_types(type_id)
);
-- Tabla de métricas (tabla de hechos)
CREATE TABLE IF NOT EXISTS game_metrics (
    app_id INT PRIMARY KEY,
    total_reviews INT,
    avg_owners INT,
    approval_percentage DECIMAL(5,2),
    FOREIGN KEY (app_id) REFERENCES games(app_id)
);
-- Tabla de tendencias (análisis)
CREATE TABLE IF NOT EXISTS game_trends (
    app_id INT PRIMARY KEY,
    trend_score DECIMAL(6,2),
    popularity_level VARCHAR(50),
    success_level VARCHAR(50),
    FOREIGN KEY (app_id) REFERENCES games(app_id)
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
    g.app_id,
    g.title,
    g.release_date,
    gm.total_reviews,
    gm.approval_percentage
FROM games g
JOIN game_metrics gm ON g.app_id = gm.app_id
WHERE gm.total_reviews >= 10000;

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

-- Tendencias por tipo de mercado
CREATE OR REPLACE VIEW view_trends_by_market AS
SELECT
    gt.type_name,
    COUNT(DISTINCT gtm.app_id) AS total_games,
    ROUND(AVG(gm.avg_owners), 0) AS avg_owners,
    ROUND(AVG(gtr.trend_score), 2) AS avg_trend_score,
    ROUND(AVG(gtr.success_level = 'Excellent') * 100, 2) AS success_rate
FROM game_type_map gtm
JOIN game_types gt ON gtm.type_id = gt.type_id
JOIN game_metrics gm ON gtm.app_id = gm.app_id
JOIN game_trends gtr ON gtm.app_id = gtr.app_id
GROUP BY gt.type_name
ORDER BY avg_trend_score DESC;


-- Tendencias por tag
CREATE OR REPLACE VIEW view_trends_by_tag AS
SELECT
    t.tag,
    COUNT(DISTINCT gt.app_id) AS total_games,
    ROUND(AVG(gt.trend_score), 2) AS avg_trend_score,
    ROUND(AVG(gm.avg_owners), 0) AS avg_owners,
    ROUND(AVG(gt.success_level = 'Excellent') * 100, 2) AS success_rate
FROM game_trends gt
JOIN game_metrics gm ON gt.app_id = gm.app_id
JOIN game_tags t ON gt.app_id = t.app_id
GROUP BY t.tag
HAVING total_games >= 50
ORDER BY avg_trend_score DESC;
