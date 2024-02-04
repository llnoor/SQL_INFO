CREATE TYPE Check_status AS ENUM ('Start', 'Success', 'Failure');

DROP TABLE IF EXISTS Peers CASCADE;
DROP TABLE IF EXISTS Tasks CASCADE;
DROP TABLE IF EXISTS Checks CASCADE;
DROP TABLE IF EXISTS P2P CASCADE;
DROP TABLE IF EXISTS Verter CASCADE;
DROP TABLE IF EXISTS TransferredPoints CASCADE;
DROP TABLE IF EXISTS Friends CASCADE;
DROP TABLE IF EXISTS Recommendations CASCADE;
DROP TABLE IF EXISTS XP CASCADE;
DROP TABLE IF EXISTS TimeTracking CASCADE;

CREATE TABLE Peers (
    Nickname VARCHAR PRIMARY KEY NOT NULL,
    Birthday DATE NOT NULL DEFAULT CURRENT_DATE
);
INSERT INTO Peers(Nickname, Birthday)
VALUES
('hydrogenium','2000-01-01'),
('helium','2000-02-02'),
('lithium','2000-03-03'),
('beryllium','2000-04-04'),
('borum','2000-05-05'),
('nitrogenium','2000-06-06'),
('oxygenium','2000-07-07'),
('fluorum','2000-08-08'),
('neon','2000-09-09');

CREATE TABLE Tasks (
    Title VARCHAR PRIMARY KEY NOT NULL,
    ParentTask VARCHAR,
    MaxXP INT NOT NULL
);
INSERT INTO Tasks(Title, ParentTask, MaxXP)
VALUES
('C1_Pool',null,1000), --Verter
('C2_BashUtils','C1_Pool',250), --Verter
('C3_String','C2_BashUtils',500), --Verter
('C4_Math','C3_String',300), --Verter
('C5_Decimal','C4_Math',350), --Verter
('C6_Matrix','C5_Decimal',200), --Verter
('C7_SmartCalc','C6_Matrix',500),
('C8_3DViewer','C7_SmartCalc',750),
('DO1_Linux','C8_3DViewer',300),
('DO2_Network','DO1_Linux',250),
('DO3_Monitoring','DO2_Network',350),
('DO4_SimpleDocker','DO3_Monitoring',350),
('DO5_CICD','DO4_SimpleDocker',300),
('SQL1_Bootcamp','DO5_CICD',1500),
('SQL2_Info21','SQL1_Bootcamp',500),
('SQL3_RetailAnalitycs','SQL2_Info21',600);

CREATE TABLE Checks (
    ID SERIAL PRIMARY KEY NOT NULL,
    Peer VARCHAR NOT NULL REFERENCES Peers(Nickname),
    Task VARCHAR NOT NULL REFERENCES Tasks(Title),
    Date DATE NOT NULL DEFAULT CURRENT_DATE
);



CREATE TABLE P2P (
    ID SERIAL PRIMARY KEY NOT NULL,
    "Check" INT REFERENCES Checks(ID),
    CheckingPeer VARCHAR NOT NULL REFERENCES Peers(Nickname),
    "State" Check_status,
    Time TIME NOT NULL
);

CREATE TABLE Verter (
    ID SERIAL PRIMARY KEY NOT NULL,
    "Check" INT REFERENCES Checks(ID) NOT NULL,
    "State" Check_status,
    Time TIME NOT NULL
);

CREATE TABLE TransferredPoints (
    ID SERIAL PRIMARY KEY NOT NULL,
    CheckingPeer VARCHAR NOT NULL,
    CheckedPeer VARCHAR NOT NULL,
    PointsAmount INT,
    FOREIGN KEY (CheckingPeer) REFERENCES Peers(Nickname),
    FOREIGN KEY (CheckedPeer) REFERENCES Peers(Nickname)
);

CREATE TABLE Friends (
    ID SERIAL PRIMARY KEY NOT NULL,
    Peer1 VARCHAR NOT NULL,
    Peer2 VARCHAR NOT NULL,
    FOREIGN KEY (Peer1) REFERENCES Peers(Nickname),
    FOREIGN KEY (Peer2) REFERENCES Peers(Nickname)
); 

CREATE TABLE Recommendations (
    ID SERIAL PRIMARY KEY NOT NULL,
    Peer VARCHAR NOT NULL,
    RecommendedPeer VARCHAR NOT NULL,
    FOREIGN KEY (Peer) REFERENCES Peers(Nickname),
    FOREIGN KEY (RecommendedPeer) REFERENCES Peers(Nickname)
);

CREATE TABLE XP (
    ID SERIAL PRIMARY KEY NOT NULL,
    "Check" INT REFERENCES Checks(ID) NOT NULL,
    NumberXP INT CHECK ( NumberXP > 0)
);

CREATE TABLE TimeTracking (
    ID SERIAL PRIMARY KEY NOT NULL,
    Peer VARCHAR NOT NULL,
    Date DATE NOT NULL,
    Time TIME NOT NULL,
    "State" INT CHECK ("State" in (1,2)),
    FOREIGN KEY (Peer) REFERENCES Peers(Nickname)
);

CREATE OR REPLACE PROCEDURE ImportData("table" text, "file" text) AS $$
BEGIN
    EXECUTE 'COPY ' || "table" || ' FROM ''' || "file" || ''' DELIMITER '','' CSV HEADER;';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE ExportData("table" text, "file" text) AS $$
BEGIN
    EXECUTE 'COPY (SELECT * FROM ' || "table" || ') TO ''' || "file" || ''' DELIMITER '','' CSV HEADER;';
END;
$$ LANGUAGE plpgsql;

-- MODEL like SQL query

INSERT INTO "checks" ("id","peer","task","date") VALUES 
 ('1','hydrogenium','C1_Pool','2023-08-01'), 
 ('2','helium','C1_Pool','2023-08-01'), 
 ('3','lithium','C1_Pool','2023-08-01'), 
 ('4','beryllium','C1_Pool','2023-08-01'), 
 ('5','borum','C1_Pool','2023-08-01'), 
 ('6','hydrogenium','C2_BashUtils','2023-08-01'), 
 ('7','helium','C2_BashUtils','2023-09-01'), 
 ('8','lithium','C2_BashUtils','2023-09-01'), 
 ('9','beryllium','C2_BashUtils','2023-09-01'), 
 ('10','borum','C2_BashUtils','2023-09-01'), 
 ('11','hydrogenium','C3_String','2023-09-09'), 
 ('12','helium','C3_String','2023-09-10'), 
 ('13','lithium','C3_String','2023-10-01'), 
 ('14','beryllium','C3_String','2023-10-02'), 
 ('15','borum','C3_String','2023-10-03'), 
 ('16','hydrogenium','C4_Math','2023-10-08'), 
 ('17','helium','C4_Math','2023-10-09'), 
 ('18','lithium','C4_Math','2023-10-10'), 
 ('19','hydrogenium','C5_Decimal','2023-10-11'), 
 ('20','hydrogenium','C6_Matrix','2023-11-03'), 
 ('21','hydrogenium','C7_SmartCalc','2023-11-06'), 
 ('22','hydrogenium','C7_SmartCalc','2023-11-07'), 
 ('23','hydrogenium','C8_3DViewer','2023-11-08');
 
 INSERT INTO "friends" ("id","peer1","peer2") VALUES 
 ('1','hydrogenium','helium'), 
 ('2','helium','lithium'), 
 ('3','lithium','beryllium'), 
 ('4','beryllium','borum'), 
 ('5','borum','hydrogenium'), 
 ('6','hydrogenium','lithium'), 
 ('7','hydrogenium','beryllium');
 
 INSERT INTO "p2p" ("id","Check","checkingpeer","State","time") VALUES 
 ('1','1','helium','Start','01.08.2023 20:34:45'), 
 ('2','1','helium','Success','01.08.2023 20:49:45'), 
 ('3','2','lithium','Start','02.08.2023 13:43:49'), 
 ('4','2','lithium','Failure','02.08.2023 13:58:49'), 
 ('5','2','hydrogenium','Start','02.08.2023 14:23:49'), 
 ('6','2','hydrogenium','Failure','02.08.2023 14:38:49'), 
 ('7','2','beryllium','Start','02.08.2023 15:03:49'), 
 ('8','2','beryllium','Failure','02.08.2023 15:18:49'), 
 ('9','2','borum','Start','02.08.2023 15:43:49'), 
 ('10','2','borum','Success','02.08.2023 15:58:49'), 
 ('11','3','borum','Start','03.08.2023 16:02:48'), 
 ('12','3','borum','Failure','03.08.2023 16:17:48'), 
 ('13','3','borum','Start','03.08.2023 16:42:48'), 
 ('14','3','borum','Failure','03.08.2023 16:57:48'), 
 ('15','3','hydrogenium','Start','03.08.2023 17:22:48'), 
 ('16','3','hydrogenium','Success','03.08.2023 17:37:48'), 
 ('17','4','lithium','Start','04.08.2023 8:51:43'), 
 ('18','4','lithium','Failure','04.08.2023 9:06:43'), 
 ('19','4','borum','Start','04.08.2023 9:31:43'), 
 ('20','4','borum','Success','04.08.2023 9:46:43'), 
 ('21','5','hydrogenium','Start','05.08.2023 15:27:36'), 
 ('22','5','hydrogenium','Success','05.08.2023 15:42:36'), 
 ('23','6','lithium','Start','10.08.2023 9:14:15'), 
 ('24','6','lithium','Success','10.08.2023 9:29:15'), 
 ('25','7','lithium','Start','01.09.2023 20:40:38'), 
 ('26','7','lithium','Failure','01.09.2023 20:55:38'), 
 ('27','7','lithium','Start','01.09.2023 21:20:38'), 
 ('28','7','lithium','Failure','01.09.2023 21:35:38'), 
 ('29','7','beryllium','Start','01.09.2023 22:00:38'), 
 ('30','7','beryllium','Success','01.09.2023 22:15:38'), 
 ('31','8','helium','Start','02.09.2023 17:15:58'), 
 ('32','8','helium','Failure','02.09.2023 17:30:58'), 
 ('33','8','helium','Start','02.09.2023 17:55:58'), 
 ('34','8','helium','Success','02.09.2023 18:10:58'), 
 ('35','9','helium','Start','03.09.2023 19:27:31'), 
 ('36','9','helium','Success','03.09.2023 19:42:31'), 
 ('37','10','beryllium','Start','04.09.2023 22:10:48'), 
 ('38','10','beryllium','Failure','04.09.2023 22:25:48'), 
 ('39','10','helium','Start','04.09.2023 22:50:48'), 
 ('40','10','helium','Failure','04.09.2023 23:05:48'), 
 ('41','10','hydrogenium','Start','04.09.2023 23:30:48'), 
 ('42','10','hydrogenium','Failure','04.09.2023 23:45:48'), 
 ('43','10','lithium','Start','05.09.2023 0:10:48'), 
 ('44','10','lithium','Success','05.09.2023 0:25:48'), 
 ('45','11','helium','Start','09.09.2023 10:42:30'), 
 ('46','11','helium','Failure','09.09.2023 10:57:30'), 
 ('47','11','lithium','Start','09.09.2023 11:22:30'), 
 ('48','11','lithium','Failure','09.09.2023 11:37:30'), 
 ('49','11','helium','Start','09.09.2023 12:02:30'), 
 ('50','11','helium','Success','09.09.2023 12:17:30'), 
 ('51','12','borum','Start','10.09.2023 8:59:52'), 
 ('52','12','borum','Failure','10.09.2023 9:14:52'), 
 ('53','12','lithium','Start','10.09.2023 9:39:52'), 
 ('54','12','lithium','Success','10.09.2023 9:54:52'), 
 ('55','13','borum','Start','01.10.2023 16:08:14'), 
 ('56','13','borum','Success','01.10.2023 16:23:14'), 
 ('57','14','helium','Start','02.10.2023 14:55:25'), 
 ('58','14','helium','Success','02.10.2023 15:10:25'), 
 ('59','15','hydrogenium','Start','03.10.2023 15:40:45'), 
 ('60','15','hydrogenium','Success','03.10.2023 15:55:45'), 
 ('61','16','helium','Start','08.10.2023 15:41:41'), 
 ('62','16','helium','Failure','08.10.2023 15:56:41'), 
 ('63','16','borum','Start','08.10.2023 16:21:41'), 
 ('64','16','borum','Failure','08.10.2023 16:36:41'), 
 ('65','16','helium','Start','08.10.2023 17:01:41'), 
 ('66','16','helium','Failure','08.10.2023 17:16:41'), 
 ('67','16','lithium','Start','08.10.2023 17:41:41'), 
 ('68','16','lithium','Success','08.10.2023 17:56:41'), 
 ('69','17','beryllium','Start','09.10.2023 13:23:41'), 
 ('70','17','beryllium','Success','09.10.2023 13:38:41'), 
 ('71','18','borum','Start','10.10.2023 9:45:28'), 
 ('72','18','borum','Failure','10.10.2023 10:00:28'),
 ('73','19','helium','Start','11.10.2023 8:21:39'), 
 ('74','19','helium','Success','11.10.2023 8:36:39'), 
 ('75','20','lithium','Start','03.11.2023 16:29:28'), 
 ('76','20','lithium','Success','03.11.2023 16:44:28'), 
 ('77','21','beryllium','Start','06.11.2023 18:19:55'), 
 ('78','21','beryllium','Success','06.11.2023 18:34:55'), 
 ('79','22','beryllium','Start','07.11.2023 20:19:55'), 
 ('80','22','beryllium','Success','07.11.2023 20:34:55'), 
 ('81','23','beryllium','Start','08.11.2023 21:19:55'), 
 ('82','23','beryllium','Success','08.11.2023 21:34:55');

INSERT INTO "recommendations" ("id","peer","recommendedpeer") VALUES 
 ('1','beryllium','borum'), 
 ('2','beryllium','helium'), 
 ('3','borum','hydrogenium'), 
 ('4','borum','lithium'), 
 ('5','helium','beryllium'), 
 ('6','helium','borum'), 
 ('7','helium','lithium'), 
 ('8','hydrogenium','beryllium'), 
 ('9','hydrogenium','helium'), 
 ('10','hydrogenium','lithium'), 
 ('11','lithium','borum'), 
 ('12','lithium','helium'), 
 ('13','lithium','hydrogenium');
 
INSERT INTO "timetracking" ("id","peer","date","time","State") VALUES 
 ('1','hydrogenium','2023-08-01','18:34:45','1'), 
 ('2','hydrogenium','2023-08-01','21:34:45','2'), 
 ('3','helium','2023-08-02','11:43:49','1'), 
 ('4','helium','2023-08-02','14:43:49','2'), 
 ('5','lithium','2023-08-03','14:02:48','1'), 
 ('6','lithium','2023-08-03','17:02:48','2'), 
 ('7','beryllium','2023-08-04','6:51:43','1'), 
 ('8','beryllium','2023-08-04','9:51:43','2'), 
 ('9','borum','2023-08-05','13:27:36','1'), 
 ('10','borum','2023-08-05','16:27:36','2'), 
 ('11','hydrogenium','2023-08-10','7:14:15','1'), 
 ('12','hydrogenium','2023-08-10','10:14:15','2'), 
 ('13','helium','2023-09-01','18:40:38','1'), 
 ('14','helium','2023-09-01','21:40:38','2'), 
 ('15','lithium','2023-09-02','15:15:58','1'), 
 ('16','lithium','2023-09-02','18:15:58','2'), 
 ('17','beryllium','2023-09-03','17:27:31','1'), 
 ('18','beryllium','2023-09-03','20:27:31','2'), 
 ('19','borum','2023-09-04','20:10:48','1'), 
 ('20','borum','2023-09-04','23:10:48','2'), 
 ('21','hydrogenium','2023-09-09','8:42:30','1'), 
 ('22','hydrogenium','2023-09-09','11:42:30','2'), 
 ('23','helium','2023-09-10','6:59:52','1'), 
 ('24','helium','2023-09-10','7:59:52','2'), 
 ('25','lithium','2023-10-01','14:08:14','1'), 
 ('26','lithium','2023-10-01','17:08:14','2'), 
 ('27','beryllium','2023-10-02','12:55:25','1'), 
 ('28','beryllium','2023-10-02','15:55:25','2'), 
 ('29','borum','2023-10-03','13:40:45','1'), 
 ('30','borum','2023-10-03','16:40:45','2'), 
 ('31','hydrogenium','2023-10-08','13:41:41','1'), 
 ('32','hydrogenium','2023-10-08','15:41:41','2'), 
 ('33','helium','2023-10-09','11:23:41','1'), 
 ('34','helium','2023-10-09','14:23:41','2'), 
 ('35','lithium','2023-10-10','7:45:28','1'), 
 ('36','lithium','2023-10-10','10:45:28','2'), 
 ('37','hydrogenium','2023-10-11','6:21:39','1'), 
 ('38','hydrogenium','2023-10-11','9:21:39','2'), 
 ('39','hydrogenium','2023-11-03','14:29:28','1'), 
 ('40','hydrogenium','2023-11-04','17:29:28','2'), 
 ('41','hydrogenium','2023-11-06','16:19:55','1'), 
 ('42','hydrogenium','2023-11-07','19:19:55','2');
 
INSERT INTO "transferredpoints" ("id","checkingpeer","checkedpeer","pointsamount") VALUES 
 ('1','beryllium','borum','1'), 
 ('2','beryllium','helium','3'), 
 ('3','beryllium','hydrogenium','1'), 
 ('4','borum','beryllium','1'), 
 ('5','borum','helium','2'), 
 ('6','borum','hydrogenium','1'), 
 ('7','borum','lithium','4'), 
 ('8','helium','beryllium','2'), 
 ('9','helium','borum','1'), 
 ('10','helium','hydrogenium','6'), 
 ('11','helium','lithium','2'), 
 ('12','hydrogenium','borum','3'), 
 ('13','hydrogenium','helium','1'), 
 ('14','hydrogenium','lithium','1'), 
 ('15','lithium','beryllium','1'), 
 ('16','lithium','borum','1'), 
 ('17','lithium','helium','4'), 
 ('18','lithium','hydrogenium','4');
 
INSERT INTO "verter" ("id","Check","State","time") VALUES 
 ('1','1','Start','01.08.2023 20:49:45'), 
 ('2','1','Success','01.08.2023 20:51:45'), 
 ('3','2','Start','02.08.2023 15:58:49'), 
 ('4','2','Success','02.08.2023 16:00:49'), 
 ('5','3','Start','03.08.2023 17:37:48'), 
 ('6','3','Success','03.08.2023 17:39:48'), 
 ('7','4','Start','04.08.2023 9:46:43'), 
 ('8','4','Success','04.08.2023 9:48:43'), 
 ('9','5','Start','05.08.2023 15:42:36'), 
 ('10','5','Success','05.08.2023 15:44:36'), 
 ('11','6','Start','10.08.2023 9:29:15'), 
 ('12','6','Success','10.08.2023 9:31:15'), 
 ('13','7','Start','01.09.2023 22:15:38'), 
 ('14','7','Success','01.09.2023 22:17:38'), 
 ('15','8','Start','02.09.2023 18:10:58'), 
 ('16','8','Success','02.09.2023 18:12:58'), 
 ('17','9','Start','03.09.2023 19:42:31'), 
 ('18','9','Success','03.09.2023 19:44:31'), 
 ('19','10','Start','05.09.2023 0:25:48'), 
 ('20','10','Success','05.09.2023 0:27:48'), 
 ('21','11','Start','09.09.2023 12:17:30'), 
 ('22','11','Success','09.09.2023 12:19:30'), 
 ('23','12','Start','10.09.2023 9:54:52'), 
 ('24','12','Success','10.09.2023 9:56:52'), 
 ('25','13','Start','01.10.2023 16:23:14'), 
 ('26','13','Success','01.10.2023 16:25:14'), 
 ('27','14','Start','02.10.2023 15:10:25'), 
 ('28','14','Success','02.10.2023 15:12:25'), 
 ('29','15','Start','03.10.2023 15:55:45'), 
 ('30','15','Success','03.10.2023 15:57:45'), 
 ('31','16','Start','08.10.2023 17:56:41'), 
 ('32','16','Success','08.10.2023 17:58:41'), 
 ('33','17','Start','09.10.2023 13:38:41'), 
 ('34','17','Success','09.10.2023 13:40:41'), 
 ('35','19','Start','11.10.2023 8:36:39'), 
 ('36','19','Success','11.10.2023 8:38:39'), 
 ('37','20','Start','03.11.2023 16:44:28'), 
 ('38','20','Success','03.11.2023 16:46:28');
 
INSERT INTO "xp" ("id","Check","numberxp") VALUES 
 ('1','1','1000'), 
 ('2','2','1000'), 
 ('3','3','1000'), 
 ('4','4','1000'), 
 ('5','5','1000'), 
 ('6','6','250'), 
 ('7','7','250'), 
 ('8','8','250'), 
 ('9','9','250'), 
 ('10','10','250'), 
 ('11','11','500'), 
 ('12','12','500'), 
 ('13','13','500'), 
 ('14','14','500'), 
 ('15','15','500'), 
 ('16','16','350'), 
 ('17','17','350'), 
 ('18','19','200'), 
 ('19','20','500'), 
 ('20','21','750'), 
 ('21','22','750');
 

-- SELECT * FROM p2p;
-- SELECT * FROM checks;
-- SELECT * FROM recommendations;
-- SELECT * FROM timetracking;
-- SELECT * FROM transferredpoints;
-- SELECT * FROM verter;
-- SELECT * FROM xp;

-- MODEL like *.csv files

/*
chmod +x data/*.csv
CALL ImportData('Checks', '/Users/janyceel/S21/sql/SQL2_Info21_v1.0-1/src/data/SQLshort - Checks.csv');
CALL ImportData('Friends', '/Users/janyceel/S21/sql/SQL2_Info21_v1.0-1/src/data/SQLshort - Friends.csv');
CALL ImportData('P2P', '/Users/janyceel/S21/sql/SQL2_Info21_v1.0-1/src/data/SQLshort - P2P.csv');
CALL ImportData('Recommendations', '/Users/janyceel/S21/sql/SQL2_Info21_v1.0-1/src/data/SQLshort - Recommendations.csv');
CALL ImportData('TimeTracking', '/Users/janyceel/S21/sql/SQL2_Info21_v1.0-1/src/data/SQLshort - TimeTracking.csv');
CALL ImportData('TransferredPoints', '/Users/janyceel/S21/sql/SQL2_Info21_v1.0-1/src/data/SQLshort - TransferredPoints.csv');
CALL ImportData('Verter', '/Users/janyceel/S21/sql/SQL2_Info21_v1.0-1/src/data/SQLshort - Verter.csv');
CALL ImportData('XP', '/Users/janyceel/S21/sql/SQL2_Info21_v1.0-1/src/data/SQLshort - XP.csv');

CALL ImportData('Checks', '/Users/janyceel/S21/sql/SQL2_Info21_v1.0-1/src/data/SQL - Checks.csv');
CALL ImportData('P2P', '/Users/janyceel/S21/sql/SQL2_Info21_v1.0-1/src/data/SQL - P2P.csv');
CALL ImportData('Verter', '/Users/janyceel/S21/sql/SQL2_Info21_v1.0-1/src/data/SQL - Verter.csv');
CALL ExportData('Checks', '/Users/janyceel/S21/sql/SQL2_Info21_v1.0-1/src/data/ExportChecks.csv');
*/
