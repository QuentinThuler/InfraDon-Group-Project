-- Active: 1772721397266@@127.0.0.1@5432@infradon
-- ================================================================
-- SCRIPT DE STAGING, NETTOYAGE ET STANDARDISATION
-- Fichier source : inventaire_mobilier_clean.csv
-- Base de données : InfraDon (PostgreSQL)
-- ================================================================




-- ================================================================
-- ÉTAPE 1 — CRÉATION DE LA TABLE DE STAGING
-- ================================================================


DROP TABLE IF EXISTS stg_inventaire CASCADE;

CREATE TABLE stg_inventaire (
    stg_id             SERIAL          PRIMARY KEY,
    id                 TEXT,
    type               TEXT,
    materiau           TEXT,
    lieu               TEXT,
    latitude           TEXT,
    longitude          TEXT,
    date_installation  TEXT,
    etat               TEXT,
    remarques          TEXT
);


-- ================================================================
-- ÉTAPE 2 — IMPORT CSV DANS LE STAGING
-- ================================================================

COPY stg_inventaire (id, type, materiau, lieu, latitude, longitude, date_installation, etat, remarques)
FROM '/docker-data/inventaire_mobilier_clean.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ';', ENCODING 'UTF8');


-- ================================================================
-- ÉTAPE 3 — NETTOYAGE ET STANDARDISATION
-- ================================================================

-- ----------------------------------------------------------------
-- 3a — TRIM global
-- ----------------------------------------------------------------


UPDATE stg_inventaire
SET
    id                = TRIM(id),
    type              = TRIM(type),
    materiau          = TRIM(materiau),
    lieu              = INITCAP(TRIM(lieu)),
    latitude          = TRIM(latitude),
    longitude         = TRIM(longitude),
    date_installation = TRIM(date_installation),
    etat              = TRIM(etat),
    remarques         = TRIM(remarques);

-- ----------------------------------------------------------------
-- ÉTAPE 3 — STANDARDISATION : CASE WHEN + LOWER + TRIM
-- ----------------------------------------------------------------

 
UPDATE stg_inventaire
SET type =
    CASE LOWER(TRIM(type))
        WHEN 'banc'        THEN 'Banc'
        WHEN 'banc public' THEN 'Banc'
        ELSE COALESCE(INITCAP(TRIM(type)), NULL)
    END
WHERE type IS NOT NULL;

-- on garde que les données des banc
DELETE FROM stg_inventaire WHERE type != 'Banc';

-- ================================================================
-- STANDARDISATION — colonne `materiau` de stg_inventaire
-- ================================================================

-- Valeurs cibles après standardisation :
--   'Bois' | 'Métal' | NULL
-- ================================================================
 
UPDATE stg_inventaire
SET materiau =
    CASE LOWER(TRIM(materiau))
    WHEN 'bois'  THEN 'Bois'
    WHEN 'métal' THEN 'Métal'
    WHEN 'metal' THEN 'Métal'
    ELSE COALESCE(materiau, NULL)
END
WHERE materiau IS NOT NULL;

-- ----------------------------------------------------------------
-- ÉTAPE 2 — FORMAT DD.MM.YYYY  →  YYYY-MM-DD
-- ----------------------------------------------------------------
-- Détection par wildcard LIKE :
--   '__.__.____ ' = 2 chars + point + 2 chars + point + 4 chars
-- Reconstruction avec SPLIT_PART() sur le délimiteur '.' :
--   SPLIT_PART('08.04.2019', '.', 1) → '08'   (jour)
--   SPLIT_PART('08.04.2019', '.', 2) → '04'   (mois)
--   SPLIT_PART('08.04.2019', '.', 3) → '2019' (année)
-- CONCAT réassemble dans l'ordre YYYY-MM-DD.
-- ----------------------------------------------------------------
 
UPDATE stg_inventaire
SET date_installation = CONCAT(
        SPLIT_PART(date_installation, '.', 3), '-',   -- YYYY
        SPLIT_PART(date_installation, '.', 2), '-',   -- MM
        SPLIT_PART(date_installation, '.', 1)         -- DD
    )
WHERE date_installation LIKE '__.__.____';            -- wildcard : 2+2+4 chiffres séparés par des points


-- ----------------------------------------------------------------
-- ÉTAPE 3 — FORMAT YYYY seul  →  YYYY-01-01
-- ----------------------------------------------------------------
-- Détection : exactement 4 caractères, tous chiffres.
-- LIKE '____' = exactement 4 caractères quelconques.
-- On affine en excluant les chaînes qui contiennent '-'
-- (pour ne pas attraper accidentellement un YYYY-MM-DD tronqué).
-- CONCAT ajoute simplement '-01-01'.
-- ----------------------------------------------------------------
 
UPDATE stg_inventaire
SET date_installation = CONCAT(date_installation, '-01-01')
WHERE date_installation LIKE '____'                   -- wildcard : exactement 4 caractères
  AND date_installation NOT LIKE '%-%';               -- exclut tout ce qui contient un tiret


-- ----------------------------------------------------------------
-- ÉTAPE 5 — FORMAT 'Mois FR YYYY'  →  YYYY-MM-01
-- ----------------------------------------------------------------
-- Ces valeurs sont les seules restantes après les étapes 2, 3, 4.
-- Toutes contiennent un espace séparant le nom du mois et l'année.
-- SPLIT_PART(..., ' ', 1) → nom du mois en français
-- SPLIT_PART(..., ' ', 2) → année (YYYY)
-- LOWER() + LIKE pour matching insensible à la casse.
--
-- Chaque nom de mois est traité par une UPDATE dédiée.
-- Le wildcard '%' en fin de LIKE absorbe l'année qui suit.
-- Le wildcard '_' gère les caractères accentués qui peuvent
-- varier selon l'encodage du CSV (é, û, etc.).
-- ----------------------------------------------------------------
 
-- janvier
UPDATE stg_inventaire
SET date_installation = CONCAT(
        SPLIT_PART(TRIM(date_installation), ' ', 2), '-01-01'
    )
WHERE LOWER(TRIM(date_installation)) LIKE 'janvier %';
 
-- février  (wildcard _ gère le é selon encodage)
UPDATE stg_inventaire
SET date_installation = CONCAT(
        SPLIT_PART(TRIM(date_installation), ' ', 2), '-02-01'
    )
WHERE LOWER(TRIM(date_installation)) LIKE 'f_vrier %';
 
-- mars
UPDATE stg_inventaire
SET date_installation = CONCAT(
        SPLIT_PART(TRIM(date_installation), ' ', 2), '-03-01'
    )
WHERE LOWER(TRIM(date_installation)) LIKE 'mars %';
 
-- avril
UPDATE stg_inventaire
SET date_installation = CONCAT(
        SPLIT_PART(TRIM(date_installation), ' ', 2), '-04-01'
    )
WHERE LOWER(TRIM(date_installation)) LIKE 'avril %';
 
-- mai
UPDATE stg_inventaire
SET date_installation = CONCAT(
        SPLIT_PART(TRIM(date_installation), ' ', 2), '-05-01'
    )
WHERE LOWER(TRIM(date_installation)) LIKE 'mai %';
 
-- juin
UPDATE stg_inventaire
SET date_installation = CONCAT(
        SPLIT_PART(TRIM(date_installation), ' ', 2), '-06-01'
    )
WHERE LOWER(TRIM(date_installation)) LIKE 'juin %';
 
-- juillet
UPDATE stg_inventaire
SET date_installation = CONCAT(
        SPLIT_PART(TRIM(date_installation), ' ', 2), '-07-01'
    )
WHERE LOWER(TRIM(date_installation)) LIKE 'juillet %';
 
-- août  (wildcard _ gère le û selon encodage)
UPDATE stg_inventaire
SET date_installation = CONCAT(
        SPLIT_PART(TRIM(date_installation), ' ', 2), '-08-01'
    )
WHERE LOWER(TRIM(date_installation)) LIKE 'ao_t %';
 
-- septembre
UPDATE stg_inventaire
SET date_installation = CONCAT(
        SPLIT_PART(TRIM(date_installation), ' ', 2), '-09-01'
    )
WHERE LOWER(TRIM(date_installation)) LIKE 'septembre %';
 
-- octobre
UPDATE stg_inventaire
SET date_installation = CONCAT(
        SPLIT_PART(TRIM(date_installation), ' ', 2), '-10-01'
    )
WHERE LOWER(TRIM(date_installation)) LIKE 'octobre %';
 
-- novembre
UPDATE stg_inventaire
SET date_installation = CONCAT(
        SPLIT_PART(TRIM(date_installation), ' ', 2), '-11-01'
    )
WHERE LOWER(TRIM(date_installation)) LIKE 'novembre %';
 
-- décembre  (wildcard _ gère le é selon encodage)
UPDATE stg_inventaire
SET date_installation = CONCAT(
        SPLIT_PART(TRIM(date_installation), ' ', 2), '-12-01'
    )
WHERE LOWER(TRIM(date_installation)) LIKE 'd_cembre %';
