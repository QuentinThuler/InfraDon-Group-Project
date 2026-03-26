-- Active: 1772721397266@@127.0.0.1@5432@infradon
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
 
-- on garde que les données de type objet 'Banc' 
DELETE
FROM stg_signalements
WHERE objet NOT LIKE '%banc%'
   AND objet NOT LIKE '%Banc%';




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