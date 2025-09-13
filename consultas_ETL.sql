CREATE DATABASE DW_Chinook;
USE DW_Chinook;

-- DIMENSIONES --

-----------------------------
---------- CLIENTE ----------
-----------------------------

CREATE TABLE DimCliente (
  ClienteKey INT IDENTITY(1,1) PRIMARY KEY,
  CustomerId INT,         
  FirstName NVARCHAR(40),
  LastName NVARCHAR(20),
  Company NVARCHAR(80),
  Address NVARCHAR(70),
  City NVARCHAR(100),
  State NVARCHAR(40),
  Country NVARCHAR(40),
  Email NVARCHAR(60)
);

--SELECT * FROM DimCliente;
-----------------------------
-----------TIEMPO------------
-----------------------------
CREATE TABLE DimTiempo (
  TiempoKey INT IDENTITY(1,1) PRIMARY KEY,
  Fecha DATE NOT NULL,
  FechaKey INT NOT NULL, 
  Ano INT, Mes INT, Dia INT,
  Trimestre INT
);
--SELECT * FROM DimTiempo;
-----------------------------
-----------GENERO------------
-----------------------------
CREATE TABLE DimGenero (
  GeneroKey INT IDENTITY(1,1) PRIMARY KEY,
  GenreId INT,
  Name NVARCHAR(200)
);

--select * from DimGenero;
-----------------------------
----------ARTISTA------------
-----------------------------
CREATE TABLE DimArtista (
  ArtistaKey INT IDENTITY(1,1) PRIMARY KEY,
  ArtistId INT,
  Name NVARCHAR(200)
);
--select * from DimArtista;
-----------------------------
------------ALBUM------------
-----------------------------
CREATE TABLE DimAlbum (
  AlbumKey INT IDENTITY(1,1) PRIMARY KEY,
  AlbumId INT,
  Title NVARCHAR(300),
  ArtistId INT
);
--select * from DimAlbum;
-----------------------------
------------TRACK------------
-----------------------------
CREATE TABLE DimTrack (
  TrackKey INT IDENTITY(1,1) PRIMARY KEY,
  TrackId INT,
  Name NVARCHAR(300),
  AlbumId INT,
  GenreId INT,
  UnitPrice DECIMAL(10,2)
);
--select * from DimTrack;

-----------------------------------------
--CREACIÓN DE TABLA DE HECHOS (CENTRAL)--
-----------------------------------------

CREATE TABLE HechosVentas (
  VentaKey INT IDENTITY(1,1) PRIMARY KEY,
  InvoiceLineId INT,
  InvoiceId INT,
  ClienteKey INT,
  TiempoKey INT,
  TrackKey INT,
  AlbumKey INT,
  ArtistaKey INT,
  GeneroKey INT,
  Quantity INT,
  UnitPrice DECIMAL(10,2),
  TotalVenta AS (Quantity * UnitPrice) PERSISTED
);
--select * from HechosVentas;

--CONEXIÓN DE LA TABLA DE HECHOS CON LAS DIMENSIONES--


-- SE ALTERA LA TABLA PARA PERMITIR LA CREACIÓN DE LAS LLAVES FORÁNEAS DE LAS TABLAS "DIMENSIONES"--
ALTER TABLE HechosVentas
  ADD CONSTRAINT FK_HechosVentas_Cliente FOREIGN KEY (ClienteKey)
  REFERENCES DimCliente(ClienteKey);

ALTER TABLE HechosVentas
  ADD CONSTRAINT FK_HechosVentas_Tiempo FOREIGN KEY (TiempoKey)
  REFERENCES DimTiempo(TiempoKey);

ALTER TABLE HechosVentas
  ADD CONSTRAINT FK_HechosVentas_Track FOREIGN KEY (TrackKey)
  REFERENCES DimTrack(TrackKey);

ALTER TABLE HechosVentas
  ADD CONSTRAINT FK_HechosVentas_Album FOREIGN KEY (AlbumKey)
  REFERENCES DimAlbum(AlbumKey);

ALTER TABLE HechosVentas
  ADD CONSTRAINT FK_HechosVentas_Artista FOREIGN KEY (ArtistaKey)
  REFERENCES DimArtista(ArtistaKey);

ALTER TABLE HechosVentas
  ADD CONSTRAINT FK_HechosVentas_Genero FOREIGN KEY (GeneroKey)
  REFERENCES DimGenero(GeneroKey);

------------------------------------------------------
--------INSERTAR DATOS DESDE LA BD EXISTENTE----------
------------------------------------------------------

--INSERT A LA TABLA CLIENTE--
INSERT INTO DW_Chinook.dbo.DimCliente (CustomerId, FirstName, LastName, Company, Address, City, State, Country, Email)
SELECT DISTINCT CustomerId, FirstName, LastName, Company, Address, City, State, Country, Email
FROM Chinook.dbo.Customer;

--INSERT DE LA TABLA TIEMPO--
INSERT INTO DW_Chinook.dbo.DimTiempo (Fecha, FechaKey, Ano, Mes, Dia, Trimestre)
SELECT DISTINCT
    CAST(InvoiceDate AS DATE) AS Fecha,
    CONVERT(INT, FORMAT(InvoiceDate, 'yyyyMMdd')) AS FechaKey,
    YEAR(InvoiceDate) AS Ano,
    MONTH(InvoiceDate) AS Mes,
    DAY(InvoiceDate) AS Dia,
    DATEPART(QUARTER, InvoiceDate) AS Trimestre
FROM Chinook.dbo.Invoice;

--INSERT DE LA TABLA GENERO--

INSERT INTO DW_Chinook.dbo.DimGenero (GenreId, Name)
SELECT DISTINCT GenreId, Name
FROM Chinook.dbo.Genre;


--INSERT DE LA TABLA ARTISTA--
INSERT INTO DW_Chinook.dbo.DimArtista (ArtistId, Name)
SELECT DISTINCT ArtistId, Name
FROM Chinook.dbo.Artist;

--INSERT DE LA TABLA ALBUM--

INSERT INTO DW_Chinook.dbo.DimAlbum (AlbumId, Title, ArtistId)
SELECT DISTINCT AlbumId, Title, ArtistId
FROM Chinook.dbo.Album;

--INSERT DE LA TABLA TRACK--
INSERT INTO DW_Chinook.dbo.DimTrack (TrackId, Name, AlbumId, GenreId, UnitPrice)
SELECT DISTINCT TrackId, Name, AlbumId, GenreId, UnitPrice
FROM Chinook.dbo.Track;

------------------------------------------------------
------------CONSULTAS DE ANÁLISIS DE SQL--------------
------------------------------------------------------


----------TOTAL DE VENTAS POR CADA CLIENTE------------
------------------------------------------------------
SELECT c.FirstName, c.LastName,
    SUM(h.TotalVenta) AS TotalVentas
FROM HechosVentas h
JOIN DimCliente c ON h.ClienteKey = c.ClienteKey
GROUP BY c.FirstName, c.LastName
ORDER BY TotalVentas DESC;

-------------TOTAL DE VENTAS POR GÉNERO---------------
------------------------------------------------------
SELECT g.Name AS Genero, SUM(h.TotalVenta) AS TotalVentas
FROM HechosVentas h
JOIN DimGenero g ON h.GeneroKey = g.GeneroKey
GROUP BY g.Name
ORDER BY TotalVentas DESC;

-------------TOTAL DE VENTAS POR ARTISTA--------------
------------------------------------------------------

SELECT a.Name AS Artista, SUM(h.TotalVenta) AS TotalVentas
FROM HechosVentas h
JOIN DimArtista a ON h.ArtistaKey = a.ArtistaKey
GROUP BY a.Name
ORDER BY TotalVentas DESC;


---------------TOTAL DE VENTAS POR PAÍS---------------
------------------------------------------------------

SELECT c.Country, SUM(h.TotalVenta) AS TotalVentas
FROM HechosVentas h
JOIN DimCliente c ON h.ClienteKey = c.ClienteKey
GROUP BY c.Country
ORDER BY TotalVentas DESC;

------------------------------------------------------
-----------------CREACIÓN DE VISTAS-------------------
------------------------------------------------------


------------------------------------------------------
-----------------VENTAS POR CLIENTE-------------------

CREATE VIEW TVentasPorCliente AS
SELECT c.FirstName, c.LastName,
    SUM(h.TotalVenta) AS TotalVentas
FROM HechosVentas h
JOIN DimCliente c ON h.ClienteKey = c.ClienteKey
GROUP BY c.FirstName, c.LastName;

--SELECT * FROM TVentasPorCliente ORDER BY TotalVentas DESC;

------------------------------------------------------
------------------VENTAS POR GÉNERO-------------------

CREATE VIEW TVentasPorGenero AS
SELECT g.Name as Genero,SUM(h.TotalVenta) AS TotalVentas
FROM HechosVentas h
JOIN DimGenero g ON h.GeneroKey = g.GeneroKey
GROUP BY g.Name;

--SELECT * FROM TVentasPorGenero ORDER BY TotalVentas DESC;


------------------------------------------------------
------------------VENTAS POR ARTISTA-------------------

CREATE VIEW TVentasPorArtista AS
SELECT a.Name AS Artista, SUM(h.TotalVenta) AS TotalVentas
FROM HechosVentas h
JOIN DimArtista a ON h.ArtistaKey = a.ArtistaKey
GROUP BY a.Name;

--SELECT * FROM TVentasPorArtista ORDER BY TotalVentas DESC;

------------------------------------------------------
-------------------VENTAS POR PAÍS--------------------
CREATE VIEW TVentasPorPais AS
SELECT c.Country AS Pais, SUM(h.TotalVenta) AS TotalVentas
FROM HechosVentas h
JOIN DimCliente c ON h.ClienteKey = c.ClienteKey
GROUP BY c.Country;

--SELECT * FROM TVentasPorPais ORDER BY TotalVentas DESC;


--INSERT INTO HechosVentas (InvoiceLineId, InvoiceId, ClienteKey,
	--TiempoKey, TrackKey, AlbumKey, ArtistaKey, GeneroKey, Quantity, UnitPrice)
--VALUES (10001, 5001, 1, 1, 1, 1, 1, 1, 2, 9.99);

--INSERT INTO HechosVentas (InvoiceLineId, InvoiceId, ClienteKey,
	--TiempoKey, TrackKey, AlbumKey, ArtistaKey, GeneroKey, Quantity, UnitPrice)
--VALUES (10002, 5002, 2, 2, 2, 2, 2, 2, 1, 14.99);


--INSERT INTO HechosVentas (InvoiceLineId, InvoiceId, ClienteKey,
	--TiempoKey, TrackKey, AlbumKey, ArtistaKey, GeneroKey, Quantity, UnitPrice)
--VALUES (10003, 5003, 3, 3, 3, 3, 3, 3, 5, 1.99);

