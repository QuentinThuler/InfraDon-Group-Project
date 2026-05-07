SELECT * from stg_intervention;

-- insert data into table techniciens from stg_intervention
INSERT INTO techniciens (nom, prenom)
SELECT DISTINCT SPLIT_PART(technicien, ' ', 1) AS nom, SPLIT_PART(technicien, ' ', 2) AS prenom
FROM stg_intervention;

-- insert data into table type_interventions from stg_intervention
INSERT INTO type_interventions (nom)
SELECT DISTINCT type_intervention 
FROM stg_intervention;

-- TO finish Insert intervention from stg_intervention
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

