SET SEARCH_PATH TO air_travel;
DROP TABLE IF EXISTS q2 CASCADE;

CREATE TABLE q2 (
    airline CHAR(2),
    name VARCHAR(50),
    year CHAR(4),
    seat_class seat_class,
    refund REAL
);

DROP VIEW IF EXISTS intermediate_step CASCADE;
DROP VIEW IF EXISTS FlightDepartDelay CASCADE;
DROP VIEW IF EXISTS FlightMakeUp CASCADE;
DROP VIEW IF EXISTS FlightsConsidered CASCADE;
DROP VIEW IF EXISTS IntFlight CASCADE;
DROP VIEW IF EXISTS DomFlight CASCADE;
DROP VIEW IF EXISTS IntFlight35 CASCADE;
DROP VIEW IF EXISTS IntFlight50 CASCADE;
DROP VIEW IF EXISTS DomFlight35 CASCADE;
DROP VIEW IF EXISTS DomFlight50 CASCADE;
DROP VIEW IF EXISTS FlightRefund CASCADE;
DROP VIEW IF EXISTS FlightRefundYear CASCADE;

CREATE VIEW FlightDepartDelay AS
SELECT Flight.id, (datetime - s_dep) as dep_delay, s_arv
FROM Flight, Departure
WHERE Flight.id = Departure.flight_id;

CREATE VIEW FlightMakeUp AS
SELECT FlightDepartDelay.id, dep_delay, s_arv
FROM FlightDepartDelay, Arrival
WHERE FlightDepartDelay.id = Arrival.flight_id and (datetime - s_arv) <= 0.5*dep_delay; 

CREATE VIEW FlightsConsidered AS
(SELECT * FROM FlightDepartDelay)
EXCEPT
(SELECT * FROM FlightMakeUp);

CREATE VIEW IntFlight AS
SELECT FlightsConsidered.id, dep_delay
FROM FlightsConsidered, Airport A1, Airport A2, Flight
WHERE FlightsConsidered.id = Flight.id and Flight.outbound = A1.code and Flight.inbound = A2.code
and A1.country <> A2. country;

CREATE VIEW DomFlight AS
SELECT FlightsConsidered.id, dep_delay
FROM FlightsConsidered, Airport A1, Airport A2, Flight
WHERE FlightsConsidered.id = Flight.id and Flight.outbound = A1.code and Flight.inbound = A2.code
and A1.country = A2. country;

CREATE VIEW IntFlight35 AS
SELECT id, 0.35 as discount
FROM IntFlight
WHERE '08:00:00' <= dep_delay and dep_delay < '12:00:00';

CREATE VIEW IntFlight50 AS
SELECT id, 0.5 as discount
FROM IntFlight
WHERE dep_delay >= '12:00:00';

CREATE VIEW DomFlight35 AS
SELECT id, 0.35 as discount
FROM DomFlight
WHERE '05:00:00' <= dep_delay and dep_delay < '10:00:00';

CREATE VIEW DomFlight50 AS
SELECT id, 0.5 as discount
FROM DomFlight
WHERE dep_delay >= '10:00:00';

CREATE VIEW FlightRefund AS
(SELECT * FROM IntFlight35)
union
(SELECT * FROM IntFlight50)
union
(SELECT * FROM DomFlight35)
union
(SELECT * FROM DomFlight50);

CREATE VIEW FlightRefundYear AS
SELECT FlightRefund.id, discount, extract(year from s_dep) AS year
FROM FlightRefund, Flight
WHERE FlightRefund.id = Flight.id;

CREATE VIEW Final AS
SELECT Airline.code as airline, Airline.name, FlightRefundYear.year, Booking.seat_class, sum(price*discount) as refund
FROM FlightRefundYear, Airline, Flight, Booking
WHERE FlightRefundYear.id = Flight.id and Flight.id = Booking.flight_id and Flight.airline = Airline.code
GROUP BY Airline.code, Airline.name, FlightRefundYear.year, Booking.seat_class
Having count(Booking.id) > 0;

INSERT INTO q2
SELECT * 
FROM FINAL;