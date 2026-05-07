-- Active: 1772721397266@@127.0.0.1@5432@infradon
-- ================================================================
-- SCRIPT DE STAGING, NETTOYAGE ET STANDARDISATION
-- Fichier source : interventions.csv
-- Base de données : InfraDon (PostgreSQL)
-- ================================================================




-- ================================================================
-- ÉTAPE 1 — CRÉATION DE LA TABLE DE STAGING
-- ================================================================


DROP TABLE IF EXISTS stg_intervention CASCADE;

CREATE TABLE stg_intervention (
    stg_id             SERIAL PRIMARY KEY,
    date                 TEXT,
    objet               TEXT,
    type_intervention           TEXT,
    technicien               TEXT,
    duree           TEXT,
    cout_materiel          TEXT,
    remarques          TEXT
);


-- ================================================================
-- ÉTAPE 2 — IMPORT CSV DANS LE STAGING
-- ================================================================

COPY stg_intervention (date, objet, type_intervention, technicien, duree, cout_materiel, remarques)
FROM '/docker-data/interventions.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ';', ENCODING 'UTF8');


-- ================================================================
-- ÉTAPE 3 — NETTOYAGE ET STANDARDISATION
-- ================================================================

-- ----------------------------------------------------------------
-- 3a — TRIM global
-- ----------------------------------------------------------------


UPDATE stg_intervention
SET
    date                = TRIM(date),
    objet              = TRIM(objet),
    type_intervention          = TRIM(type_intervention),
    technicien              = TRIM(technicien),
    duree          = TRIM(duree),
    cout_materiel         = TRIM(cout_materiel),
    remarques = TRIM(remarques);


-- on garde que les données des banc
DELETE
FROM stg_intervention
WHERE objet NOT LIKE '%banc%'
   AND objet NOT LIKE '%Banc%';

-- ----------------------------------------------------------------
-- ÉTAPE 3 — STANDARDISATION : CASE WHEN + LOWER + TRIM
-- banc public Y-Parc -> Banc Y-Parc
-- réparation -> Réparation
-- JM -> Jean-Marque Bonvin
-- p.Alves -> Alves Pedro
-- ----------------------------------------------------------------
 
UPDATE stg_intervention
SET objet =
    CASE
        WHEN LOWER(objet) LIKE 'banc public%'
            THEN 'Banc ' || INITCAP(SUBSTRING(objet FROM 12))
        WHEN LOWER(objet) LIKE 'banc%'
            THEN 'Banc ' || INITCAP(SUBSTRING(objet FROM 5))
        ELSE COALESCE(INITCAP(objet), NULL)
    END;

UPDATE stg_intervention
SET type_intervention = COALESCE(INITCAP(TRIM(type_intervention)), NULL);

UPDATE stg_intervention
SET technicien =
    CASE LOWER(technicien)
        WHEN 'jm' THEN 'Bonvin Jean-Marc'
        WHEN 'jean-marc' THEN 'Bonvin Jean-Marc'
        WHEN 'jean-marc bonvin' THEN 'Bonvin Jean-Marc'
        WHEN 'p. alves' THEN 'Alves Pedro'
        WHEN 'pedro' THEN 'Alves Pedro'
        ELSE COALESCE(INITCAP(technicien), NULL)
    END;

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
 
UPDATE stg_intervention
SET date = CONCAT(
        SPLIT_PART(date, '.', 3), '-',   -- YYYY
        SPLIT_PART(date, '.', 2), '-',   -- MM
        SPLIT_PART(date, '.', 1)         -- DD
    )
WHERE date LIKE '__.__.____';            -- wildcard : 2+2+4 chiffres séparés par des points


-- ----------------------------------------------------------------
-- ÉTAPE 2 — FORMAT durée
-- 1h -> 1
-- 30min -> 0,5
-- 2h30 -> 2,5
-- ----------------------------------------------------------------
UPDATE stg_intervention
SET duree =
    CASE LOWER(duree)
        WHEN '30 min' THEN '0,5'
        WHEN '1h30' THEN '1,5'
        WHEN '3h' THEN '3'
        WHEN '2h' THEN '2'
        WHEN '1h' THEN '1'
        WHEN 'une matinée' THEN '4'
        WHEN 'une journée' THEN '8'
        ELSE COALESCE(INITCAP(duree), NULL)
    END;

-- ----------------------------------------------------------------
-- ÉTAPE 2 — FORMAT cout_materiel
-- CHF 120.- -> 120,00
-- 120.- -> 120,00
-- ----------------------------------------------------------------
UPDATE stg_intervention
SET duree =
    CASE LOWER(duree)
        WHEN '30 min' THEN '0,5'
        WHEN '1h30' THEN '1,5'
        WHEN '3h' THEN '3'
        WHEN '2h' THEN '2'
        WHEN '1h' THEN '1'
        WHEN 'une matinée' THEN '4'
        WHEN 'une journée' THEN '8'
        ELSE COALESCE(INITCAP(duree), NULL)
    END;

UPDATE stg_intervention
SET cout_materiel =
    CASE 
        WHEN LOWER(cout_materiel) IN ('gratuit', 'garantie')
            THEN '0'
        ELSE
            TRIM(
                REPLACE(
                    REPLACE(
                        UPPER(cout_materiel), 
                    'CHF', ''), 
                '.-', '')
            )
    END
WHERE cout_materiel IS NOT NULL;

-- Créer une table temporaire avec l'extraction propre
CREATE TABLE stg_intervention_parsed AS
SELECT 
    s.*,
    -- Extraction du type de mobilier
    CASE 
        -- "Le Banc Public Devant..." -> "Banc"
        WHEN s.objet ~* '^Le .* (Public|Devant|Près)' THEN 
            TRIM(REGEXP_REPLACE(REGEXP_REPLACE(s.objet, '^Le ', '', 'i'), ' (Public|Devant|Près).*$', '', 'i'))
        -- "Banc Public Près De..." -> "Banc"
        WHEN s.objet ~* '^[A-Za-z]+ Public (Près|Devant)' THEN 
            TRIM(SPLIT_PART(s.objet, ' Public', 1))
        -- "Banc Près De..." -> "Banc"
        WHEN s.objet ~* '^[A-Za-z]+ (Près|Devant)' THEN 
            TRIM(REGEXP_REPLACE(s.objet, ' (Près|Devant).*$', '', 'i'))
        -- "Banc Place De..." -> "Banc" (cas par défaut)
        ELSE 
            TRIM(SPLIT_PART(s.objet, ' ', 1))
    END as type_mobilier_clean,
    -- Extraction du lieu
    CASE 
        -- "... Devant Chemin De Maillefer" -> "Chemin De Maillefer"
        WHEN s.objet ~* 'Devant ' THEN 
            TRIM(REGEXP_REPLACE(s.objet, '^.*Devant ', '', 'i'))
        -- "... Près De Y-Parc" -> "Y-Parc"
        WHEN s.objet ~* 'Près De ' THEN 
            TRIM(REGEXP_REPLACE(s.objet, '^.*Près De ', '', 'i'))
        --"Banc Place De La Gare" -> "Place De La Gare"
        ELSE 
            TRIM(REGEXP_REPLACE(s.objet, '^(Le |La |L'')?[A-Za-z]+ (Public )?', '', 'i'))
    END as type_lieu_clean
FROM stg_intervention s;