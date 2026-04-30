SELECT * from stg_intervention;

-- insert data into table techniciens from stg_intervention
INSERT INTO techniciens (nom, prenom, description)
SELECT DISTINCT SPLIT_PART(technicien, ' ', 1) AS nom, SPLIT_PART(technicien, ' ', 2) AS prenom, '' AS description
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
    s.date::DATE,
    REPLACE(s.duree, ',', '.')::FLOAT8,
    s.cout_materiel::NUMERIC,
    s.remarques,
    t.id,
    m.id,
    ti.id
FROM stg_intervention s
-- Résolution FK technicien
JOIN techniciens t ON LOWER(TRIM(t.nom)) = LOWER(SPLIT_PART(s.technicien, ' ', 1))
-- Résolution FK type_intervention
JOIN type_interventions ti ON LOWER(TRIM(ti.nom)) = LOWER(TRIM(s.type_intervention))
JOIN mobiliers m ON LOWER(TRIM(ti.nom)) = LOWER(TRIM(s.type_intervention));

-- TO DO Résolution FK mobilier join mobilier on ? -> type_mobilier (banc), -> type_Lieux (route de lausanne)


