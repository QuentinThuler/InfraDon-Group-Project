-- Active: 1772721397266@@127.0.0.1@5432@infradon


-- ___________________________________ Inventaire insert ____________________________________

SELECT * from stg_inventaire;

-- insert lieu into table type-lieux from stg_inventaire
INSERT INTO type_lieux (nom)
SELECT DISTINCT lieu 
FROM stg_inventaire 
WHERE lieu IS NOT NULL;

-- insert materiau into table type_materiaux from stg_inventaire
INSERT INTO type_materiaux (nom)
SELECT DISTINCT materiau 
FROM stg_inventaire 
WHERE materiau IS NOT NULL;

-- insert mobilier into table type-mobiliers from stg_inventaire
INSERT INTO type_mobiliers (nom)
SELECT DISTINCT type 
FROM stg_inventaire
WHERE type IS NOT NULL;

-- insert etat into table type-etat from stg_inventaire
INSERT INTO type_etats (nom)
SELECT DISTINCT etat 
FROM stg_inventaire
WHERE etat IS NOT NULL;

INSERT INTO mobiliers (
    latitude,
    longitude,
    date_installation,
    remarque,
    id_type_mobilier,
    id_type_lieu,
    id_type_materiaux,
    id_type_etat
)
SELECT
    REPLACE(s.latitude, ',', '.')::FLOAT,
    REPLACE(s.longitude, ',', '.')::FLOAT,
    s.date_installation::DATE,
    s.remarques,
    tm.id,
    tl.id,
    tmat.id,
    te.id
FROM stg_inventaire s
-- Résolution FK type mobilier
JOIN type_mobiliers tm   ON LOWER(TRIM(tm.nom)) = LOWER(TRIM(s.type))
-- Résolution FK lieu
JOIN type_lieux tl       ON LOWER(TRIM(tl.nom)) = LOWER(TRIM(s.lieu))
-- Résolution FK matériaux
JOIN type_materiaux tmat ON LOWER(TRIM(tmat.nom)) = LOWER(TRIM(s.materiau))
-- Résolution FK état
JOIN type_etats te       ON LOWER(TRIM(te.nom)) = LOWER(TRIM(s.etat));

-- ___________________________________ Intervention insert ____________________________________

SELECT * from stg_intervention;

-- insert data into table techniciens from stg_intervention
INSERT INTO techniciens (nom, prenom)
SELECT DISTINCT SPLIT_PART(technicien, ' ', 1) AS nom, SPLIT_PART(technicien, ' ', 2) AS prenom
FROM stg_intervention;

-- insert data into table type_interventions from stg_intervention
INSERT INTO type_interventions (nom)
SELECT DISTINCT type_intervention 
FROM stg_intervention;

-- intervention from stg_intervention
INSERT INTO interventions (
    date,
    duree,
    cout,
    remarque,
    id_technicien,
    id_mobilier,
    id_type_intervention
)
SELECT
    sp.date::DATE,
    REPLACE(sp.duree, ',', '.')::FLOAT8,
    sp.cout_materiel::NUMERIC,
    sp.remarques,
    t.id,
    m.id,
    ti.id
FROM stg_intervention_parsed sp
-- Résolution FK technicien
JOIN techniciens t ON LOWER(TRIM(t.nom)) = LOWER(SPLIT_PART(sp.technicien, ' ', 1))
-- Résolution FK type_intervention
JOIN type_interventions ti ON LOWER(TRIM(ti.nom)) = LOWER(TRIM(sp.type_intervention))
JOIN type_mobiliers tm ON LOWER(TRIM(tm.nom)) = LOWER(TRIM(sp.type_mobilier_clean))
JOIN type_lieux tl ON LOWER(TRIM(tl.nom)) = LOWER(TRIM(sp.type_lieu_clean))
JOIN mobiliers m ON m.id_type_mobilier = tm.id AND m.id_type_lieu = tl.id;

-- ___________________________________ Signalement insert ____________________________________


-- insert urgence into table type-urgence from stg_signalements
INSERT INTO urgences (nom)
SELECT DISTINCT urgence 
FROM stg_signalements 
WHERE urgence IS NOT NULL;

-- insert statut into table type-statut from stg_signalements
INSERT INTO statut (nom)
SELECT DISTINCT statut 
FROM stg_signalements 
WHERE statut IS NOT NULL;

-- insert signalements into table signalements from stg_signalements
SET datestyle = 'DMY';
-- Insertion avec les données nettoyées
INSERT INTO signalements (
    date,
    description,
    signal_par,
    id_mobilier,
    id_urgence,
    id_statut
)
SELECT
    sp.date::DATE,
    sp.description,
    sp.signale_par,
    m.id,
    u.id,
    st.id
FROM stg_signalements_parsed sp
JOIN urgences u ON LOWER(TRIM(u.nom)) = LOWER(TRIM(sp.urgence))
JOIN statut st ON LOWER(TRIM(st.nom)) = LOWER(TRIM(sp.statut))
JOIN type_mobiliers tm ON LOWER(TRIM(tm.nom)) = LOWER(TRIM(sp.type_mobilier_clean))
JOIN type_lieux tl ON LOWER(TRIM(tl.nom)) = LOWER(TRIM(sp.type_lieu_clean))
JOIN mobiliers m ON m.id_type_mobilier = tm.id AND m.id_type_lieu = tl.id;