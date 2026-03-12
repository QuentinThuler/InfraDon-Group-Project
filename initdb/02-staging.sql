-- Active: 1772721152986@@127.0.0.1@5432@infradon
COPY staging.inventaire_mobilier 
FROM '/docker-data/inventaire_mobilier.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

COPY staging.interventions
FROM '/docker-data/interventions.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

COPY staging.signalements
FROM '/docker-data/signalements.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');