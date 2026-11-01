/* =====================================================================
   01 - Veritabanı ve Tabloların Oluşturulması
   Veritabanı : IAkademiDB (eğitim amaçlı örnek şema)
   Tablolar   : Egitmenler, Ogrenciler, Kurslar, Kayitlar
   Gereksinim : SQL Server 2017 veya üzeri (SSMS / Azure Data Studio)

   UYARI: Bu betik varsa IAkademiDB veritabanını SİLİP yeniden oluşturur.
          Yalnızca eğitim/test ortamında çalıştırın.
   ===================================================================== */

USE master;
GO

-- Varsa eski veritabanını kapat ve sil
IF DB_ID(N'IAkademiDB') IS NOT NULL
BEGIN
    ALTER DATABASE IAkademiDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE IAkademiDB;
END
GO

-- Türkçe karakterlere duyarlı, büyük/küçük harf duyarsız (CI), aksan duyarlı (AS) sıralama
CREATE DATABASE IAkademiDB
COLLATE Turkish_CI_AS;
GO

USE IAkademiDB;
GO

/* ---------------------------------------------------------------------
   Egitmenler
   --------------------------------------------------------------------- */
CREATE TABLE dbo.Egitmenler
(
    EgitmenId        INT IDENTITY(1,1)  NOT NULL,
    Ad               NVARCHAR(50)       NOT NULL,
    Soyad            NVARCHAR(50)       NOT NULL,
    UzmanlikAlani    NVARCHAR(100)      NOT NULL,
    Email            NVARCHAR(150)      NOT NULL,
    IseBaslamaTarihi DATE               NOT NULL CONSTRAINT DF_Egitmenler_IseBaslama DEFAULT (CAST(SYSDATETIME() AS DATE)),

    CONSTRAINT PK_Egitmenler       PRIMARY KEY CLUSTERED (EgitmenId),
    CONSTRAINT UQ_Egitmenler_Email UNIQUE (Email)
);
GO

/* ---------------------------------------------------------------------
   Ogrenciler
   --------------------------------------------------------------------- */
CREATE TABLE dbo.Ogrenciler
(
    OgrenciId    INT IDENTITY(1,1) NOT NULL,
    Ad           NVARCHAR(50)      NOT NULL,
    Soyad        NVARCHAR(50)      NOT NULL,
    Email        NVARCHAR(150)     NOT NULL,
    DogumTarihi  DATE              NULL,      -- isteğe bağlı alan
    Sehir        NVARCHAR(50)      NULL,      -- isteğe bağlı alan
    KayitTarihi  DATETIME2(0)      NOT NULL CONSTRAINT DF_Ogrenciler_KayitTarihi DEFAULT (SYSDATETIME()),

    CONSTRAINT PK_Ogrenciler       PRIMARY KEY CLUSTERED (OgrenciId),
    CONSTRAINT UQ_Ogrenciler_Email UNIQUE (Email),
    CONSTRAINT CK_Ogrenciler_DogumTarihi CHECK (DogumTarihi IS NULL OR DogumTarihi <= CAST(SYSDATETIME() AS DATE))
);
GO

/* ---------------------------------------------------------------------
   Kurslar
   --------------------------------------------------------------------- */
CREATE TABLE dbo.Kurslar
(
    KursId      INT IDENTITY(1,1) NOT NULL,
    KursAdi     NVARCHAR(100)     NOT NULL,
    Kategori    NVARCHAR(50)      NOT NULL,
    SaatSuresi  SMALLINT          NOT NULL,
    Fiyat       DECIMAL(10,2)     NOT NULL,
    EgitmenId   INT               NOT NULL,

    CONSTRAINT PK_Kurslar          PRIMARY KEY CLUSTERED (KursId),
    CONSTRAINT UQ_Kurslar_KursAdi  UNIQUE (KursAdi),
    CONSTRAINT CK_Kurslar_Saat     CHECK (SaatSuresi > 0),
    CONSTRAINT CK_Kurslar_Fiyat    CHECK (Fiyat >= 0),
    CONSTRAINT FK_Kurslar_Egitmenler FOREIGN KEY (EgitmenId) REFERENCES dbo.Egitmenler (EgitmenId)
);
GO

/* ---------------------------------------------------------------------
   Kayitlar (Ogrenciler ile Kurslar arasındaki çoka-çok ilişki tablosu)
   --------------------------------------------------------------------- */
CREATE TABLE dbo.Kayitlar
(
    KayitId      INT IDENTITY(1,1) NOT NULL,
    OgrenciId    INT               NOT NULL,
    KursId       INT               NOT NULL,
    KayitTarihi  DATE              NOT NULL CONSTRAINT DF_Kayitlar_KayitTarihi DEFAULT (CAST(SYSDATETIME() AS DATE)),
    Durum        NVARCHAR(20)      NOT NULL CONSTRAINT DF_Kayitlar_Durum DEFAULT (N'Aktif'),
    Puan         TINYINT           NULL,     -- kurs tamamlanınca girilen sınav puanı (0-100)

    CONSTRAINT PK_Kayitlar PRIMARY KEY CLUSTERED (KayitId),
    CONSTRAINT FK_Kayitlar_Ogrenciler FOREIGN KEY (OgrenciId) REFERENCES dbo.Ogrenciler (OgrenciId),
    CONSTRAINT FK_Kayitlar_Kurslar    FOREIGN KEY (KursId)    REFERENCES dbo.Kurslar (KursId),
    -- Bir öğrenci aynı kursa yalnızca bir kez kaydolabilir
    CONSTRAINT UQ_Kayitlar_Ogrenci_Kurs UNIQUE (OgrenciId, KursId),
    CONSTRAINT CK_Kayitlar_Durum CHECK (Durum IN (N'Aktif', N'Tamamlandı', N'İptal')),
    CONSTRAINT CK_Kayitlar_Puan  CHECK (Puan BETWEEN 0 AND 100),
    -- Puan yalnızca tamamlanan kayıtlarda bulunabilir
    CONSTRAINT CK_Kayitlar_PuanDurum CHECK (Puan IS NULL OR Durum = N'Tamamlandı')
);
GO

/* ---------------------------------------------------------------------
   Yabancı anahtar sütunları için dizinler (JOIN performansı)
   --------------------------------------------------------------------- */
CREATE NONCLUSTERED INDEX IX_Kurslar_EgitmenId  ON dbo.Kurslar (EgitmenId);
CREATE NONCLUSTERED INDEX IX_Kayitlar_KursId    ON dbo.Kayitlar (KursId);
GO

/* ---------------------------------------------------------------------
   Kontrol: oluşturulan tabloları ve sütunları listele
   --------------------------------------------------------------------- */
SELECT t.name AS Tablo, c.column_id AS Sira, c.name AS Sutun,
       ty.name AS VeriTipi, c.max_length AS MaksUzunluk, c.is_nullable AS NullOlabilir
FROM sys.tables t
JOIN sys.columns c ON c.object_id = t.object_id
JOIN sys.types ty  ON ty.user_type_id = c.user_type_id
ORDER BY t.name, c.column_id;
GO
