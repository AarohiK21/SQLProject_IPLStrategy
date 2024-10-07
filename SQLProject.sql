CREATE TABLE IPL_Ball(id INT, inning INT, over INT, ball INT, batsman VARCHAR,
	non_striker VARCHAR, bowler VARCHAR, batsman_runs INT, extra_runs INT, total_runs INT,
	is_wicket INT, dismissal_kind VARCHAR, player_dismissed VARCHAR, fielder VARCHAR,
	extras_type VARCHAR, batting_team VARCHAR, bowling_team VARCHAR)

COPY IPL_Ball FROM 'C:\TEMP\IPL Dataset\IPL_Ball.csv' DELIMITER ',' CSV HEADER;

SELECT * FROM IPL_Ball;

--DROP TABLE IPL_Match
CREATE TABLE IPL_Match(id INT, city VARCHAR, date DATE, player_of_match VARCHAR,
	venue VARCHAR, neutral_venue INT, team1 VARCHAR, team2 VARCHAR, toss_winner VARCHAR,
	toss_decision VARCHAR, winner VARCHAR, result VARCHAR, result_margin INT,
	eliminator VARCHAR, method VARCHAR, umpire1 VARCHAR, umpire2 VARCHAR)

COPY IPL_Match FROM 'C:\TEMP\IPL Dataset\IPL_matches.csv' DELIMITER ',' CSV HEADER;

--SHOW datestyle
--SET datestyle = SQL, DMY

SELECT * FROM IPL_Match

SELECT * FROM IPL_Ball
	
--Two criteria: high SR, more than 500 balls faced without wides, leg byes
SELECT batsman, COUNT(ball) AS ball_faced, sum(batsman_runs) AS runs_scored, 
	sum(batsman_runs*100.0)/count(batsman_runs) AS strike_rate 
	FROM IPL_Ball WHERE ball IN(SELECT ball WHERE extras_type = 'NA')
	GROUP BY batsman
	HAVING COUNT(ball)>=500
	ORDER BY strike_rate DESC LIMIT 10;

--Second query
SELECT ib.batsman, COUNT(DISTINCT(EXTRACT(YEAR FROM im.date))) AS matches,
	sum(batsman_runs)/sum(is_wicket) AS average
	FROM IPL_Ball AS ib JOIN IPL_Match AS im
	ON ib.id = im.id
	GROUP BY ib.batsman
	HAVING COUNT(DISTINCT(EXTRACT(YEAR FROM im.date)))>2
	ORDER BY average DESC LIMIT 10;

--Third query

--CREATE TABLE Boundaries AS 
CREATE TABLE Boundaries AS
SELECT batsman, SUM(batsman_runs) AS total_runs, 
SUM(CASE WHEN batsman_runs IN(4,6) THEN  batsman_runs ELSE NULL END) AS boundary_hits
FROM IPL_Ball
GROUP BY batsman;

SELECT *, (boundary_hits*1./total_runs)*100 AS precent_of_hits
FROM Boundaries WHERE batsman IN(SELECT batsman FROM IPL_Ball 
	GROUP BY batsman HAVING COUNT(DISTINCT id)>28 )
ORDER BY (boundary_hits*1./total_runs)*100 DESC LIMIT 10;

--Fourth query
SELECT bowler, SUM(total_runs)*1./(COUNT(ball)/6) AS economy_rate,
       COUNT(ball) AS balls_bowled
FROM IPL_Ball 
WHERE extras_type NOT IN ('legbyes', 'penalty', 'wides', 'noballs')
GROUP BY bowler
HAVING COUNT(ball) >= 500
ORDER BY economy_rate ASC LIMIT 10;

--Fifth query
SELECT * FROM IPL_Ball

SELECT bowler, COUNT(ball)/COUNT(CASE WHEN is_wicket=1 THEN 1 ELSE NULL END) AS strike_rate,
COUNT(ball) AS bowled_ball
FROM IPL_Ball
WHERE extras_type = 'NA'
GROUP BY bowler
HAVING COUNT(ball)>=500
ORDER BY strike_rate ASC LIMIT 10;

--Sixth query
SELECT batsman AS all_rounders,
SUM(batsman_runs) * 100.0 / COUNT(ball) AS batting_strike_rate,
    COUNT(ball) * 1.0 / COUNT(CASE WHEN is_wicket = 1 THEN 1 ELSE NULL END) AS bowling_strike_rate
FROM IPL_Ball
WHERE batsman IN(SELECT bowler FROM IPL_Ball GROUP BY bowler HAVING COUNT(ball)>=300)
GROUP BY batsman HAVING COUNT(ball)>=500
ORDER BY batting_strike_rate DESC,
bowling_strike_rate ASC LIMIT 10;

select * from ipl_ball




-------------Questions
SELECT COUNT(DISTINCT(city)) FROM ipl_match

CREATE TABLE deliveries_v02 AS
SELECT *, (CASE WHEN total_runs>=4 THEN 'boundary'
				WHEN total_runs = 0 THEN 'dot'
				ELSE 'other' END) AS "ball_result"
FROM IPL_Ball

SELECT ball_result, COUNT(ball_result) FROM deliveries_v02
WHERE ball_result IN('boundary', 'dot') 
GROUP BY ball_result

SELECT batting_team, COUNT(ball_result) AS boundaries FROM deliveries_v02
WHERE ball_result = 'boundary'
GROUP BY batting_team
ORDER BY boundaries DESC;

SELECT bowling_team, COUNT(ball_result) AS boundaries FROM deliveries_v02
WHERE ball_result = 'dot'
GROUP BY bowling_team
ORDER BY boundaries DESC;

SELECT COUNT(dismissal_kind) FROM deliveries_v02 WHERE NOT dismissal_kind  = 'NA'

SELECT bowler, SUM(extra_runs) AS runs_conceded
FROM IPL_Ball
GROUP BY bowler
ORDER BY runs_conceded DESC LIMIT 5

CREATE TABLE deliveries_v03 AS
SELECT d.*, im.venue AS venue, im.date AS match_date
	FROM deliveries_v02 AS d LEFT JOIN IPL_Match AS im
ON d.id = im.id

SELECT venue, SUM(total_runs) AS venue_runs FROM deliveries_v03 
	GROUP BY venue ORDER BY venue_runs DESC

SELECT EXTRACT(YEAR FROM match_date), SUM(total_runs) AS total_runs 
	FROM deliveries_v03
WHERE venue = 'Eden Gardens'
GROUP BY EXTRACT(YEAR FROM match_date)
ORDER BY total_runs DESC


	SELECT DISTINCT(dismissal_kind), COUNT(dismissal_kind) FROM ipl_ball GROUP BY dismissal_kind

SELECt batsman, sum(total_runs) FROM ipl_ball 
	group by batsman
	having 	SUM(batsman_runs) * 100.0 / COUNT(ball) >150
	 order by sum(total_runs) desc