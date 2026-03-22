-- Steam database - DATA
USE Steam_database;

-- Limpieza en orden correcto (por FK)
DELETE FROM game_type_map;
DELETE FROM game_types;
DELETE FROM game_trends;
DELETE FROM game_metrics;
DELETE FROM game_tags;
DELETE FROM game_categories;
DELETE FROM games;

-- Carga de tabla "games"
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.5/Uploads/games.csv'
INTO TABLE games
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@name, @month, @year, @release_date, @price, @positive_rev, @negative_rev, @app_id, @min_owners, @max_owners, @hltb_single)
SET
app_id = @app_id,
title = @name,
release_date = @release_date,
positive_reviews = @positive_rev,
negative_reviews = @negative_rev,
min_owners = @min_owners,
max_owners = @max_owners;

-- Carga de tabla "game_tags"
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.5/Uploads/t-games-tags.csv'
INTO TABLE game_tags
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(app_id, tag);

-- Carga de tabla "game_categories"
-- Nota para esta tabla:
-- La tabla game_categories no se cargó mediante LOAD DATA INFILE
-- debido a limitaciones del entorno y errores del cliente (Workbench).
-- Se insertaron registros manualmente para permitir pruebas de relaciones.

-- Poblacion de tabla de metricas
INSERT INTO game_metrics (
    app_id,
    total_reviews,
    avg_owners,
    approval_percentage
)
SELECT
    app_id,
    (positive_reviews + negative_reviews) AS total_reviews,
    fn_avg_owners(min_owners, max_owners) AS avg_owners,
    fn_approval_percentage(positive_reviews, negative_reviews) AS approval_percentage
FROM games;

-- Poblacion tabla de tendencias
INSERT INTO game_trends (
    app_id,
    trend_score,
    popularity_level,
    success_level
)
SELECT
    app_id,
    ROUND(
        (
            (approval_percentage * 0.6)
            +
            (LOG10(GREATEST(total_reviews, 1)) * 5 * 0.25)
            +
            (LOG10(GREATEST(avg_owners, 1)) * 5 * 0.15)
        ),
        2
    ) AS trend_score,

    CASE
        WHEN avg_owners < 50000 THEN 'Low'
        WHEN avg_owners < 200000 THEN 'Medium'
        ELSE 'High'
    END AS popularity_level,

    CASE
        WHEN approval_percentage < 60 THEN 'Poor'
        WHEN approval_percentage < 80 THEN 'Good'
        ELSE 'Excellent'
    END AS success_level

FROM game_metrics;

-- Clasificacion por mercado
-- Tipos de mercado
INSERT INTO game_types (type_id, type_name)
VALUES
(1, 'Niche'),
(2, 'Mid Market'),
(3, 'High Market');

-- Asignación de juegos a tipos
INSERT INTO game_type_map (app_id, type_id)
SELECT
    app_id,
    CASE
        WHEN avg_owners < 50000 THEN 1
        WHEN avg_owners < 200000 THEN 2
        ELSE 3
    END

FROM game_metrics;

-- Validaciones finales
-- Validar carga de juegos
SELECT COUNT(*) AS total_games FROM games;

-- Validar métricas generadas
SELECT COUNT(*) AS total_metrics FROM game_metrics;

-- Validar tendencias generadas
SELECT COUNT(*) AS total_trends FROM game_trends;

-- Validar clasificación por mercado
SELECT 
    gt.type_name,
    COUNT(*) AS total_games
FROM game_type_map gtm
JOIN game_types gt ON gtm.type_id = gt.type_id
GROUP BY gt.type_name;

-- Mostrar análisis final
SELECT * FROM view_trends_by_market;
