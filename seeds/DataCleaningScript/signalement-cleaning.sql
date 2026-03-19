-- Active: 1772721152986@@127.0.0.1@5432@postgres
-- ================================================================
-- SCRIPT DE STAGING, NETTOYAGE ET STANDARDISATION
-- Fichier source : signalement-cleaning.csv
-- Base de données : InfraDon (PostgreSQL)
-- ================================================================
--
-- ANOMALIES DÉTECTÉES DANS LA SOURCE :
--
--  [id]               • Pas d'ID
--
--  [date]             • OK
--
--  [signale_par]      • 11 valeurs canoniques
--                       Mme Weber, Mme Rochat, Mme Dupont, M. Pereira, M. Keller, patrouille JM, concierge école, email citoyen, un passant, habitant du quartier, un habitant
--                     • 'M. Keller' → 'Mme Keller'
--                     • 'M. Pereira' → 'Mme Pereira'
--                     • 'un passant' → 'Passant'
--                     • 'un habitant' → 'Habitant'
--                     • 'habitant du quartier' → 'Habitant quartier'
--                     • Vide '' → NULL
--
--  [objet]            • Casse incohérente : 'banc' → 'Banc', 'lampadaire' → 'Lampadaire', 'fontaine' → 'Fontaine', 'poubelle' → 'Poubelle', 'panneau' → 'Panneau', 'borne' → 'Borne'
--                     • 'banc' → 'Banc'
--                     • 'le Banc' → 'Banc'
--                     • 'le banc' → 'Banc'
--                     • 'Banc' → 'Banc'
--                     • 'banc public' → 'Banc'
--                     • 'Lampadaire' sans matériaux (LED, sodium) → NULL
--                     • 'le lampadaire' → 'Lampadaire'
--                     • 'le Lampadaire' → 'Lampadaire'    
--                     • 'lampadaire' → 'Lampadaire'    
--                     • 'led' → 'LED'    
--                     • 'fontaine publique' → 'Fontaine'    
--                     • 'le fontaine publique' → 'Fontaine'    
--                     • 'fontaine' → 'Fontaine'    
--                     • 'le Fontaine' → 'Fontaine'    
--                     • 'poubelle' → 'Poubelle'    
--                     • 'le Poubelle' → 'Poubelle'    
--                     • 'le poubelle tri' → 'Poubelle tri'    
--                     • 'panneau' → 'Panneau'    
--                     • 'le Panneau' → 'Panneau'    
--                     • 'le panneau' → 'Panneau'    
--                     • 'borne' → 'Borne recharge EV'    
--                     • 'borne EV' → 'Borne recharge EV'    
--                     • 'Borne recharge' → 'Borne recharge EV'    
--                     • 'le borne recharge EV' → 'Borne recharge EV'    
--                     • 'le corbeille' → 'Corbeille'    
--                     • Vide '' → NULL
--
--  [description]      • Pas de normalisation, car cas de figures techniquement infinis.
--
--  [urgence]          • Vide '' → NULL
--
--  [statut]           • Vide '' → NULL
--
-- PIPELINE :
--   ÉTAPE 1  — Création de la table de staging (données brutes)
--   ÉTAPE 2  — Import CSV via COPY
--   ÉTAPE 3  — Nettoyage et standardisation (UPDATE in-place)
--              3a  TRIM global
--              3b  Dédoublonnage sur id
--              3c  Standardisation id          (séparateur '_' → '-')
--              3d  Standardisation date
--              3e  Standardisation signale_par
--              3f  Standardisation objet
--              3g  Standardisation description
--              3h  Standardisation urgence
--              3i  Standardisation statut
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

DROP TABLE IF EXISTS stg_signalements CASCADE;

CREATE TABLE stg_signalements (
    stg_id             SERIAL PRIMARY KEY,
    date               TEXT,
    signale_par        TEXT,
    objet              TEXT,
    description        TEXT,
    urgence            TEXT,
    statut             TEXT
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

COPY stg_signalements (date, signale_par, objet, description, urgence, statut)
FROM '/docker-data/signalements.csv'
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

UPDATE stg_signalements
SET
    date              = TRIM(date),
    signale_par       = TRIM(signale_par),
    objet             = TRIM(objet),
    description       = TRIM(description),
    urgence           = TRIM(urgence),
    statut            = TRIM(statut)
    ;
    
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
 
UPDATE stg_signalements
SET signale_par =
    CASE LOWER(TRIM(signale_par))
        WHEN 'M. Keller'        THEN 'Mme Keller'
        WHEN 'M. Pereira' THEN 'Mme Pereira'

        WHEN 'un passant'          THEN 'Passant'
        WHEN 'un habitant' THEN 'Habitant'
        WHEN 'habitant du quartier' THEN 'Habitant quartier'

        ELSE COALESCE(INITCAP(TRIM(signale_par)), NULL)
    END
WHERE signale_par IS NOT NULL;

UPDATE stg_signalements
SET objet =
    CASE LOWER(TRIM(objet))
        WHEN 'banc' THEN 'Banc'
        WHEN 'banc public' THEN 'Banc'
        WHEN 'le banc' THEN 'Banc'
        WHEN 'le Banc' THEN 'Banc'
        WHEN 'lampadaire' THEN 'Lampadaire'
        WHEN 'le lampadaire' THEN 'Lampadaire'
        WHEN 'le Lampadaire' THEN 'Lampadaire'
        WHEN 'lampadaire led' THEN 'Lampadaire LED'
        WHEN 'lampadaire sodium' THEN 'Lampadaire sodium'
        WHEN 'led' THEN 'LED'
        WHEN 'fontaine publique' THEN 'Fontaine'
        WHEN 'le fontaine publique' THEN 'Fontaine'
        WHEN 'fontaine' THEN 'Fontaine'
        WHEN 'le fontaine' THEN 'Fontaine'
        WHEN 'le Fontaine' THEN 'Fontaine'
        WHEN 'poubelle' THEN 'Poubelle'
        WHEN 'le Poubelle' THEN 'Poubelle'
        WHEN 'le poubelle tri' THEN 'Poubelle tri'
        WHEN 'corbeille' THEN 'Poubelle'
        WHEN 'le corbeille' THEN 'Poubelle'
        WHEN 'poubelle tri' THEN 'Poubelle'
        WHEN 'panneau' THEN 'Panneau affichage'
        WHEN 'le Panneau' THEN 'Panneau affichage'
        WHEN 'le panneau' THEN 'Panneau affichage'
        WHEN 'panneau affichage' THEN 'Panneau affichage'
        WHEN 'panneau info' THEN 'Panneau info'
        WHEN 'borne'          THEN 'Borne recharge EV'
        WHEN 'borne ev'          THEN 'Borne recharge EV'
        WHEN 'borne recharge'    THEN 'Borne recharge EV'
        WHEN 'Borne recharge'    THEN 'Borne recharge EV'
        WHEN 'borne recharge ev' THEN 'Borne recharge EV'
        WHEN 'le borne recharge ev' THEN 'Borne recharge EV'

        ELSE COALESCE(INITCAP(TRIM(objet)), NULL)
    END
WHERE objet IS NOT NULL;
 
-- on garde que les données des banc
DELETE FROM stg_signalements WHERE objet != 'Banc';