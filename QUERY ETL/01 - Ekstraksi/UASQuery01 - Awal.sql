IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DW_KelasC_Kelompok8')
BEGIN 
	ALTER DATABASE DW_KelasC_Kelompok8 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE DW_KelasC_Kelompok8;
END;
GO

CREATE DATABASE DW_KelasC_Kelompok8;
GO

-- Menspesifikasikan database mana yang mau diaktifkan sebagai lembar kerja
USE DW_KelasC_Kelompok8;
GO

-- Membuat skema ekstraksi
CREATE SCHEMA ekstraksi;
GO

-- Membuat skema transform
CREATE SCHEMA transform;
GO

-- Membuat skema loading
CREATE SCHEMA loading;
GO


