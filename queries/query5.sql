SET SEARCH_PATH TO air_travel;
DROP TABLE IF EXISTS q5 CASCADE;

CREATE TABLE q5 (
	destination CHAR(3),
	num_flights INT
);

DROP VIEW IF EXISTS intermediate_step CASCADE;
DROP VIEW IF EXISTS day CASCADE;
DROP VIEW IF EXISTS n CASCADE;

CREATE VIEW day AS
SELECT day::date as day FROM q5_parameters;
-- can get the given date using: (SELECT day from day)

CREATE VIEW n AS
SELECT n FROM q5_parameters;
-- can get the given number of flights using: (SELECT n from n)

-- WITH RECURSIVE numbers AS (
-- (SELECT 1 AS n) -- the base query
-- UNION ALL
-- (SELECT n + 1 FROM numbers WHERE n < 10) -- the recursive query
-- )
-- SELECT * FROM numbers;

INSERT INTO q5
WITH RECURSIVE Hop AS (

	-- the base query
	(SELECT CAST(Flight.inbound AS CHAR(3)) AS destination, 1 AS num_flights, id, outbound, inbound, s_dep, s_arv
	FROM Flight
	WHERE outbound = 'YYZ' 
	and s_dep >= (SELECT day from day) and (s_dep - (SELECT day from day)) <= '23:59:59') 

	UNION ALL
	
	-- the recursive query
	(SELECT CAST(f.inbound AS CHAR(3)), num_flights + 1, f.id, f.outbound, f.inbound, f.s_dep, f.s_arv
	FROM Hop h, Flight f
	WHERE num_flights < (SELECT n from n) and f.id <> h.id and h.destination = f.outbound
	and f.s_dep >= h.s_arv and (f.s_dep - h.s_arv) <=  '23:59:59') 

)


