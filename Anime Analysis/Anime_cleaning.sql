USE anime;
/*
The SQL project seeks to conduct data cleaning and manipulation where required..
I also want to join the tables based on rank and score from each category e.g.
anime name showcasing its ranks in popularity and liking, alongside the rating in both categories.
This will help us find out whether the most popular anime are also the fans' favourite
*/
SELECT *
FROM top100_popular_anime;
 -- renaming columns
ALTER TABLE top100_popular_anime
RENAME COLUMN Popularity_Rank TO Popularity_Ranking;
ALTER TABLE top100_popular_anime
RENAME COLUMN Score TO Anime_Rating;

SELECT *
FROM top100_most_favourite_anime;
-- renaming columns
ALTER TABLE top100_most_favourite_anime
RENAME COLUMN Popularity_Rank TO Favourability_Ranking;
ALTER TABLE top100_most_favourite_anime
RENAME COLUMN Score TO Anime_Rating;
 -- I have combined columns to be used for analysis into one table
CREATE TABLE IMDB_top_anime_data AS 
SELECT pop.Title, pop.Popularity_Ranking, fav.Favourability_Ranking, pop.Anime_Rating
FROM top100_popular_anime pop
LEFT JOIN top100_most_favourite_anime fav
ON pop.Title = fav.Title
UNION
SELECT pop.Title, pop.Popularity_Ranking, fav.Favourability_Ranking, pop.Anime_Rating
FROM top100_popular_anime pop
RIGHT JOIN top100_most_favourite_anime fav
ON pop.Title = fav.Title;

SELECT *
FROM IMDB_top_anime_data;

DELETE FROM IMDB_top_anime_data
WHERE Title IS NULL AND Popularity_Ranking IS NULL AND Anime_Rating IS NULL;

-- Changing the name, I confused it.
RENAME TABLE IMDB_top_anime_data TO MAL_top_anime_data;
SELECT *
FROM MAL_top_anime_data;
 -- Cleaning up
UPDATE MAL_top_anime_data
SET Title  ='Tokyo Ghoul Root A'
WHERE Title ='Tokyo Ghoul âˆšA';

	