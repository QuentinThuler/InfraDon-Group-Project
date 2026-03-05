-- *********************************************
-- * SQL PostgreSQL generation                 
-- *--------------------------------------------
-- * DB-MAIN version: 11.0.2              
-- * Generator date: Sep 14 2021              
-- * Generation date: Thu Mar  5 13:45:25 2026 
-- * LUN file: C:\Users\Sam\OneDrive - Education Vaud\Bureau\Etude-heig\Semestre2\infraDonnée\comem-infradon\modélisation\InfraDonnee.lun 
-- * Schema: MLD/1 
-- ********************************************* 


-- Database Section
-- ________________ 

create database MLD;


-- Tables Section
-- _____________ 

create table fournisseurs (
     id serial not null,
     nom_entreprise varchar(100) not null,
     contact varchar(50),
     email varchar(255),
     telephone varchar(25) not null,
     remarque varchar(500),
     constraint ID_fournisseurs primary key (id));

create table interventions (
     id serial not null,
     date date not null,
     duree varchar(10) not null,
     cout float(10),
     remarque varchar(1000),
     id_technicien numeric(1) not null,
     id_mobilier numeric(1) not null,
     id_type_intervention numeric(1) not null,
     constraint ID_interventions primary key (id));

create table mobiliers (
     id serial not null,
     latitude float(10),
     longitude float(10),
     date_installation date not null,
     remarque varchar(1000),
     id_type_mobilier numeric(1) not null,
     id_type_lieu numeric(1) not null,
     id_type_materiaux numeric(1),
     id_type-etat numeric(1),
     constraint ID_mobiliers primary key (id));

create table type_mobilier_fournisseur (
     id_fournisseur numeric(1) not null,
     id_mobilier numeric(1) not null,
     constraint ID_servire primary key (id_mobilier, id_fournisseur));

create table signalements (
     id serial not null,
     date date not null,
     description varchar(1000) not null,
     signal_par varchar(50),
     id_immmobilier numeric(1) not null,
     id_urgence numeric(1),
     id_statut numeric(1),
     constraint ID_signalements primary key (id));

create table statut (
     id serial not null,
     nom varchar(100) not null,
     constraint ID_statut primary key (id));

create table techniciens (
     id serial not null,
     nom varchar(50),
     prenom varchar(50) not null,
     description varchar(50) not null,
     constraint ID_techniciens primary key (id));

create table type_etats (
     id serial not null,
     nom varchar(100) not null,
     constraint ID_type_etats primary key (id));

create table type_interventions (
     id serial not null,
     nom varchar(100) not null,
     constraint ID_type_interventions primary key (id));

create table type_lieux (
     id serial not null,
     nom varchar(100) not null,
     constraint ID_type_lieux primary key (id));

create table type_materiaux (
     id serial not null,
     nom varchar(100) not null,
     constraint ID_type_materiaux primary key (id));

create table type_mobiliers (
     id serial not null,
     nom varchar(100) not null,
     constraint ID_type_mobiliers primary key (id));

create table urgences (
     id serial not null,
     nom varchar(100) not null,
     constraint ID_urgences primary key (id));


-- Constraints Section
-- ___________________ 

alter table interventions add constraint FKRealisee_FK
     foreign key (id_technicien)
     references techniciens;

alter table interventions add constraint FKRecevoir_FK
     foreign key (id_mobilier)
     references mobiliers;

alter table interventions add constraint FKConcerne_FK
     foreign key (id_type_intervention)
     references type_interventions;

alter table mobiliers add constraint FKrepresente_FK
     foreign key (id_type_mobilier)
     references type_mobiliers;

alter table mobiliers add constraint FKcontenir_FK
     foreign key (id_type_lieu)
     references type_lieux;

alter table mobiliers add constraint FKconstitue_FK
     foreign key (id_type_materiaux)
     references type_materiaux;

alter table mobiliers add constraint FKassocie_FK
     foreign key (id_type-etat)
     references type_etats;

alter table type_mobilier_fournisseur add constraint FKser_typ
     foreign key (id_mobilier)
     references type_mobiliers;

alter table type_mobilier_fournisseur add constraint FKser_fou_FK
     foreign key (id_fournisseur)
     references fournisseurs;

alter table signalements add constraint FKimpacter_FK
     foreign key (id_immmobilier)
     references mobiliers;

alter table signalements add constraint FKdonner_FK
     foreign key (id_urgence)
     references urgences;

alter table signalements add constraint FKavoir_FK
     foreign key (id_statut)
     references statut;


-- Index Section
-- _____________ 

create index FKRealisee_IND
     on interventions (id_technicien);

create index FKRecevoir_IND
     on interventions (id_mobilier);

create index FKConcerne_IND
     on interventions (id_type_intervention);

create index FKrepresente_IND
     on mobiliers (id_type_mobilier);

create index FKcontenir_IND
     on mobiliers (id_type_lieu);

create index FKconstitue_IND
     on mobiliers (id_type_materiaux);

create index FKassocie_IND
     on mobiliers (id_type-etat);

create index FKser_fou_IND
     on type_mobilier_fournisseur (id_fournisseur);

create index FKimpacter_IND
     on signalements (id_immmobilier);

create index FKdonner_IND
     on signalements (id_urgence);

create index FKavoir_IND
     on signalements (id_statut);

