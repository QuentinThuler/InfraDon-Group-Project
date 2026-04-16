SELECT * from stg_signalements;

-- insert date into table type-date from stg_signalements
INSERT INTO type_date (nom)
SELECT DISTINCT date 
FROM stg_signalements 
WHERE date IS NOT NULL;

-- insert signale_par into table type-signale_par from stg_signalements
INSERT INTO type_signale_par (nom)
SELECT DISTINCT signale_par 
FROM stg_signalements 
WHERE date IS NOT NULL;

-- insert objet into table type-objet from stg_signalements
INSERT INTO type_objet (nom)
SELECT DISTINCT objet 
FROM stg_signalements 
WHERE date IS NOT NULL;

-- insert description into table type-description from stg_signalements
INSERT INTO type_description (nom)
SELECT DISTINCT description 
FROM stg_signalements 
WHERE date IS NOT NULL;

-- insert urgence into table type-urgence from stg_signalements
INSERT INTO type_urgence (nom)
SELECT DISTINCT urgence 
FROM stg_signalements 
WHERE date IS NOT NULL;

-- insert statut into table type-statut from stg_signalements
INSERT INTO type_statut (nom)
SELECT DISTINCT statut 
FROM stg_signalements 
WHERE date IS NOT NULL;