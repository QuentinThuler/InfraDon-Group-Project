-- ===========================================
-- 02-data.sql
-- Données géographiques réelles
-- Canton de Vaud - Communes et Rivières
-- Coordonnées en WGS84 (SRID 4326)
-- ===========================================

-- ===========================================
-- COMMUNES VAUDOISES (points - coordonnées réelles)
-- Source: Coordonnées officielles des centres communaux
-- ===========================================
INSERT INTO communes (nom, district, population, superficie_km2, geom) VALUES
-- District de Lausanne
('Lausanne', 'Lausanne', 140202, 41.37, ST_SetSRID(ST_MakePoint(6.6328, 46.5196), 4326)),
('Pully', 'Lausanne', 18583, 5.76, ST_SetSRID(ST_MakePoint(6.6619, 46.5097), 4326)),
('Prilly', 'Lausanne', 12441, 2.36, ST_SetSRID(ST_MakePoint(6.6011, 46.5333), 4326)),
('Renens', 'Lausanne', 21478, 2.96, ST_SetSRID(ST_MakePoint(6.5883, 46.5350), 4326)),
('Epalinges', 'Lausanne', 10132, 6.27, ST_SetSRID(ST_MakePoint(6.6681, 46.5483), 4326)),

-- District de l'Ouest lausannois
('Ecublens', 'Ouest lausannois', 13789, 5.33, ST_SetSRID(ST_MakePoint(6.5611, 46.5278), 4326)),
('Bussigny', 'Ouest lausannois', 9452, 5.86, ST_SetSRID(ST_MakePoint(6.5536, 46.5511), 4326)),
('Crissier', 'Ouest lausannois', 8274, 3.82, ST_SetSRID(ST_MakePoint(6.5778, 46.5456), 4326)),

-- District de Morges
('Morges', 'Morges', 16520, 3.84, ST_SetSRID(ST_MakePoint(6.4983, 46.5111), 4326)),
('Aubonne', 'Morges', 3618, 9.69, ST_SetSRID(ST_MakePoint(6.3917, 46.4958), 4326)),
('Saint-Prex', 'Morges', 6087, 5.32, ST_SetSRID(ST_MakePoint(6.4550, 46.4817), 4326)),

-- District de Nyon
('Nyon', 'Nyon', 21039, 6.79, ST_SetSRID(ST_MakePoint(6.2389, 46.3831), 4326)),
('Gland', 'Nyon', 14133, 9.45, ST_SetSRID(ST_MakePoint(6.2708, 46.4231), 4326)),
('Rolle', 'Nyon', 6729, 5.91, ST_SetSRID(ST_MakePoint(6.3372, 46.4600), 4326)),
('Coppet', 'Nyon', 3361, 2.52, ST_SetSRID(ST_MakePoint(6.1919, 46.3147), 4326)),

-- District de Lavaux-Oron
('Puidoux', 'Lavaux-Oron', 3180, 17.78, ST_SetSRID(ST_MakePoint(6.7736, 46.4972), 4326)),
('Lutry', 'Lavaux-Oron', 10161, 8.65, ST_SetSRID(ST_MakePoint(6.6878, 46.5033), 4326)),
('Bourg-en-Lavaux', 'Lavaux-Oron', 5574, 13.44, ST_SetSRID(ST_MakePoint(6.7350, 46.4958), 4326)),

-- District de la Riviera-Pays-d'Enhaut
('Vevey', 'Riviera-Pays-d''Enhaut', 19891, 2.38, ST_SetSRID(ST_MakePoint(6.8433, 46.4628), 4326)),
('Montreux', 'Riviera-Pays-d''Enhaut', 26433, 33.37, ST_SetSRID(ST_MakePoint(6.9106, 46.4333), 4326)),
('La Tour-de-Peilz', 'Riviera-Pays-d''Enhaut', 11949, 2.55, ST_SetSRID(ST_MakePoint(6.8600, 46.4528), 4326)),
('Château-d''Oex', 'Riviera-Pays-d''Enhaut', 3440, 113.56, ST_SetSRID(ST_MakePoint(7.1358, 46.4747), 4326)),

-- District du Jura-Nord vaudois
('Yverdon-les-Bains', 'Jura-Nord vaudois', 30157, 11.28, ST_SetSRID(ST_MakePoint(6.6411, 46.7783), 4326)),
('Orbe', 'Jura-Nord vaudois', 7150, 15.55, ST_SetSRID(ST_MakePoint(6.5306, 46.7247), 4326)),
('Vallorbe', 'Jura-Nord vaudois', 3686, 24.03, ST_SetSRID(ST_MakePoint(6.3750, 46.7128), 4326)),
('Sainte-Croix', 'Jura-Nord vaudois', 4831, 34.41, ST_SetSRID(ST_MakePoint(6.5028, 46.8219), 4326)),
('L''Isle', 'Jura-Nord vaudois', 1289, 10.72, ST_SetSRID(ST_MakePoint(6.4114, 46.6142), 4326)),

-- District du Gros-de-Vaud
('Echallens', 'Gros-de-Vaud', 6236, 5.17, ST_SetSRID(ST_MakePoint(6.6333, 46.6417), 4326)),
('Assens', 'Gros-de-Vaud', 1582, 4.55, ST_SetSRID(ST_MakePoint(6.6500, 46.6167), 4326)),
('Bottens', 'Gros-de-Vaud', 1411, 6.46, ST_SetSRID(ST_MakePoint(6.6631, 46.6056), 4326)),

-- District de la Broye-Vully
('Payerne', 'Broye-Vully', 10359, 24.16, ST_SetSRID(ST_MakePoint(6.9378, 46.8206), 4326)),
('Moudon', 'Broye-Vully', 6266, 11.35, ST_SetSRID(ST_MakePoint(6.7972, 46.6692), 4326)),
('Avenches', 'Broye-Vully', 4518, 10.79, ST_SetSRID(ST_MakePoint(7.0417, 46.8806), 4326)),
('Lucens', 'Broye-Vully', 3725, 10.19, ST_SetSRID(ST_MakePoint(6.8417, 46.7094), 4326)),

-- District d'Aigle
('Aigle', 'Aigle', 10598, 16.44, ST_SetSRID(ST_MakePoint(6.9678, 46.3178), 4326)),
('Bex', 'Aigle', 7643, 99.08, ST_SetSRID(ST_MakePoint(7.0100, 46.2517), 4326)),
('Villeneuve', 'Aigle', 6012, 7.08, ST_SetSRID(ST_MakePoint(6.9306, 46.4000), 4326)),
('Leysin', 'Aigle', 4218, 28.34, ST_SetSRID(ST_MakePoint(7.0117, 46.3433), 4326)),
('Ollon', 'Aigle', 7605, 63.48, ST_SetSRID(ST_MakePoint(6.9989, 46.2961), 4326));


-- ===========================================
-- RIVIERES VAUDOISES (lignes - tracés simplifiés réels)
-- Source: Tracés approximatifs basés sur données géographiques
-- ===========================================
INSERT INTO rivieres (nom, longueur_km, geom) VALUES
-- La Venoge (source L'Isle -> embouchure St-Sulpice)
('Venoge', 38.0, ST_SetSRID(ST_MakeLine(ARRAY[
    ST_MakePoint(6.4114, 46.6142),  -- L'Isle (source)
    ST_MakePoint(6.4500, 46.5900),  -- Vers Cossonay
    ST_MakePoint(6.4800, 46.5600),  -- Penthalaz
    ST_MakePoint(6.5200, 46.5400),  -- Bussigny
    ST_MakePoint(6.5500, 46.5200),  -- St-Sulpice (embouchure)
    ST_MakePoint(6.5600, 46.5100)   -- Lac Léman
]), 4326)),

-- La Broye (traverse le canton d'est en ouest)
('Broye', 79.0, ST_SetSRID(ST_MakeLine(ARRAY[
    ST_MakePoint(6.9378, 46.8206),  -- Payerne
    ST_MakePoint(6.8800, 46.7800),  -- Vers Moudon
    ST_MakePoint(6.7972, 46.6692),  -- Moudon
    ST_MakePoint(6.8417, 46.7094)   -- Lucens
]), 4326)),

-- L'Orbe (Vallorbe -> Orbe -> lac de Neuchâtel)
('Orbe', 57.0, ST_SetSRID(ST_MakeLine(ARRAY[
    ST_MakePoint(6.3750, 46.7128),  -- Vallorbe (grottes)
    ST_MakePoint(6.4200, 46.7200),  -- Vers Les Clées
    ST_MakePoint(6.4800, 46.7200),  -- Vers Chavornay
    ST_MakePoint(6.5306, 46.7247),  -- Orbe
    ST_MakePoint(6.5800, 46.7500),  -- Vers Yverdon
    ST_MakePoint(6.6411, 46.7783)   -- Yverdon (lac)
]), 4326)),

-- L'Aubonne (Jura -> lac Léman)
('Aubonne', 20.0, ST_SetSRID(ST_MakeLine(ARRAY[
    ST_MakePoint(6.3600, 46.5400),  -- Source (Jura)
    ST_MakePoint(6.3800, 46.5200),  -- Vers Aubonne
    ST_MakePoint(6.3917, 46.4958),  -- Aubonne
    ST_MakePoint(6.3900, 46.4600)   -- Embouchure
]), 4326)),

-- La Promenthouse (Arzier -> lac Léman)
('Promenthouse', 17.0, ST_SetSRID(ST_MakeLine(ARRAY[
    ST_MakePoint(6.2300, 46.4800),  -- Source
    ST_MakePoint(6.2500, 46.4500),  -- Vers Gland
    ST_MakePoint(6.2708, 46.4231),  -- Gland
    ST_MakePoint(6.2700, 46.4000)   -- Embouchure
]), 4326)),

-- Le Talent (Gros-de-Vaud)
('Talent', 35.0, ST_SetSRID(ST_MakeLine(ARRAY[
    ST_MakePoint(6.6800, 46.5800),  -- Source (Jorat)
    ST_MakePoint(6.6333, 46.6417),  -- Echallens
    ST_MakePoint(6.5800, 46.7000),  -- Vers Chavornay
    ST_MakePoint(6.5306, 46.7247)   -- Confluence Orbe
]), 4326)),

-- La Veveyse (Préalpes -> Vevey)
('Veveyse', 24.0, ST_SetSRID(ST_MakeLine(ARRAY[
    ST_MakePoint(6.9500, 46.5200),  -- Source (Préalpes)
    ST_MakePoint(6.9000, 46.4900),  -- Vers Châtel-St-Denis
    ST_MakePoint(6.8600, 46.4700),  -- Vers Vevey
    ST_MakePoint(6.8433, 46.4628)   -- Vevey (embouchure)
]), 4326)),

-- La Grande Eau (Alpes -> Aigle)
('Grande Eau', 29.0, ST_SetSRID(ST_MakeLine(ARRAY[
    ST_MakePoint(7.1358, 46.4747),  -- Château-d'Oex
    ST_MakePoint(7.0800, 46.4200),  -- Vers Les Diablerets
    ST_MakePoint(7.0117, 46.3433),  -- Leysin
    ST_MakePoint(6.9678, 46.3178)   -- Aigle (embouchure Rhône)
]), 4326)),

-- La Mentue (Gros-de-Vaud)
('Mentue', 26.0, ST_SetSRID(ST_MakeLine(ARRAY[
    ST_MakePoint(6.7200, 46.5900),  -- Source
    ST_MakePoint(6.7500, 46.6500),  -- Vers Moudon
    ST_MakePoint(6.7972, 46.6692)   -- Confluence Broye
]), 4326)),

-- La Morges (rivière de la ville de Morges)
('Morges', 10.0, ST_SetSRID(ST_MakeLine(ARRAY[
    ST_MakePoint(6.4700, 46.5600),  -- Source
    ST_MakePoint(6.4850, 46.5350),  -- Vers Morges
    ST_MakePoint(6.4983, 46.5111)   -- Morges (embouchure)
]), 4326));
