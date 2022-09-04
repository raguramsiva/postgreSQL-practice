SET SEARCH_PATH TO air_travel;
DROP TABLE IF EXISTS q1 CASCADE;

CREATE TABLE q1 (
    pass_id INT,
    name VARCHAR(100),
    airlines INT
);

CREATE VIEW CompletedFlights AS 
SELECT flight.id as flight_id, airline
FROM Flight join Arrival on flight.id = Arrival.flight_id;

Create View CompletedBookings AS
SELECT Booking.id, airline, pass_id
FROM Booking join CompletedFlights on CompletedFlights.flight_id = Booking.flight_id;

Create View AirlineTotal AS
SELECT Passenger.id as pass_id, Passenger.firstname||' '||Passenger.surname as name, count(distinct airline) as airlines
FROM Passenger left join CompletedBookings on CompletedBookings.pass_id = Passenger.id
GROUP BY Passenger.id;

INSERT INTO q1
SELECT *
FROM AirlineTotal;
