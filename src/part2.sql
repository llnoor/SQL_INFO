CREATE OR REPLACE PROCEDURE add_p2p (IN peer_nickname VARCHAR, IN checkers_nickname VARCHAR,
                    IN task_name VARCHAR,  IN  P2P_check_status Check_status, IN checked_time time)
AS $$
BEGIN
-- Before    IF P2P_check_status = 'Start' AND (SELECT * FROM p2p JOIN checks ON checks.id = "Check" WHERE task_name = checks.task AND peer_nickname = checkingpeer AND checkers_nickname = checks.peer) IS NOT NULL
    IF P2P_check_status = 'Start' AND (SELECT 1 FROM p2p JOIN checks ON checks.id = "Check" WHERE task_name = checks.task AND peer_nickname = checkingpeer AND checkers_nickname = checks.peer) IS NOT NULL
    THEN
      RAISE EXCEPTION 'В таблице не может быть больше одной незавершенной P2P проверки';
      ELSE
        IF P2P_check_status = 'Start'
        THEN
            INSERT INTO checks
            VALUES ((SELECT max(id) + 1 FROM checks), peer_nickname, task_name, (SELECT CURRENT_DATE));
            INSERT INTO p2p
            VALUES ((SELECT max(id) + 1 FROM p2p), (SELECT max(id) FROM checks), checkers_nickname, P2P_check_status, checked_time);
        ELSE
            INSERT INTO p2p
            VALUES ((SELECT max(id) + 1 FROM p2p), (SELECT "Check" FROM p2p JOIN checks ON checks.id = "Check" WHERE checks.peer = peer_nickname AND checks.task = task_name AND checkingpeer = checkers_nickname),
                    checkers_nickname, P2P_check_status,checked_time);
        END IF;
    END IF;
END;
$$
    LANGUAGE plpgsql;

SELECT * FROM checks;
SELECT * FROM p2p;
call add_p2p('lithium', 'hydrogenium', 'C5_Decimal', 'Start', '08:00:00');
SELECT * FROM checks;
SELECT * FROM p2p;
call add_p2p('lithium', 'hydrogenium', 'C5_Decimal', 'Start', '08:00:00'); 


CREATE OR REPLACE PROCEDURE add_verter (IN peer_nickname VARCHAR, IN task_name VARCHAR,
                                        IN  Verter_check_status Check_status, IN checked_time time)
AS $$
BEGIN
    IF (SELECT max(Time) FROM P2P JOIN checks ON P2P."Check" = checks.ID WHERE "State" = 'Success' AND
                    checks.Peer = peer_nickname AND checks.Task = task_name) = checked_time AND NOT NULL
        THEN
            INSERT INTO verter
        VALUES ((SELECT max(id) + 1 FROM verter), (SELECT "Check" FROM P2P WHERE Time = (SELECT max(Time) FROM P2P)), Verter_check_status, checked_time);
            ELSE
        RAISE EXCEPTION 'Неудачная P2P проверка';
    END IF;
END;
$$

CREATE OR REPLACE PROCEDURE add_verter(IN peer_nickname VARCHAR, IN task_name VARCHAR,
                                       IN Verter_check_status Check_status, IN checked_time TIME)
AS $$
DECLARE
  latest_p2p_check_id INT;
BEGIN
  SELECT MAX(P2P."Check")
  INTO latest_p2p_check_id
  FROM P2P
  JOIN Checks ON P2P."Check" = Checks.ID
  WHERE Checks.Task = task_name AND P2P."State" = 'Success';

  IF latest_p2p_check_id IS NOT NULL THEN
    INSERT INTO Verter("Check", "State", Time)
    VALUES (latest_p2p_check_id, Verter_check_status, checked_time);
  ELSE
    RAISE EXCEPTION 'Не найдено успешной проверки P2P для данной задачи';
  END IF;
END;
$$ LANGUAGE plpgsql;


/**/

CREATE OR REPLACE FUNCTION trg_update_transferred_points()
RETURNS TRIGGER AS $$
BEGIN
    -- Обновляем PointsAmount в TransferredPoints, если запись существует
    UPDATE TransferredPoints
    SET PointsAmount = PointsAmount + 1
    WHERE CheckingPeer = NEW.CheckingPeer
      AND CheckedPeer = (SELECT Peer FROM Checks WHERE ID = NEW."Check");

    -- Если записи не существует, вставляем новую запись
    IF NOT FOUND THEN
        INSERT INTO TransferredPoints(CheckingPeer, CheckedPeer, PointsAmount)
        VALUES (NEW.CheckingPeer, (SELECT Peer FROM Checks WHERE ID = NEW."Check"), 1);
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Создаем триггер
CREATE TRIGGER trg_update_transferred_points
AFTER INSERT ON P2P
FOR EACH ROW
WHEN (NEW."State" = 'Start')  -- Условие выполняется только при добавлении записи со статусом "Start"
EXECUTE FUNCTION trg_update_transferred_points();


----


CREATE OR REPLACE FUNCTION before_insert_xp()
RETURNS TRIGGER AS $$
BEGIN
    -- Проверяем, что количество XP не превышает максимальное значение для задачи
    IF NEW.NumberXP > (SELECT MaxXP FROM Tasks WHERE Title = (SELECT Task FROM Checks WHERE ID = NEW."Check")) THEN
        RAISE EXCEPTION 'Количество XP превышает максимальное значение для задачи';
    END IF;

    -- Проверяем, что Check связан с успешной проверкой
    IF NOT EXISTS (SELECT 1 FROM Checks WHERE ID = NEW."Check" AND EXISTS (SELECT 1 FROM P2P WHERE "Check" = NEW."Check" AND "State" = 'Success')) THEN
        RAISE EXCEPTION 'Check не связан с успешной проверкой';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_before_insert_xp
BEFORE INSERT ON XP
FOR EACH ROW
EXECUTE FUNCTION before_insert_xp();
