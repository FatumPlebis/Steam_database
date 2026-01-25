-- Creacion de base de datos
CREATE DATABASE IF NOT EXISTS Steam_database;
USE Steam_database;
-- Tabla principal: Videojuegos
CREATE TABLE IF NOT EXISTS games (
  app_id INT NOT NULL,
  title VARCHAR(255) NOT NULL,
  release_date DATE NOT NULL,
  hltb_single INT NULL,
  negative_reviews INT NULL,
  positive_reviews INT NULL,
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
