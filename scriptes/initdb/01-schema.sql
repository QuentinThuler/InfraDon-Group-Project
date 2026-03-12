-- ===========================================
-- 01-schema.sql
-- Schéma de la base de données spatiale
-- Canton de Vaud - Communes et Rivières
-- ===========================================

-- Activer l'extension PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;

-- ===========================================
-- TABLE: communes
-- Représente les communes vaudoises (points)
-- Coordonnées en WGS84 (SRID 4326)
-- ===========================================
CREATE TABLE communes (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    district VARCHAR(50) NOT NULL,
    population INTEGER,
    superficie_km2 DECIMAL(10,2),
    geom GEOMETRY(POINT, 4326)
);

-- ===========================================
-- TABLE: rivieres
-- Représente les rivières du canton (lignes)
-- Coordonnées en WGS84 (SRID 4326)
-- ===========================================
CREATE TABLE rivieres (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    longueur_km DECIMAL(10,2),
    geom GEOMETRY(LINESTRING, 4326)
);

-- ===========================================
-- INDEX SPATIAUX
-- Améliore les performances des requêtes spatiales
-- ===========================================
CREATE INDEX idx_communes_geom ON communes USING GIST (geom);
CREATE INDEX idx_rivieres_geom ON rivieres USING GIST (geom);
