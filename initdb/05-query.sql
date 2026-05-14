
-- LIVRABLE 1 : ÉTAT DU PARC ACTUEL (v_parc_bancs)

-- Objectif : Vue de synthèse présentant l'état global du parc de bancs
-- Cette vue agrège les données pour donner une vision claire et structurée

CREATE OR REPLACE VIEW v_parc_bancs AS
WITH statistiques_generales AS (
    -- ÉTAPE 1 : Calculer les statistiques générales
    -- On compte le nombre total de bancs et ceux sans coordonnées GPS
    SELECT 
        COUNT(*) AS nombre_total_bancs,
        COUNT(CASE WHEN latitude IS NULL OR longitude IS NULL THEN 1 END) AS bancs_sans_gps
    FROM mobiliers m
    WHERE m.id_type_mobilier = 1  -- 1 = Banc
),
statistiques_materiaux AS (
    -- ÉTAPE 2 : Statistiques par matériau (bois vs métal)
    SELECT 
        tm.nom AS materiau,
        COUNT(m.id) AS nombre_bancs,
        -- Calcul de l'âge moyen en années
        ROUND(AVG(
            EXTRACT(YEAR FROM AGE(CURRENT_DATE, m.date_installation))
        ), 1) AS age_moyen_annees
    FROM mobiliers m
    INNER JOIN type_materiaux tm ON m.id_type_materiaux = tm.id
    WHERE m.id_type_mobilier = 1  -- Seulement les bancs
        AND m.date_installation IS NOT NULL
    GROUP BY tm.nom
),
statistiques_etats AS (
    -- ÉTAPE 3 : Statistiques par état (bon, usé, à remplacer)
    SELECT 
        te.nom AS etat,
        COUNT(m.id) AS nombre_bancs
    FROM mobiliers m
    INNER JOIN type_etats te ON m.id_type_etat = te.id
    WHERE m.id_type_mobilier = 1  -- Seulement les bancs
    GROUP BY te.nom
)
-- ASSEMBLAGE FINAL : On empile tous les résultats avec UNION ALL
SELECT 
    'SYNTHÈSE GÉNÉRALE' AS categorie,
    'Nombre total de bancs' AS indicateur,
    sg.nombre_total_bancs::TEXT AS valeur,
    NULL AS materiau,
    NULL AS etat
FROM statistiques_generales sg

UNION ALL

SELECT 
    'SYNTHÈSE GÉNÉRALE',
    'Bancs sans coordonnées GPS',
    sg.bancs_sans_gps::TEXT,
    NULL,
    NULL
FROM statistiques_generales sg

UNION ALL

SELECT 
    'RÉPARTITION PAR MATÉRIAU',
    'Nombre de bancs',
    sm.nombre_bancs::TEXT,
    sm.materiau,
    NULL
FROM statistiques_materiaux sm

UNION ALL

SELECT 
    'RÉPARTITION PAR MATÉRIAU',
    'Âge moyen (années)',
    sm.age_moyen_annees::TEXT,
    sm.materiau,
    NULL
FROM statistiques_materiaux sm

UNION ALL

SELECT 
    'RÉPARTITION PAR ÉTAT',
    'Nombre de bancs',
    se.nombre_bancs::TEXT,
    NULL,
    se.etat
FROM statistiques_etats se;

-- LIVRABLE 2 : BANCS À REMPLACER DANS LES 2 ANS (v_bancs_a_remplacer)

-- Objectif : Identifier les bancs qui doivent être remplacés selon 2 critères :
-- 1. État = "usé" (id=1) ou "à remplacer" (id=3)
-- 2. OU plus de 3 interventions enregistrées

CREATE OR REPLACE VIEW v_bancs_a_remplacer AS
WITH comptage_interventions AS (
    -- ÉTAPE 1 : Compter le nombre d'interventions par banc
    -- On fait une jointure entre mobiliers et interventions
    -- COUNT(*) compte toutes les interventions pour chaque banc
    SELECT 
        m.id AS id_mobilier,
        COUNT(i.id) AS nombre_interventions
    FROM mobiliers m
    LEFT JOIN interventions i ON m.id = i.id_mobilier
    WHERE m.id_type_mobilier = 1  -- Seulement les bancs
    GROUP BY m.id
)
-- SÉLECTION FINALE : Tous les bancs qui remplissent les critères
SELECT 
    m.id,
    tl.nom AS lieu,
    tm.nom AS materiau,
    -- Calcul de l'âge en années
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, m.date_installation))::INTEGER AS age_annees,
    -- Nombre d'interventions (0 si aucune)
    COALESCE(ci.nombre_interventions, 0) AS nombre_interventions,
    te.nom AS etat,
    m.latitude,
    m.longitude,
    m.remarque,
    -- Colonne calculée : pourquoi ce banc doit être remplacé ?
    CASE 
        -- Cas le plus critique : état à remplacer + nombreuses interventions
        WHEN te.id = 3 AND COALESCE(ci.nombre_interventions, 0) > 3 
            THEN 'État critique + nombreuses interventions'
        -- État critique seul
        WHEN te.id = 3 
            THEN 'État critique (à remplacer)'
        -- État usé avec nombreuses interventions
        WHEN te.id = 1 AND COALESCE(ci.nombre_interventions, 0) > 3 
            THEN 'État usé + nombreuses interventions'
        -- État usé seul
        WHEN te.id = 1 
            THEN 'État usé'
        -- Nombreuses interventions seul
        WHEN COALESCE(ci.nombre_interventions, 0) > 3 
            THEN 'Trop d''interventions (>3)'
        ELSE 'Autre'
    END AS raison_remplacement
FROM mobiliers m
-- Jointures pour récupérer les noms (au lieu des IDs)
INNER JOIN type_lieux tl ON m.id_type_lieu = tl.id
INNER JOIN type_materiaux tm ON m.id_type_materiaux = tm.id
INNER JOIN type_etats te ON m.id_type_etat = te.id
-- LEFT JOIN pour garder les bancs même sans interventions
LEFT JOIN comptage_interventions ci ON m.id = ci.id_mobilier
WHERE m.id_type_mobilier = 1  -- Seulement les bancs
    AND (
        -- CRITÈRE 1 : État usé (id=1) ou à remplacer (id=3)
        te.id IN (1, 3)
        -- OU
        -- CRITÈRE 2 : Plus de 3 interventions
        OR COALESCE(ci.nombre_interventions, 0) > 3
    )
-- Tri par priorité : les plus critiques en premier
ORDER BY 
    CASE 
        WHEN te.id = 3 THEN 1  -- "à remplacer" en premier
        WHEN te.id = 1 THEN 2  -- "usé" en deuxième
        ELSE 3
    END,
    ci.nombre_interventions DESC NULLS LAST,
    age_annees DESC;

-- LIVRABLE 3 : ESTIMATION BUDGÉTAIRE (v_budget_bancs)

-- Objectif : Calculer le budget nécessaire pour remplacer tous les bancs
-- identifiés dans la vue précédente


-- LIVRABLE 1 : ÉTAT DU PARC ACTUEL (v_parc_bancs)

-- Objectif : Vue de synthèse présentant l'état global du parc de bancs
-- Cette vue agrège les données pour donner une vision claire et structurée

CREATE OR REPLACE VIEW v_budget_bancs AS
WITH bancs_a_remplacer AS (
    -- ÉTAPE 1 : Réutiliser la vue précédente
    SELECT * FROM v_bancs_a_remplacer
),
cout_moyen_remplacement AS (
    -- ÉTAPE 2 : Calculer le coût moyen d'un remplacement
    SELECT AVG(i.cout)::NUMERIC AS cout_moyen
    FROM interventions i
    WHERE i.id_type_intervention = 4 -- 4 = Remplacement Latte
        AND i.cout IS NOT NULL
        AND i.cout > 0 -- Exclure les interventions gratuites (garantie)
),
statistiques_par_materiau AS (
    -- ÉTAPE 3 : Calculer le budget par matériau (bois vs métal)
    SELECT 
        bar.materiau,
        COUNT(*) AS nombre_bancs,
        cmr.cout_moyen,
        -- Budget = nombre de bancs × coût moyen
        COUNT(*) * cmr.cout_moyen AS budget_estime
    FROM bancs_a_remplacer bar
    CROSS JOIN cout_moyen_remplacement cmr
    GROUP BY bar.materiau, cmr.cout_moyen
),
totaux AS (
    -- ÉTAPE 4 : Calculer les totaux globaux
    SELECT 
        SUM(nombre_bancs) AS total_bancs,
        MAX(cout_moyen) AS cout_moyen_global,
        SUM(budget_estime) AS budget_total
    FROM statistiques_par_materiau
),
resultats_bruts AS (
    -- UNION ALL dans une CTE intermédiaire
    SELECT 
        'SYNTHÈSE BUDGÉTAIRE' AS categorie,
        'Nombre total de bancs à remplacer' AS indicateur,
        t.total_bancs::TEXT AS valeur,
        NULL::TEXT AS materiau,
        NULL::NUMERIC AS montant_chf
    FROM totaux t
 
    UNION ALL
 
    SELECT 
        'SYNTHÈSE BUDGÉTAIRE',
        'Coût moyen d''un remplacement (CHF)',
        ROUND(t.cout_moyen_global, 2)::TEXT,
        NULL::TEXT,
        ROUND(t.cout_moyen_global, 2)
    FROM totaux t
 
    UNION ALL
 
    SELECT 
        'SYNTHÈSE BUDGÉTAIRE',
        'Budget total estimé (CHF)',
        ROUND(t.budget_total, 2)::TEXT,
        NULL::TEXT,
        ROUND(t.budget_total, 2)
    FROM totaux t
 
    UNION ALL
 
    SELECT 
        'RÉPARTITION PAR MATÉRIAU',
        'Nombre de bancs à remplacer',
        spm.nombre_bancs::TEXT,
        spm.materiau,
        NULL
    FROM statistiques_par_materiau spm
 
    UNION ALL
 
    SELECT 
        'RÉPARTITION PAR MATÉRIAU',
        'Budget estimé (CHF)',
        ROUND(spm.budget_estime, 2)::TEXT,
        spm.materiau,
        ROUND(spm.budget_estime, 2)
    FROM statistiques_par_materiau spm
 
    UNION ALL
 
    SELECT 
        'RÉPARTITION PAR MATÉRIAU',
        'Pourcentage du budget total',
        ROUND((spm.budget_estime / (SELECT budget_total FROM totaux)) * 100, 1)::TEXT || '%',
        spm.materiau,
        NULL
    FROM statistiques_par_materiau spm
)
-- SELECT final avec ORDER BY (fonctionne car on trie sur une CTE, pas sur UNION)
SELECT 
    categorie,
    indicateur,
    valeur,
    materiau,
    montant_chf
FROM resultats_bruts
ORDER BY 
    CASE categorie
        WHEN 'SYNTHÈSE BUDGÉTAIRE' THEN 1
        WHEN 'RÉPARTITION PAR MATÉRIAU' THEN 2
    END,
    materiau NULLS FIRST,
    indicateur;


-- RECOMMANDATION POUR LE SERVICE TECHNIQUE

/*
RECOMMANDATION : Privilégier le MÉTAL pour les futurs remplacements

1. DURABILITÉ SUPÉRIEURE
   - Le bois nécessite plus de remplacements à proportion égale
   - Les bancs en métal vieillissent mieux

2. COÛT DE MAINTENANCE RÉDUIT
   - Moins d'interventions nécessaires sur le métal
   - Résistance supérieure aux intempéries
*/