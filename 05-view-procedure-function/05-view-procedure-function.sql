/* =====================================================================
   05 - View, Stored Procedure, Function ve Trigger
   Gereksinim : SQL Server 2016 SP1 veya üzeri (CREATE OR ALTER için)
   Önce 01 ve 02 betikleri çalıştırılmış olmalıdır.
   ===================================================================== */

USE IAkademiDB;
GO

/* =====================================================================
   BÖLÜM A - VIEW (Görünüm)
   Sık kullanılan sorguları adlandırıp yeniden kullanılabilir hale getirir.
   Not: CREATE VIEW, bir batch'in ilk ifadesi olmalıdır (öncesinde GO).
   ===================================================================== */

CREATE OR ALTER VIEW dbo.vw_KursOzet
AS
SELECT k.KursId,
       k.KursAdi,
       k.Kategori,
       k.SaatSuresi,
       k.Fiyat,
       e.Ad + N' ' + e.Soyad                                      AS EgitmenAdSoyad,
       COUNT(ky.KayitId)                                          AS KayitSayisi,
       SUM(CASE WHEN ky.Durum = N'Aktif' THEN 1 ELSE 0 END)       AS AktifKayit,
       CAST(AVG(CAST(ky.Puan AS DECIMAL(5,2))) AS DECIMAL(5,2))   AS PuanOrtalamasi
FROM dbo.Kurslar k
JOIN dbo.Egitmenler e       ON e.EgitmenId = k.EgitmenId
LEFT JOIN dbo.Kayitlar ky   ON ky.KursId   = k.KursId
GROUP BY k.KursId, k.KursAdi, k.Kategori, k.SaatSuresi, k.Fiyat, e.Ad, e.Soyad;
GO

CREATE OR ALTER VIEW dbo.vw_OgrenciKayitDetay
AS
SELECT ky.KayitId,
       o.OgrenciId,
       o.Ad + N' ' + o.Soyad AS OgrenciAdSoyad,
       o.Sehir,
       k.KursId,
       k.KursAdi,
       k.Kategori,
       ky.KayitTarihi,
       ky.Durum,
       ky.Puan
FROM dbo.Kayitlar ky
JOIN dbo.Ogrenciler o ON o.OgrenciId = ky.OgrenciId
JOIN dbo.Kurslar    k ON k.KursId    = ky.KursId;
GO

-- View, tablo gibi sorgulanır
SELECT * FROM dbo.vw_KursOzet ORDER BY KayitSayisi DESC;

SELECT OgrenciAdSoyad, KursAdi, Puan
FROM dbo.vw_OgrenciKayitDetay
WHERE Sehir = N'İstanbul' AND Durum = N'Tamamlandı'
ORDER BY Puan DESC;
GO

-- WITH SCHEMABINDING + CHECK OPTION: temel tablo yapısını korur, görünüm dışı veri girişini engeller
CREATE OR ALTER VIEW dbo.vw_AktifKayitlar
WITH SCHEMABINDING
AS
SELECT KayitId, OgrenciId, KursId, KayitTarihi, Durum
FROM dbo.Kayitlar
WHERE Durum = N'Aktif'
WITH CHECK OPTION;
GO

/* =====================================================================
   BÖLÜM B - FUNCTION (Fonksiyon)
   ===================================================================== */

-- Skaler fonksiyon: doğum tarihinden tam yaş hesaplar
CREATE OR ALTER FUNCTION dbo.fn_YasHesapla (@DogumTarihi DATE)
RETURNS INT
AS
BEGIN
    IF @DogumTarihi IS NULL RETURN NULL;

    DECLARE @Bugun DATE = CAST(SYSDATETIME() AS DATE);
    DECLARE @Yas INT = DATEDIFF(YEAR, @DogumTarihi, @Bugun);

    -- Bu yıl doğum günü henüz gelmediyse bir eksilt
    IF DATEADD(YEAR, @Yas, @DogumTarihi) > @Bugun SET @Yas -= 1;

    RETURN @Yas;
END;
GO

-- Skaler fonksiyon: puandan harf notu
CREATE OR ALTER FUNCTION dbo.fn_HarfNotu (@Puan TINYINT)
RETURNS NVARCHAR(10)
AS
BEGIN
    RETURN CASE
               WHEN @Puan IS NULL THEN N'-'
               WHEN @Puan >= 90   THEN N'AA'
               WHEN @Puan >= 80   THEN N'BA'
               WHEN @Puan >= 70   THEN N'BB'
               WHEN @Puan >= 60   THEN N'CB'
               ELSE N'FF'
           END;
END;
GO

-- Inline tablo değerli fonksiyon (parametreli view gibi çalışır, genellikle en hızlı türdür)
CREATE OR ALTER FUNCTION dbo.fn_OgrenciKurslari (@OgrenciId INT)
RETURNS TABLE
AS
RETURN
(
    SELECT k.KursId, k.KursAdi, k.Kategori, ky.KayitTarihi, ky.Durum, ky.Puan,
           dbo.fn_HarfNotu(ky.Puan) AS HarfNotu
    FROM dbo.Kayitlar ky
    JOIN dbo.Kurslar  k ON k.KursId = ky.KursId
    WHERE ky.OgrenciId = @OgrenciId
);
GO

-- Kullanım
SELECT Ad, Soyad, dbo.fn_YasHesapla(DogumTarihi) AS Yas
FROM dbo.Ogrenciler
ORDER BY Yas DESC;

SELECT * FROM dbo.fn_OgrenciKurslari(1);

-- APPLY ile her öğrenci için fonksiyonu çağırma
SELECT o.Ad, o.Soyad, f.KursAdi, f.Puan, f.HarfNotu
FROM dbo.Ogrenciler o
CROSS APPLY dbo.fn_OgrenciKurslari(o.OgrenciId) f
WHERE f.Puan IS NOT NULL
ORDER BY f.Puan DESC;
GO

/* =====================================================================
   BÖLÜM C - STORED PROCEDURE (Saklı Yordam)
   ===================================================================== */

-- Parametreli rapor yordamı (isteğe bağlı parametre)
CREATE OR ALTER PROCEDURE dbo.usp_KursRaporu
    @Kategori NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT KursAdi, Kategori, EgitmenAdSoyad, KayitSayisi, AktifKayit, PuanOrtalamasi
    FROM dbo.vw_KursOzet
    WHERE @Kategori IS NULL OR Kategori = @Kategori
    ORDER BY KayitSayisi DESC, KursAdi;
END;
GO

-- İş kuralları, hata yönetimi ve OUTPUT parametresi içeren kayıt yordamı
CREATE OR ALTER PROCEDURE dbo.usp_OgrenciKayitEkle
    @OgrenciId INT,
    @KursId    INT,
    @KayitId   INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Ogrenciler WHERE OgrenciId = @OgrenciId)
        THROW 50001, N'Öğrenci bulunamadı.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.Kurslar WHERE KursId = @KursId)
        THROW 50002, N'Kurs bulunamadı.', 1;

    IF EXISTS (SELECT 1 FROM dbo.Kayitlar WHERE OgrenciId = @OgrenciId AND KursId = @KursId)
        THROW 50003, N'Öğrenci bu kursa zaten kayıtlı.', 1;

    INSERT INTO dbo.Kayitlar (OgrenciId, KursId, KayitTarihi, Durum)
    VALUES (@OgrenciId, @KursId, CAST(SYSDATETIME() AS DATE), N'Aktif');

    SET @KayitId = SCOPE_IDENTITY();   -- yeni oluşan kimlik değeri
END;
GO

-- Kursu tamamlama: durumu ve puanı birlikte günceller
CREATE OR ALTER PROCEDURE dbo.usp_PuanGir
    @KayitId INT,
    @Puan    TINYINT
AS
BEGIN
    SET NOCOUNT ON;

    IF @Puan > 100
        THROW 50004, N'Puan 0 ile 100 arasında olmalıdır.', 1;

    UPDATE dbo.Kayitlar
    SET Puan = @Puan, Durum = N'Tamamlandı'
    WHERE KayitId = @KayitId AND Durum = N'Aktif';

    IF @@ROWCOUNT = 0
        THROW 50005, N'Aktif durumda böyle bir kayıt bulunamadı.', 1;
END;
GO

-- Kullanım
EXEC dbo.usp_KursRaporu;
EXEC dbo.usp_KursRaporu @Kategori = N'Yazılım';

DECLARE @YeniKayit INT;
EXEC dbo.usp_OgrenciKayitEkle @OgrenciId = 20, @KursId = 7, @KayitId = @YeniKayit OUTPUT;
PRINT N'Oluşturulan kayıt numarası: ' + CAST(@YeniKayit AS NVARCHAR(10));

-- Hata durumunu yakalama: aynı kayıt tekrar eklenmeye çalışılır
BEGIN TRY
    EXEC dbo.usp_OgrenciKayitEkle @OgrenciId = 20, @KursId = 7, @KayitId = @YeniKayit OUTPUT;
END TRY
BEGIN CATCH
    PRINT N'Hata ' + CAST(ERROR_NUMBER() AS NVARCHAR(10)) + N': ' + ERROR_MESSAGE();
END CATCH;
GO

/* =====================================================================
   BÖLÜM D - TRIGGER (Tetikleyici)
   Kayıt durumu değiştiğinde değişikliği bir log tablosuna yazar.
   ===================================================================== */

IF OBJECT_ID(N'dbo.KayitDurumLog', N'U') IS NULL
    CREATE TABLE dbo.KayitDurumLog
    (
        LogId           INT IDENTITY(1,1) CONSTRAINT PK_KayitDurumLog PRIMARY KEY,
        KayitId         INT          NOT NULL,
        EskiDurum       NVARCHAR(20) NOT NULL,
        YeniDurum       NVARCHAR(20) NOT NULL,
        DegisimZamani   DATETIME2(0) NOT NULL CONSTRAINT DF_KayitDurumLog_Zaman DEFAULT (SYSDATETIME()),
        Kullanici       SYSNAME      NOT NULL CONSTRAINT DF_KayitDurumLog_Kullanici DEFAULT (SUSER_SNAME())
    );
GO

CREATE OR ALTER TRIGGER dbo.trg_Kayitlar_DurumLog
ON dbo.Kayitlar
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT UPDATE(Durum) RETURN;

    -- inserted: yeni değerler, deleted: eski değerler (çok satırlı güncellemeler için küme tabanlı yazılır)
    INSERT INTO dbo.KayitDurumLog (KayitId, EskiDurum, YeniDurum)
    SELECT d.KayitId, d.Durum, i.Durum
    FROM deleted d
    JOIN inserted i ON i.KayitId = d.KayitId
    WHERE d.Durum <> i.Durum;
END;
GO

-- Deneme: yukarıda oluşan kaydı tamamla, logu gör
DECLARE @DenemeKayit INT = (SELECT KayitId FROM dbo.Kayitlar WHERE OgrenciId = 20 AND KursId = 7);
EXEC dbo.usp_PuanGir @KayitId = @DenemeKayit, @Puan = 87;

SELECT * FROM dbo.KayitDurumLog;
SELECT * FROM dbo.vw_OgrenciKayitDetay WHERE OgrenciId = 20;
GO

-- Temizlik: deneme verisini silip tabloyu ilk haline döndürür
DELETE FROM dbo.Kayitlar WHERE OgrenciId = 20 AND KursId = 7;
DELETE FROM dbo.KayitDurumLog;
GO
