-- Active: 1772721397266@@127.0.0.1@5432@infradon
-- ÉTAPE 1 : CRÉATION DES RÔLES

-- Rôle CITOYEN : Lecture seule sur les données publiques
CREATE ROLE role_citoyen;

-- Rôle TECHNICIEN : Lecture + Écriture sur les données opérationnelles
CREATE ROLE role_technicien;

-- Rôle ADMINISTRATEUR : Tous les privilèges
CREATE ROLE role_administrateur;



-- ÉTAPE 2 : ATTRIBUTION DES PRIVILÈGES PAR RÔLE

-- RÔLE CITOYEN
-- Les citoyens peuvent consulter :
-- - L'inventaire du mobilier (bancs publics)
-- - Les signalements (pour voir si leur signalement a été traité)

-- Connexion à la base de données
GRANT CONNECT ON DATABASE infradon TO role_citoyen;

-- Lecture sur l'inventaire du mobilier
GRANT SELECT ON mobiliers TO role_citoyen;

-- Lecture sur les signalements (consultation uniquement)
GRANT SELECT ON signalements TO role_citoyen;


-- Accès en lecture aux tables de référence
GRANT SELECT ON type_mobiliers TO role_citoyen;
GRANT SELECT ON type_lieux TO role_citoyen;
GRANT SELECT ON type_materiaux TO role_citoyen;
GRANT SELECT ON type_etats TO role_citoyen;
GRANT SELECT ON urgences TO role_citoyen;
GRANT SELECT ON statut TO role_citoyen;


-- RÔLE TECHNICIEN
-- Les techniciens peuvent :
-- - Lire toutes les données
-- - Ajouter/modifier les interventions et signalements
-- - Mettre à jour l'état du mobilier
-- - Consulter toutes les vues

-- Connexion à la base
GRANT CONNECT ON DATABASE infradon TO role_technicien;

-- Lecture complète sur toutes les tables
GRANT SELECT ON ALL TABLES IN SCHEMA public TO role_technicien;

-- Écriture sur les interventions (ajout de nouvelles interventions)
GRANT SELECT, INSERT, UPDATE ON interventions TO role_technicien;

-- Écriture sur les signalements (mise à jour du statut, ajout de remarques)
GRANT SELECT, INSERT, UPDATE ON signalements TO role_technicien;

-- Mise à jour de l'état du mobilier (après intervention)
GRANT SELECT, UPDATE ON mobiliers TO role_technicien;

-- Lecture/écriture sur les tables de référence (pour ajouter de nouveaux types si nécessaire)
GRANT SELECT, INSERT ON type_interventions TO role_technicien;
GRANT SELECT, INSERT ON techniciens TO role_technicien;

-- Accès aux séquences pour l'insertion de nouvelles lignes
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO role_technicien;


-- RÔLE ADMINISTRATEUR
-- Les administrateurs ont tous les privilèges :
-- - Gestion complète de la structure de la base
-- - CRUD complet sur toutes les tables
-- - Gestion des sauvegardes et restaurations

-- Connexion à la base
GRANT CONNECT ON DATABASE infradon TO role_administrateur;

-- Tous les privilèges sur toutes les tables
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO role_administrateur;

-- Tous les privilèges sur les séquences
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO role_administrateur;

-- Privilèges de création/suppression d'objets
GRANT CREATE ON SCHEMA public TO role_administrateur;

-- Privilèges sur la base de données complète
GRANT ALL PRIVILEGES ON DATABASE infradon TO role_administrateur;


-- ÉTAPE 3 : CRÉATION DES UTILISATEURS EXEMPLES

-- CITOYENS
-- Création d'utilisateurs citoyens types
CREATE USER citoyen_weber WITH PASSWORD 'weber2026!';
CREATE USER citoyen_rochat WITH PASSWORD 'rochat2026!';
CREATE USER consultation_publique WITH PASSWORD 'public2026!' VALID UNTIL '2027-12-31';

-- Attribution du rôle citoyen
GRANT role_citoyen TO citoyen_weber;
GRANT role_citoyen TO citoyen_rochat;
GRANT role_citoyen TO consultation_publique;


-- TECHNICIENS
-- Création d'utilisateurs techniciens (basés sur les noms dans le fichier interventions.csv)
CREATE USER tech_pedro WITH PASSWORD 'pedro_tech2026!';
CREATE USER tech_jeanmarc WITH PASSWORD 'jm_tech2026!';
CREATE USER tech_koffi WITH PASSWORD 'koffi_tech2026!';

-- Attribution du rôle technicien
GRANT role_technicien TO tech_pedro;
GRANT role_technicien TO tech_jeanmarc;
GRANT role_technicien TO tech_koffi;


-- ADMINISTRATEURS
-- Création d'utilisateurs administrateurs
CREATE USER admin_service_technique 
    WITH PASSWORD 'admin_st_2026!' 
    CREATEDB 
    CREATEROLE;

CREATE USER admin_backup 
    WITH PASSWORD 'backup_2026!' 
    VALID UNTIL '2027-12-31';

-- Attribution du rôle administrateur
GRANT role_administrateur TO admin_service_technique;
GRANT role_administrateur TO admin_backup;


-- ÉTAPE 4 : PRIVILÈGES SPÉCIFIQUES ADDITIONNELS

-- Permettre aux techniciens de voir les autres techniciens (pour coordination)
GRANT SELECT ON techniciens TO role_technicien;

-- Permettre aux citoyens de créer des signalements (mais pas de les modifier)
GRANT INSERT ON signalements TO role_citoyen;

-- Permettre aux administrateurs de gérer les fournisseurs
-- (important pour le contexte : le fournisseur principal a fermé)
GRANT ALL PRIVILEGES ON fournisseurs TO role_administrateur;
