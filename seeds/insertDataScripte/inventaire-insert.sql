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


-- TO DO Insert mobilier
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


SELECT * from mobiliers;
