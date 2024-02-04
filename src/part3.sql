-- 1) Write a function that returns the TransferredPoints table in a more human-readable form
-- DROP FUNCTION human_readable_transferred_points();
CREATE OR REPLACE FUNCTION human_readable_transferred_points()
    RETURNS TABLE (
        "Peer1" VARCHAR, "Peer2" VARCHAR, "PointsAmount" INT
    ) LANGUAGE plpgsql
AS
$$
BEGIN
    RETURN QUERY
        SELECT
               table1.checkingpeer AS Peer1,
               table1.checkedpeer AS Peer2,
               table1.pointsamount-table2.pointsamount AS PointsAmount
        FROM transferredpoints AS table1
        INNER JOIN transferredpoints AS table2
            ON table1.checkingpeer = table2.checkedpeer AND table2.checkingpeer = table1.checkedpeer AND table1.id < table2.id;
END;
$$;

SELECT * FROM human_readable_transferred_points();
--SELECT * FROM transferredpoints;

-- 2) Write a function that returns a table of the following form: user name, name of the checked task, number of XP received
-- DROP FUNCTION xp_of_successfully_passed_tasks();
CREATE OR REPLACE FUNCTION xp_of_successfully_passed_tasks()
    RETURNS TABLE (
        "Peer" VARCHAR, "Task" VARCHAR, "XP" INT
    ) LANGUAGE plpgsql
AS
$$
BEGIN
    RETURN QUERY
        SELECT
               checks.peer AS Peer,
               checks.task AS Task,
               xp.numberxp AS XP
        FROM checks
        JOIN xp ON xp."Check" = checks.id
        ORDER BY 1,2,3;
END;
$$;

SELECT * FROM xp_of_successfully_passed_tasks();

-- 3) Write a function that finds the peers who have not left campus for the whole day
-- DROP FUNCTION peer_not_leaving();
CREATE OR REPLACE FUNCTION peer_not_leaving(IN p_date DATE)
    RETURNS TABLE (
        "Peer" VARCHAR
    ) LANGUAGE plpgsql
AS
$$
BEGIN
    RETURN QUERY
        SELECT table1.peer AS "Peer" FROM
        (SELECT peer, MIN(time)
        FROM timetracking
        WHERE date = p_date AND "State" = 1
        GROUP BY peer) AS table1
        LEFT JOIN
        (SELECT peer, MAX(time)
        FROM timetracking
        WHERE date = p_date AND "State" = 2
        GROUP BY peer) AS table2
        ON table1.peer=table2.peer
        WHERE table2.peer is NULL;
END;
$$;

SELECT * FROM peer_not_leaving('2023-11-06');

-- 4) Calculate the change in the number of peer points of each peer using the TransferredPoints table
-- DROP FUNCTION changed_peer_points();
CREATE OR REPLACE FUNCTION changed_peer_points()
    RETURNS TABLE (
        "Peer" VARCHAR, "PointsChange" bigint
    ) LANGUAGE plpgsql
AS
$$
BEGIN
    RETURN QUERY
        SELECT table1.Peer AS Peer, ( COALESCE(table1.get,0) - COALESCE(table2.give,0)) AS PointsChange FROM
        (SELECT checkingpeer AS Peer, SUM(pointsamount) AS get FROM transferredpoints
        GROUP BY checkingpeer) AS table1
        FULL JOIN
        (SELECT checkedpeer AS Peer, SUM(pointsamount) AS give FROM transferredpoints
        GROUP BY checkedpeer) AS table2 ON table1.Peer= table2.Peer
        ORDER BY 1,2;
END;
$$;

SELECT * FROM changed_peer_points();

-- 5) Calculate the change in the number of peer points of each peer using the table returned by the first function from Part 3
-- DROP FUNCTION changed_peer_points2();
CREATE OR REPLACE FUNCTION changed_peer_points2()
    RETURNS TABLE (
        "Peer" VARCHAR, "PointsChange" bigint
    ) LANGUAGE plpgsql
AS
$$
BEGIN
    RETURN QUERY
        SELECT COALESCE(table1.Peer,table2.Peer) AS Peer, ( COALESCE(table1.get,0) - COALESCE(table2.give,0)) AS PointsChange FROM
        (SELECT "Peer1" AS Peer, SUM("PointsAmount") AS get FROM human_readable_transferred_points()
        GROUP BY "Peer1") AS table1
        FULL JOIN
        (SELECT "Peer2" AS Peer, SUM("PointsAmount") AS give FROM human_readable_transferred_points()
        GROUP BY "Peer2") AS table2 ON table1.Peer= table2.Peer
        ORDER BY 1,2;
END;
$$;

SELECT * FROM changed_peer_points2();
-- hydrogenium lithium checked each other!

-- 6) Find the most frequently checked task for each day
-- DROP FUNCTION frequently_checked_task();
CREATE OR REPLACE FUNCTION frequently_checked_task()
    RETURNS TABLE (
        "Day" DATE, "Task" VARCHAR
    ) LANGUAGE plpgsql
AS
$$
BEGIN
    RETURN QUERY
        WITH firstview AS
        (SELECT task, COUNT(task) AS COUNT, date FROM checks
        GROUP BY task, date
        ORDER BY date),
        secondview AS
        (SELECT MAX(COUNT) AS MAX_COUNT, date   FROM firstview
        GROUP BY date
        ORDER BY date)
        SELECT firstview.date AS Day, firstview.task AS Task FROM secondview
        INNER JOIN firstview ON firstview.COUNT = secondview.MAX_COUNT AND firstview.date=secondview.date;
END;
$$;

SELECT * FROM frequently_checked_task();

-- 7) Find all peers who have completed the whole given block of tasks and the completion date of the last task
DROP PROCEDURE IF EXISTS completed_block CASCADE;
CREATE OR REPLACE PROCEDURE completed_block(block_name VARCHAR, INOUT RESULT REFCURSOR)
    LANGUAGE plpgsql AS
$$
BEGIN
    OPEN RESULT FOR
    SELECT checks.peer AS "Peer", checks.date AS "Day" FROM checks
    INNER JOIN p2p p ON checks.id = p."Check"
    LEFT JOIN verter v on checks.id = v."Check"
    WHERE p."State" = 'Success' AND (v."State" = 'Success' OR v."State" IS NULL) AND
      checks.task = (SELECT title FROM tasks WHERE title ~ ('^'|| block_name || '[0-9]' || '*') ORDER BY title DESC LIMIT 1);
END;
$$;


BEGIN;
    CALL completed_block('C', 'RESULT');
    FETCH ALL IN "RESULT";
END;

-- 8)
-- DROP FUNCTION peers_recommendation()
CREATE OR REPLACE FUNCTION peers_recommendation()
RETURNS TABLE(Peer VARCHAR, RecommendedPeer VARCHAR) AS $$
BEGIN
RETURN QUERY
	WITH recommended_counts AS (
		SELECT RecommendedPeer, COUNT(RecommendedPeer) AS total_recom, Friends.Peer1 AS Peer
		FROM Recommendations
		LEFT JOIN Friends ON Recommendations.Peer = Friends.Peer2
		WHERE Friends.Peer1 != Recommendations.RecommendedPeer
		GROUP BY RecommendedPeer, Recommendations.Peer,Friends.Peer1
	),
	result_table AS (
		SELECT recommended_counts.Peer, recommended_counts.RecommendedPeer, total_recom,
			ROW_NUMBER() OVER (PARTITION BY recommended_counts.Peer ORDER BY COUNT(*) DESC) AS rank
		FROM recommended_counts
		WHERE total_recom = (SELECT MAX(total_recom)
						FROM recommended_counts) AND recommended_counts.Peer != recommended_counts.RecommendedPeer
		GROUP BY recommended_counts.Peer, recommended_counts.RecommendedPeer, total_recom
		ORDER BY recommended_counts.Peer ASC
	)
	SELECT result_table.Peer, result_table.RecommendedPeer
	FROM result_table
	WHERE rank = 1;
END;
$$ LANGUAGE plpgsql;


-- 9)
-- DROP function percentage_of_peers_starting_blocks(block_name_1 varchar, block_name_2 varchar);

CREATE FUNCTION percentage_of_peers_starting_blocks(block_name_1 varchar, block_name_2 varchar)
RETURNS TABLE(Started_block1 BIGINT, Started_block2 BIGINT, Started_both BIGINT, Started_no_one BIGINT)
    AS $$
    DECLARE
        peers_count CONSTANT int := (SELECT COUNT(peers.nickname)
                        FROM peers);
    BEGIN
        RETURN QUERY
        WITH startedblock1 AS (SELECT DISTINCT peer
            FROM Checks
            WHERE Checks.task SIMILAR TO concat(block_name_1,'[0-9]_%')),
            startedblock2 AS (SELECT DISTINCT peer
            FROM Checks
            WHERE Checks.task SIMILAR TO concat(block_name_2,'[0-9]_%')),
            startedboth AS (SELECT DISTINCT startedblock1.peer
            FROM startedblock1 INNER JOIN startedblock2 ON startedblock1.peer = startedblock2.peer),
            startedoneof AS(SELECT DISTINCT peer
                            FROM ((SELECT * FROM startedblock1) UNION (SELECT * FROM startedblock2)) AS foo)

        SELECT (SELECT COUNT(*) * 100/peers_count
                FROM startedblock1)      AS Started_block1,
                (SELECT COUNT(*) * 100/peers_count
                 FROM startedblock2)   AS Started_block2,
                (SELECT COUNT(*) * 100/peers_count
                 FROM startedboth)       AS Started_both,
                     (SELECT (peers_count - COUNT(*)) * 100/peers_count
                      FROM startedoneof) AS Started_no_one;
    END
$$
LANGUAGE plpgsql;

-- 10) 
-- DROP FUNCTION IF EXISTS percentage_of_people_pass_checks_on_birthday();

 CREATE FUNCTION percentage_of_people_pass_checks_on_birthday()
 RETURNS TABLE(SuccessfulChecks bigint, UnsuccessfulChecks bigint)
 AS $$
 DECLARE
    all_checks_count integer := (SELECT MAX(id) FROM checks);
     suck_checks bigint := (SELECT COUNT(*)
         FROM Peers INNER JOIN Checks ON Peers.birthday = Checks.date
         WHERE Peers.Nickname = Checks.Peer);
 BEGIN
         RETURN QUERY
             SELECT
                (SELECT suck_checks/all_checks_count * 100) AS SuccessfulChecks,
                (SELECT (all_checks_count - suck_checks)/all_checks_count * 100) AS UnsuccessfulChecks;
     END
 $$
 LANGUAGE plpgsql;

SELECT * FROM percentage_of_people_pass_checks_on_birthday();

-- 11)

-- DROP FUNCTION IF EXISTS peers_completed_tasks(task_1 varchar, task_2 varchar, task_3 varchar);

CREATE OR REPLACE FUNCTION peers_completed_tasks(task_1 varchar, task_2 varchar, task_3 varchar)
    RETURNS TABLE
            (
                peers varchar
            )
AS
$$
BEGIN
RETURN QUERY WITH SuccessTasks AS (
            SELECT peer,
                   task
            FROM checks
                     JOIN p2p ON checks.id = p2p."Check"
                     LEFT JOIN verter ON checks.id = verter."Check"
            WHERE p2p.state = 'Success'
              AND (NOT exists(SELECT * FROM verter WHERE verter."Check" = checks.id) OR
                   verter.state = 'Success')
        )
SELECT DISTINCT peer as nickname
FROM SuccessTasks
WHERE peer in (SELECT peer FROM SuccessTasks WHERE task = task_1)
  AND peer in (SELECT peer FROM SuccessTasks WHERE task = task_2)
  AND peer NOT IN (SELECT peer FROM SuccessTasks WHERE task = task_3);
END
$$
LANGUAGE plpgsql;

-- 12) 
-- DROP FUNCTION IF EXISTS predecessor_tasks();

CREATE OR REPLACE FUNCTION predecessor_tasks() 
RETURNS TABLE(Task VARCHAR, PrevCount INT) AS $$
BEGIN
	RETURN QUERY
	WITH RECURSIVE task_count AS (
		SELECT title, 0 AS PrevCount
		FROM tasks
		WHERE parenttask IS NULL

		UNION ALL

		SELECT t.title, task_count.PrevCount + 1
		FROM tasks t
		INNER JOIN task_count ON t.parenttask = task_count.title
	)
	SELECT title AS Task, PrevCount
	FROM task_count;
END;
$$ LANGUAGE plpgsql;

-- 13)

-- DROP FUNCTION IF EXISTS lucky_days_for_review(IN N int);

CREATE OR REPLACE FUNCTION lucky_days_for_review(IN N int)
RETURNS TABLE (Lucky_days date)
AS $BODY$
BEGIN
RETURN QUERY
WITH  all_checks AS (
                SELECT checks.id, checks.date, p2p.time, p2p.state, xp.xpamount FROM checks, p2p, xp
                WHERE checks.id = p2p."Check" AND (p2p.state = 'Success' OR p2p.state = 'Failure')
                AND checks.id = xp."Check" AND xpamount >= (SELECT tasks.maxxp FROM tasks WHERE tasks.title = checks.task) * 0.8
                ORDER BY checks.date, p2p.time),
  successful_consecutive_checks AS (
        SELECT id, date, time, state,
        (CASE WHEN state = 'Success' THEN row_number() over (partition by state, date) ELSE 0 END) AS amount
        FROM all_checks ORDER BY date),
  max_day AS (SELECT date, MAX(amount) amount FROM successful_consecutive_checks GROUP BY date)
SELECT date FROM max_day WHERE amount >= N;
END;
$BODY$ 
LANGUAGE plpgsql;

---14 ++
CREATE OR REPLACE FUNCTION get_most_experience_peer()
RETURNS TABLE (PeerName VARCHAR, Experience NUMERIC)
AS $$
BEGIN
    RETURN QUERY
    SELECT ch.Peer AS PeerName, CAST(SUM(XP.NumberXP) AS NUMERIC) AS Experience
    FROM Checks AS ch
        INNER JOIN XP ON XP."Check" = ch.ID
    GROUP BY ch.Peer
    ORDER BY Experience DESC
    LIMIT 1;
END;
$$ LANGUAGE PLPGSQL;


--15
CREATE OR REPLACE FUNCTION fnc_peer_coming(t TIME, m INT)
RETURNS TABLE ("Peer" VARCHAR) AS $$
BEGIN
    RETURN QUERY
        SELECT tt.Peer
        FROM TimeTracking AS tt
        WHERE tt.Time < t
        GROUP BY tt.Peer
        HAVING COUNT(*) >= m
        ORDER BY tt.Peer;
END;
$$ LANGUAGE plpgsql;



-- 16
CREATE OR REPLACE FUNCTION get_peers_with_multiple_exits(n_days INT, min_exits INT)
RETURNS TABLE ("Peer" VARCHAR) AS $$
BEGIN
	RETURN QUERY
	WITH last_days AS (
		SELECT tt.Peer, tt.Date, COUNT(tt."State") AS exits_count
		FROM TimeTracking tt
		WHERE tt."State" = 2
		GROUP BY tt.Peer, tt.Date
		HAVING (current_date - tt.Date) < n_days
	)
	SELECT ld.Peer
	FROM last_days ld
	GROUP BY ld.Peer, ld.exits_count
	HAVING ld.exits_count >= min_exits;
END;
$$ LANGUAGE plpgsql;


--17
CREATE OR REPLACE PROCEDURE calculate_monthly_early_entry_percentage()
AS $$
DECLARE
    result_set REFCURSOR;
    month_data RECORD;
    early_entries INTEGER;
    total_entries INTEGER;
    percentage FLOAT;
BEGIN
    OPEN result_set FOR
    SELECT
        TO_CHAR(tt.Date, 'YYYY-MM') AS "Month",
        COUNT(*) AS "TotalEntries",
        COUNT(*) FILTER (WHERE EXTRACT(HOUR FROM tt.Time) < 12) AS "EarlyEntries"
    FROM timetracking AS tt
        INNER JOIN Peers ON tt.Peer = Peers.Nickname
    WHERE EXTRACT(MONTH FROM Peers.Birthday) = EXTRACT(MONTH FROM tt.Date)
    GROUP BY "Month"
    ORDER BY "Month" ASC;

    LOOP
        FETCH result_set INTO month_data;
        EXIT WHEN NOT FOUND;

        early_entries := month_data."EarlyEntries";
        total_entries := month_data."TotalEntries";

        IF total_entries > 0 THEN
            percentage := (early_entries::FLOAT / total_entries::FLOAT) * 100;
        ELSE
            percentage := 0;
        END IF;

        RAISE NOTICE 'Month: %, Percentage of Early Entries: %', month_data."Month", percentage;
    END LOOP;

    CLOSE result_set;
END;
$$ LANGUAGE PLPGSQL;

--CALL calculate_monthly_early_entry_percentage();

