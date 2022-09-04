SET SEARCH_PATH TO air_travel;
DROP TABLE IF EXISTS q3 CASCADE;

CREATE TABLE q3 (
    outbound VARCHAR(30),
    inbound VARCHAR(30),
    direct INT,
    one_con INT,
    two_con INT,
    earliest timestamp
);


DROP VIEW IF EXISTS intermediate_step CASCADE;
DROP VIEW IF EXISTS CanadaUSA CASCADE;
DROP VIEW IF EXISTS CityPairs CASCADE;
DROP VIEW IF EXISTS AllFlightInfo CASCADE;
DROP VIEW IF EXISTS DirectFlight CASCADE;
DROP VIEW IF EXISTS OneConnection CASCADE;
DROP VIEW IF EXISTS OneConnectionRoute CASCADE;
DROP VIEW IF EXISTS TwoConnection CASCADE;
DROP VIEW IF EXISTS TwoConnectionRoute CASCADE;
DROP VIEW IF EXISTS AllRoutes CASCADE;

CREATE VIEW CanadaUSA AS
SELECT code, city, country
FROM Airport
WHERE country = 'Canada' or country = 'USA';

CREATE VIEW CityPairs AS
SELECT distinct t1.code as code1, t1.city as city1, t2.code as code2, t2.city as city2
FROM CanadaUSA t1, CanadaUSA t2
WHERE t1.country <> t2.country;

Create VIEW AllFlightInfo AS
SELECT id, outbound, inbound, s_dep, s_arv
FROM Flight
WHERE date_part('year', s_dep) = 2022 and date_part('month', s_dep) = 4 and date_part('day', s_dep) = 30
and date_part('year', s_arv) = 2022 and date_part('month', s_arv) = 4 and date_part('day', s_arv) = 30;

Create VIEW DirectFlight AS
SELECT city1, city2, count(id) as direct, min(s_arv) as earliest_direct
FROM CityPairs left join AllFlightInfo on code1 = outbound and code2 = inbound
GROUP BY city1, city2;

CREATE VIEW OneConnection AS
SELECT f1.id as f1, f1.outbound as f1out, f1.inbound as f1in, f1.s_dep as f1s_dep, f1.s_arv as f1s_arv, 
f2.id as f2, f2.outbound as f2out, f2.inbound as f2in, f2.s_dep as f2s_dep, f2.s_arv as f2s_arv
FROM AllFlightInfo f1, AllFlightInfo f2
WHERE f1.id <> f2.id and f1.inbound = f2.outbound and (f2.s_dep - f1.s_arv) >= '00:30:00';

CREATE VIEW OneConnectionRoute AS
SELECT city1, city2, count(f1) as one_con, min(f2s_arv) as earliest_one
FROM CityPairs left join OneConnection on code1 = f1out and code2 = f2in
GROUP BY city1, city2;

CREATE VIEW TwoConnection AS
SELECT f1.id as f1, f1.outbound as f1out, f1.inbound as f1in, f1.s_dep as f1s_dep, f1.s_arv as f1s_arv,
f2.id as f2, f2.outbound as f2out, f2.inbound as f2in, f2.s_dep as f2s_dep, f2.s_arv as f2s_arv,
f3.id as f3, f3.outbound as f3out, f3.inbound as f3in, f3.s_dep as f3s_dep, f3.s_arv as f3s_arv
FROM AllFlightInfo f1, AllFlightInfo f2, AllFlightInfo F3
WHERE f1.id <> f2.id and f1.id <> f3.id and f2.id <> f3.id 
and f1.inbound = f2.outbound and f2.inbound = f3.outbound 
and (f1.s_arv + '00:30:00') <= f2.s_dep and (f2.s_arv + '00:30:00') <= f3.s_dep;

CREATE VIEW TwoConnectionRoute AS
SELECT city1, city2, count(f1) as two_con, min(f3s_arv) as earliest_two
FROM CityPairs left join TwoConnection on code1 = f1out and code2 = f3in
GROUP BY city1, city2;

CREATE VIEW AllRoutes AS
SELECT city1 as outbound, city2 as inbound, direct, one_con, two_con, LEAST(earliest_direct, earliest_one, earliest_two) as earliest
FROM DirectFlight natural join OneConnectionRoute natural join TwoConnectionRoute;

INSERT INTO q3
SELECT * 
FROM AllRoutes;




