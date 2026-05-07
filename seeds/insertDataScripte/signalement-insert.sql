-- Active: 1772721397266@@127.0.0.1@5432@infradon

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
