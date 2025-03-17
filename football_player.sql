CREATE DATABASE Football_Proj
GO

USE Football_Proj
GO

-- Select Data that we are going to use
SELECT *
FROM Football_Proj..football_player
GO

-- Age distribution of players and the number of players in each age group
SELECT
    position,
    CASE 
        WHEN age < 20 THEN 'Under 20'
        WHEN age BETWEEN 20 AND 25 THEN '20-25'
        WHEN age BETWEEN 26 AND 30 THEN '26-30'
        WHEN age BETWEEN 31 AND 35 THEN '31-35'
        WHEN age > 35 THEN 'Over 35'
    END AS AgeGroup,
    COUNT(*) AS PlayerCount,
    AVG(price) AS AVG_PlayerPrice
FROM Football_Proj..football_player
WHERE age IS NOT NULL
GROUP BY 
    position,
    CASE 
        WHEN age < 20 THEN 'Under 20'
        WHEN age BETWEEN 20 AND 25 THEN '20-25'
        WHEN age BETWEEN 26 AND 30 THEN '26-30'
        WHEN age BETWEEN 31 AND 35 THEN '31-35'
        WHEN age > 35 THEN 'Over 35'
    END
ORDER BY PlayerCount DESC
GO

-- Top 10 players with the highest current market value
SELECT TOP 10 
    name, 
    price, 
    position, 
    club
FROM Football_Proj..football_player
ORDER BY price DESC
GO

-- Distribution of players by position
SELECT 
    position, 
    COUNT(*) AS PlayerCount, 
    AVG(price) AS PlayerPrice,
    SUM(CASE WHEN foot = 'left' THEN 1 ELSE 0 END) AS Left_Foot_Player_Count,
    SUM(CASE WHEN foot = 'right' THEN 1 ELSE 0 END) AS Right_Foot_Player_Count,
    SUM(CASE WHEN foot = 'both' THEN 1 ELSE 0 END) AS Both_Foot_Player_Count
FROM Football_Proj..football_player
WHERE position IS NOT NULL
GROUP BY position 
ORDER BY COUNT(*) DESC
GO

-- Player count, average market value, and total market value in the league
SELECT 
    league, 
    COUNT(*) AS PlayerCount, 
    AVG(price) AS AVG_PlayerPrice, 
    SUM(price) AS Total_value
FROM Football_Proj..football_player
WHERE league IS NOT NULL
GROUP BY league
ORDER BY AVG(price) DESC
GO

-- The highest-valued player in their position
SELECT name, club, position, price
FROM (
    SELECT 
        name,
        club,
        position,
        price,
        ROW_NUMBER() OVER (PARTITION BY position ORDER BY price DESC) AS rn
    FROM Football_Proj..football_player
    WHERE price IS NOT NULL
) ranked
WHERE rn = 1
ORDER BY price DESC
GO

-- The club with the most balanced squad
WITH CountPlayer AS (
    SELECT 
        club,
        SUM(CASE WHEN position LIKE 'Goalkeeper%' THEN 1 ELSE 0 END) AS Goalkeepers,
        SUM(CASE WHEN position LIKE 'Defender%' THEN 1 ELSE 0 END) AS Defenders,
        SUM(CASE WHEN position LIKE 'midfield%' THEN 1 ELSE 0 END) AS Midfielders,
        SUM(CASE WHEN position LIKE 'Attack%' THEN 1 ELSE 0 END) AS Attackers
    FROM Football_Proj..football_player
    WHERE club IS NOT NULL
    GROUP BY club
    HAVING COUNT(*) > 11
)
SELECT
    SUB.club,
    SUB.Goalkeepers,
    SUB.Defenders,
    SUB.Midfielders,
    SUB.Attackers,
    POWER(SUB.Goalkeepers - SUB.Avg_Player, 2) + POWER(SUB.Midfielders - SUB.Avg_Player, 2) + POWER(SUB.Midfielders - SUB.Avg_Player, 2) + POWER(SUB.Attackers - SUB.Avg_Player, 2) AS PositionBalanceScore
FROM (
    SELECT 
        *,
        (Goalkeepers + Defenders + Midfielders + Attackers)/4 AS Avg_Player
    FROM CountPlayer
) AS SUB
ORDER BY PositionBalanceScore
GO

-- Top 10 clubs with the highest squad value
SELECT TOP 10
    club,
    COUNT(*) AS PlayerCount,
    SUM(price) AS ClubValue
FROM Football_Proj..football_player
GROUP BY club 
HAVING club IS NOT NULL
ORDER BY ClubValue DESC
GO

-- The relationship between height and average value by position
UPDATE Football_Proj..football_player
SET height = height * 10
WHERE height < 100 AND height IS NOT NULL;

SELECT position, ROUND(AVG(height),2) AS AverageHeight, ROUND(AVG(price),2) AS AveragePrice
FROM Football_Proj..football_player
GROUP BY position 
HAVING position IS NOT NULL
ORDER BY AveragePrice DESC
GO

-- Gap between current market value and peak value
SELECT
    name,
    club,
    position,
    price,
    max_price,
    (max_price - price) AS drop_price,
    CASE 
        WHEN max_price = 0 THEN NULL
        ELSE ROUND((max_price - price)*100/max_price,2)
    END AS DropPercentage
FROM Football_Proj..football_player
ORDER BY drop_price DESC
