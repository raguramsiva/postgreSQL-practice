SET SEARCH_PATH TO air_travel;
DROP TABLE IF EXISTS q4 CASCADE;

CREATE TABLE q4 (
	airline CHAR(2),
	tail_number CHAR(5),
	very_low INT,
	low INT,
	fair INT,
	normal INT,
	high INT
);

DROP VIEW IF EXISTS intermediate_step CASCADE;
DROP VIEW IF EXISTS DepartedFlights CASCADE;
DROP VIEW IF EXISTS AllPlanes CASCADE;
DROP VIEW IF EXISTS DepartedFlightsBookings CASCADE;
DROP VIEW IF EXISTS FlightOccupancy CASCADE;
DROP VIEW IF EXISTS DepartedFlightsOccupancy CASCADE;
DROP VIEW IF EXISTS PlanesAllInfo CASCADE;
DROP VIEW IF EXISTS very_low CASCADE;
DROP VIEW IF EXISTS low CASCADE;
DROP VIEW IF EXISTS fair CASCADE;
DROP VIEW IF EXISTS normal CASCADE;
DROP VIEW IF EXISTS high CASCADE;
DROP VIEW IF EXISTS all_very_low CASCADE;
DROP VIEW IF EXISTS all_low CASCADE;
DROP VIEW IF EXISTS all_fair CASCADE;
DROP VIEW IF EXISTS all_normal CASCADE;
DROP VIEW IF EXISTS all_high CASCADE;
DROP VIEW IF EXISTS Final CASCADE;

CREATE VIEW DepartedFlights AS
SELECT *
FROM Flight, Departure
WHERE Flight.id = Departure.flight_id;

CREATE VIEW AllPlanes AS
SELECT airline as airline_code, tail_number, capacity_economy + capacity_business + capacity_first as capacity
FROM Airline, Plane
WHERE Airline.code = Plane.airline;

CREATE VIEW DepartedFlightsBookings AS
SELECT distinct DepartedFlights.id, pass_id, seat_class, row, letter
FROM DepartedFlights, Booking
WHERE DepartedFlights.id = Booking.flight_id;

CREATE VIEW FlightOccupancy AS
SELECT id as occupancy_id, count(*) as occupancy
FROM  DepartedFlightsBookings
GROUP BY id;

CREATE VIEW DepartedFlightsOccupancy AS
SELECT id, airline, plane, flight_id, occupancy
FROM DepartedFlights, FlightOccupancy
WHERE DepartedFlights.id = FlightOccupancy.occupancy_id;

CREATE VIEW PlanesAllInfo AS
SELECT flight_id, occupancy, airline_code, tail_number, capacity, (cast(occupancy as float)/cast(capacity as float))*100 as percentage
FROM DepartedFlightsOccupancy right join AllPlanes on DepartedFlightsOccupancy.airline = AllPlanes.airline_code and DepartedFlightsOccupancy.plane = AllPlanes.tail_number;

CREATE VIEW very_low AS
SELECT airline_code as airline, tail_number, percentage
FROM PlanesAllInfo
WHERE 0 <= percentage and percentage < 20;

CREATE VIEW low AS
SELECT airline_code, tail_number, percentage
FROM PlanesAllInfo
WHERE 20 <= percentage and percentage < 40;

CREATE VIEW fair AS
SELECT airline_code, tail_number, percentage
FROM PlanesAllInfo
WHERE 40 <= percentage and percentage < 60;

CREATE VIEW normal AS
SELECT airline_code, tail_number, percentage
FROM PlanesAllInfo
WHERE 60 <= percentage and percentage < 80;

CREATE VIEW high AS
SELECT airline_code, tail_number, percentage
FROM PlanesAllInfo
WHERE percentage >= 80;

CREATE VIEW all_very_low AS
SELECT airline_code, tail_number, count(percentage) as very_low 
FROM AllPlanes natural left join very_low
GROUP BY airline_code, tail_number;

CREATE VIEW all_low AS
SELECT airline_code, tail_number, count(percentage) as low 
FROM AllPlanes natural left join low
GROUP BY airline_code, tail_number;

CREATE VIEW all_fair AS
SELECT airline_code, tail_number, count(percentage) as fair
FROM AllPlanes natural left join fair
GROUP BY airline_code, tail_number;

CREATE VIEW all_normal AS
SELECT airline_code, tail_number, count(percentage) as normal
FROM AllPlanes natural left join normal
GROUP BY airline_code, tail_number;

CREATE VIEW all_high AS
SELECT airline_code, tail_number, count(percentage) as high 
FROM AllPlanes natural left join high
GROUP BY airline_code, tail_number;

CREATE VIEW Final AS
SELECT airline_code as airline, tail_number, very_low, low, fair, normal, high
FROM all_very_low natural join all_low natural join all_fair natural join all_normal natural join all_high;

INSERT INTO q4
SELECT * 
FROM Final;
