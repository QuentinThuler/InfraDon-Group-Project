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
