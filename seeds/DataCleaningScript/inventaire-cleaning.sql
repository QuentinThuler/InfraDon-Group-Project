-- Active: 1772721397266@@127.0.0.1@5432@infradon
-- ================================================================
-- SCRIPT DE STAGING, NETTOYAGE ET STANDARDISATION
-- Fichier source : inventaire_mobilier.csv
-- Base de données : InfraDon (PostgreSQL)
-- ================================================================
--
-- ANOMALIES DÉTECTÉES DANS LA SOURCE :
--
--  [id]               • Séparateur incohérent : '_' vs '-'  (B_3 / B-001)
--                     • 1 doublon : id='1006' présent 2 fois
--                       (lieu 'Place de la Gare' vs 'place de la gare')
--
--  [type]             • 22 variantes pour 10 valeurs canoniques
--                       (ex: 'banc','Banc','banc public' → 'Banc')
--                     • 'corbeille' → 'Poubelle'
--                     • 'borne EV','Borne recharge' → 'Borne recharge EV'
--                     • 'Panneau','panneau affichage' → 'Panneau affichage'
--
--  [materiau]         • Casse incohérente : 'metal','métal','Métal' → 'Métal'
--                     • 'pierre' vs 'Pierre' → 'Pierre'
--                     • Valeurs erronées : 'LED','sodium' (types de lampe,
--                       pas des matériaux) → NULL
--                     • Vide '' → NULL
--
--  [lieu]             • 'place de la gare' (minuscule) vs 'Place de la Gare'
--
--  [latitude/longitude] • Séparateur décimal virgule ',' au lieu de '.'
--                       • Vide '' → NULL
--
--  [date_installation]• 4 formats coexistent :
--                       DD.MM.YYYY (41 valeurs) | YYYY-MM-DD (27 valeurs)
--                       YYYY seul  (12 valeurs) | mois_FR YYYY (22 valeurs)
--                     • Tous convertis vers ISO 8601 : YYYY-MM-DD
--
--  [etat]             • Tout en minuscules → majuscule initiale
--                       'bon' → 'Bon' | 'usé' → 'Usé'
--                       'à remplacer' → 'À remplacer'
--
--  [remarques]        • Vide '' → NULL
--
-- PIPELINE :
--   ÉTAPE 1  — Création de la table de staging (données brutes)
--   ÉTAPE 2  — Import CSV via COPY
--   ÉTAPE 3  — Nettoyage et standardisation (UPDATE in-place)
--              3a  TRIM global
--              3b  Dédoublonnage sur id
--              3c  Standardisation id          (séparateur '_' → '-')
--              3d  Standardisation type
--              3e  Standardisation materiau
--              3f  Standardisation lieu
--              3g  Standardisation latitude / longitude
--              3h  Standardisation date_installation
--              3i  Standardisation etat
--              3j  Nullification des vides résiduels
--   ÉTAPE 4  — Validation post-nettoyage (requêtes de contrôle)
--   ÉTAPE 5  — Vue de contrôle final
--   ÉTAPE 6  — Transfert vers la table de production
-- ================================================================



-- ================================================================
-- ÉTAPE 1 — CRÉATION DE LA TABLE DE STAGING
-- ================================================================
-- Toutes les colonnes sont déclarées en TEXT.
-- Raison : les données brutes contiennent des formats hétérogènes
-- (dates textuelles, virgule comme séparateur décimal, valeurs
-- mixtes...) qui provoqueraient des erreurs de CAST immédiat.
-- On typera proprement lors du transfert en production (étape 6).
--
-- stg_id       : identifiant technique interne d'import
-- stg_source   : traçabilité du fichier source
-- stg_imported : horodatage de l'import
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
-- Le fichier CSV présente les caractéristiques suivantes :
--   • Encodage : UTF-8 avec BOM (xEF xBB xBF)  → 'UTF8'
--   • Séparateur de colonnes : point-virgule ';'
--   • Séparateur décimal dans lat/lon : virgule ','
--   • Fin de ligne : CRLF (Windows)
--   • Ligne d'en-tête : oui (HEADER true)
--   • 121 lignes de données (dont 1 doublon)
--
-- On liste explicitement les 9 colonnes du CSV pour éviter
-- toute confusion avec les colonnes techniques stg_source et
-- stg_imported qui ont des valeurs DEFAULT et ne doivent pas
-- être alimentées par le COPY.
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
-- Première opération systématique : suppression des espaces
-- de début et de fin sur toutes les colonnes TEXT.
-- Excel exporte parfois des espaces invisibles autour des valeurs.
-- TRIM() est appliqué avant toute autre transformation pour que
-- les comparaisons CASE WHEN suivantes soient fiables.
-- ----------------------------------------------------------------

UPDATE stg_inventaire
SET
    id                = TRIM(id),
    type              = TRIM(type),
    materiau          = TRIM(materiau),
    lieu              = TRIM(lieu),
    latitude          = TRIM(latitude),
    longitude         = TRIM(longitude),
    date_installation = TRIM(date_installation),
    etat              = TRIM(etat),
    remarques         = TRIM(remarques);

-- ----------------------------------------------------------------
-- ÉTAPE 3 — STANDARDISATION : CASE WHEN + LOWER + TRIM
-- ----------------------------------------------------------------
-- On passe toute valeur en minuscule (LOWER) pour comparer sans
-- tenir compte de la casse, puis on applique un CASE WHEN exhaustif
-- qui couvre :
--   • toutes les variantes de casse (banc / Banc)
--   • tous les synonymes (banc public, corbeille, borne EV…)
--   • la valeur de repli ELSE avec INITCAP pour les cas imprévus
--
-- On utilise LOWER(TRIM(...)) et non directement la valeur déjà
-- trimmée pour garantir la robustesse même si un TRIM préalable
-- avait été sauté.
-- ----------------------------------------------------------------
 
UPDATE stg_inventaire
SET type =
    CASE LOWER(TRIM(type))
        WHEN 'banc'        THEN 'Banc'
        WHEN 'banc public' THEN 'Banc'

        WHEN 'fontaine'          THEN 'Fontaine'
        WHEN 'fontaine publique' THEN 'Fontaine'
 
        WHEN 'lampadaire' THEN 'Lampadaire'
        WHEN 'lampadaire led' THEN 'Lampadaire LED'
        WHEN 'lampadaire sodium' THEN 'Lampadaire sodium'
 
        WHEN 'poubelle'  THEN 'Poubelle'
        WHEN 'corbeille' THEN 'Poubelle'
        WHEN 'poubelle tri' THEN 'Poubelle'

        WHEN 'borne ev'          THEN 'Borne recharge EV'
        WHEN 'borne recharge'    THEN 'Borne recharge EV'
        WHEN 'borne recharge ev' THEN 'Borne recharge EV'
 
        WHEN 'panneau'           THEN 'Panneau affichage'
        WHEN 'panneau affichage' THEN 'Panneau affichage'
        WHEN 'panneau info' THEN 'Panneau info'
 
        ELSE COALESCE(INITCAP(TRIM(type)), NULL)
    END
WHERE type IS NOT NULL;

-- on garde que les données des banc
DELETE FROM stg_inventaire WHERE type != 'Banc';

-- ================================================================
-- STANDARDISATION — colonne `materiau` de stg_inventaire
-- ================================================================
-- Données brutes observées dans le CSV (121 lignes) :
--
--
-- Valeurs cibles après standardisation :
--   'Bois' | 'Métal' | NULL
-- ================================================================

-- ----------------------------------------------------------------
-- ÉTAPE 3 — NORMALISATION vers les valeurs canoniques
-- ----------------------------------------------------------------
-- On résout les 3 problèmes restants en un seul passage CASE :
--
--   Problème 1 — Casse mixte :
--     'bois' / 'Bois' → 'Bois'
--     'métal' / 'Métal' → 'Métal'
--
--   Problème 2 — Accent manquant :
--     'metal' (sans accent) → 'Métal'
--
-- LOWER() est appliqué sur la valeur comparée pour rendre
-- le matching insensible à la casse résiduelle.
-- COALESCE garantit que les NULL traversent sans être altérés.
-- ----------------------------------------------------------------
 
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

select * from stg_inventaire;