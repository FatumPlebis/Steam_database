SELECT DATABASE();
SHOW TABLES;
SELECT COUNT(*) FROM games;
SET FOREIGN_KEY_CHECKS = 0;
SET SQL_SAFE_UPDATES = 0;
DELETE FROM games;
SET FOREIGN_KEY_CHECKS = 1;

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

SELECT COUNT(*) FROM games;

SELECT * FROM view_game_approval LIMIT 5;

SHOW FULL TABLES IN Steam_database;