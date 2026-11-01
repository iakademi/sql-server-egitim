/* =====================================================================
   03 - SELECT Sorguları
   Konular: SELECT, WHERE, LIKE, IN, BETWEEN, NULL, ORDER BY, TOP,
            OFFSET-FETCH, DISTINCT, CASE, tarih/metin/sayı fonksiyonları,
            temel toplama fonksiyonları
   ===================================================================== */

USE IAkademiDB;
GO

/* ---------------------------------------------------------------------
   1. Temel SELECT
   --------------------------------------------------------------------- */
SELECT * FROM dbo.Kurslar;                                  -- tüm sütunlar (üretimde önerilmez)

SELECT KursAdi, Kategori, SaatSuresi, Fiyat                 -- yalnızca gereken sütunlar
FROM dbo.Kurslar;

SELECT KursAdi AS [Kurs Adı],                               -- sütun takma adı (alias)
       Fiyat   AS [Liste Fiyatı],
       Fiyat * 1.20 AS [KDV Dahil Fiyat],                   -- hesaplanan sütun
       Fiyat / SaatSuresi AS [Saatlik Ücret]
FROM dbo.Kurslar;

/* ---------------------------------------------------------------------
   2. WHERE ile filtreleme
   --------------------------------------------------------------------- */
SELECT Ad, Soyad, Sehir FROM dbo.Ogrenciler WHERE Sehir = N'İstanbul';

SELECT KursAdi, Fiyat FROM dbo.Kurslar WHERE Fiyat > 5000 AND SaatSuresi >= 36;

SELECT KursAdi, Kategori FROM dbo.Kurslar
WHERE Kategori = N'Yazılım' OR Kategori = N'Veri';

-- IN: birden fazla değerden biri
SELECT Ad, Soyad, Sehir FROM dbo.Ogrenciler WHERE Sehir IN (N'Ankara', N'İzmir', N'Bursa');

-- NOT IN
SELECT KursAdi, Kategori FROM dbo.Kurslar WHERE Kategori NOT IN (N'Yazılım', N'Veri');

-- BETWEEN: sınırlar dahildir
SELECT KursAdi, Fiyat FROM dbo.Kurslar WHERE Fiyat BETWEEN 4500 AND 6000 ORDER BY Fiyat;

SELECT Ad, Soyad, DogumTarihi FROM dbo.Ogrenciler
WHERE DogumTarihi BETWEEN '1995-01-01' AND '1999-12-31';

/* ---------------------------------------------------------------------
   3. LIKE ile örüntü arama
      %  : sıfır veya daha fazla karakter
      _  : tam bir karakter
      [] : karakter kümesi
   --------------------------------------------------------------------- */
SELECT KursAdi FROM dbo.Kurslar WHERE KursAdi LIKE N'P%';            -- P ile başlayan
SELECT KursAdi FROM dbo.Kurslar WHERE KursAdi LIKE N'%Temelleri';    -- Temelleri ile biten
SELECT KursAdi FROM dbo.Kurslar WHERE KursAdi LIKE N'%Server%';      -- içinde geçen
SELECT Ad, Soyad FROM dbo.Ogrenciler WHERE Ad LIKE N'_e%';           -- ikinci harfi e olan
SELECT Ad, Soyad FROM dbo.Ogrenciler WHERE Soyad LIKE N'[A-D]%';     -- A ile D arası başlayan

/* ---------------------------------------------------------------------
   4. NULL işlemleri
      NULL ile karşılaştırma = veya <> ile yapılmaz; IS NULL / IS NOT NULL kullanılır.
   --------------------------------------------------------------------- */
SELECT Ad, Soyad FROM dbo.Ogrenciler WHERE Sehir IS NULL;
SELECT COUNT(*) AS SehriBilinen FROM dbo.Ogrenciler WHERE Sehir IS NOT NULL;

SELECT Ad, Soyad,
       ISNULL(Sehir, N'Belirtilmemiş')                    AS Sehir,        -- tek alternatif
       COALESCE(CAST(DogumTarihi AS NVARCHAR(10)), N'-')  AS DogumTarihi   -- ilk NULL olmayan değer
FROM dbo.Ogrenciler
WHERE OgrenciId IN (19, 20);

-- Puanı henüz girilmemiş kayıtlar
SELECT KayitId, OgrenciId, KursId, Durum FROM dbo.Kayitlar WHERE Puan IS NULL;

/* ---------------------------------------------------------------------
   5. ORDER BY, TOP, DISTINCT
   --------------------------------------------------------------------- */
SELECT KursAdi, Fiyat FROM dbo.Kurslar ORDER BY Fiyat DESC;                  -- azalan
SELECT Ad, Soyad, Sehir FROM dbo.Ogrenciler ORDER BY Sehir, Soyad, Ad;       -- çok ölçütlü

SELECT TOP (3) KursAdi, Fiyat FROM dbo.Kurslar ORDER BY Fiyat DESC;          -- en pahalı 3 kurs
SELECT TOP (10) PERCENT Ad, Soyad FROM dbo.Ogrenciler ORDER BY DogumTarihi;  -- en büyük %10
SELECT TOP (2) WITH TIES KayitId, Puan FROM dbo.Kayitlar                     -- eşit puanlıları da getir
WHERE Puan IS NOT NULL ORDER BY Puan DESC;

SELECT DISTINCT Sehir FROM dbo.Ogrenciler WHERE Sehir IS NOT NULL ORDER BY Sehir;
SELECT DISTINCT Kategori FROM dbo.Kurslar;

-- Sayfalama: 2. sayfa (sayfa başına 5 kayıt)
SELECT OgrenciId, Ad, Soyad
FROM dbo.Ogrenciler
ORDER BY OgrenciId
OFFSET 5 ROWS FETCH NEXT 5 ROWS ONLY;

/* ---------------------------------------------------------------------
   6. CASE ifadesi
   --------------------------------------------------------------------- */
SELECT KursAdi, Fiyat,
       CASE
           WHEN Fiyat >= 7000 THEN N'Üst segment'
           WHEN Fiyat >= 5000 THEN N'Orta segment'
           ELSE N'Başlangıç segmenti'
       END AS FiyatSegmenti
FROM dbo.Kurslar
ORDER BY Fiyat DESC;

SELECT KayitId, Puan,
       CASE
           WHEN Puan IS NULL THEN N'Değerlendirilmedi'
           WHEN Puan >= 90   THEN N'AA'
           WHEN Puan >= 80   THEN N'BA'
           WHEN Puan >= 70   THEN N'BB'
           WHEN Puan >= 60   THEN N'CB'
           ELSE N'FF'
       END AS HarfNotu
FROM dbo.Kayitlar;

-- IIF ve CHOOSE
SELECT KayitId, IIF(Durum = N'Aktif', N'Devam ediyor', N'Kapandı') AS Aciklama FROM dbo.Kayitlar;
SELECT CHOOSE(3, N'Pzt', N'Sal', N'Çar', N'Per') AS ucuncu;

/* ---------------------------------------------------------------------
   7. Metin fonksiyonları
   --------------------------------------------------------------------- */
SELECT Ad, Soyad,
       Ad + N' ' + Soyad                       AS AdSoyad,
       CONCAT(Ad, N' ', UPPER(Soyad))          AS AdBuyukSoyad,
       LEN(Email)                              AS EmailUzunlugu,
       LEFT(Ad, 1) + LEFT(Soyad, 1)            AS BasHarfler,
       SUBSTRING(Email, 1, CHARINDEX(N'@', Email) - 1) AS KullaniciAdi,
       REPLACE(Email, N'example.com', N'ornek.test')   AS YeniEmail
FROM dbo.Ogrenciler
WHERE OgrenciId <= 5;
GO

/* ---------------------------------------------------------------------
   8. Tarih fonksiyonları
   --------------------------------------------------------------------- */
SELECT Ad, Soyad, DogumTarihi,
       DATEDIFF(YEAR, DogumTarihi, CAST(SYSDATETIME() AS DATE)) AS YaklasikYas,
       YEAR(DogumTarihi)                                         AS DogumYili,
       DATENAME(MONTH, DogumTarihi)                              AS DogumAyi,
       FORMAT(DogumTarihi, 'dd MMMM yyyy', 'tr-TR')              AS TrBicim
FROM dbo.Ogrenciler
WHERE DogumTarihi IS NOT NULL AND OgrenciId <= 5;

SELECT SYSDATETIME()                              AS Simdi,
       DATEADD(DAY, 30, CAST(SYSDATETIME() AS DATE)) AS OtuzGunSonra,
       EOMONTH(SYSDATETIME())                     AS AyinSonGunu,
       DATEFROMPARTS(2026, 1, 15)                 AS Tarih;

-- 2026 yılındaki kayıtlar (aralık koşulu dizin kullanımına uygundur)
SELECT KayitId, OgrenciId, KursId, KayitTarihi
FROM dbo.Kayitlar
WHERE KayitTarihi >= '2026-01-01' AND KayitTarihi < '2027-01-01'
ORDER BY KayitTarihi;

/* ---------------------------------------------------------------------
   9. Sayısal fonksiyonlar ve basit toplamalar
   --------------------------------------------------------------------- */
SELECT ROUND(5800.00 / 36, 2)  AS SaatlikUcret,
       CEILING(5800.00 / 36)   AS Yukari,
       FLOOR(5800.00 / 36)     AS Asagi,
       ABS(-15)                AS Mutlak,
       POWER(2, 10)            AS UsAlma;

SELECT COUNT(*)            AS KursSayisi,
       MIN(Fiyat)          AS EnUcuz,
       MAX(Fiyat)          AS EnPahali,
       AVG(Fiyat)          AS OrtalamaFiyat,
       SUM(SaatSuresi)     AS ToplamSaat
FROM dbo.Kurslar;

SELECT COUNT(*)      AS TumKayitlar,
       COUNT(Puan)   AS PuanliKayitlar,        -- COUNT(sütun) NULL değerleri saymaz
       AVG(Puan)     AS OrtalamaPuan           -- AVG de NULL'ları yok sayar
FROM dbo.Kayitlar;
GO
