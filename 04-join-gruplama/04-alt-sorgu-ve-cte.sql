/* =====================================================================
   04 (devam) - Alt Sorgular, CTE ve Küme İşlemleri
   Konular: skaler/tablo alt sorgu, EXISTS, ilişkili alt sorgu, CROSS APPLY,
            CTE, özyinelemeli CTE, UNION / INTERSECT / EXCEPT
   ===================================================================== */

USE IAkademiDB;
GO

/* ---------------------------------------------------------------------
   1. Alt sorgular
   --------------------------------------------------------------------- */
-- Ortalamanın üzerinde fiyatlı kurslar (skaler alt sorgu)
SELECT KursAdi, Fiyat
FROM dbo.Kurslar
WHERE Fiyat > (SELECT AVG(Fiyat) FROM dbo.Kurslar)
ORDER BY Fiyat DESC;

-- IN ile alt sorgu: en az bir kursu tamamlamış öğrenciler
SELECT Ad, Soyad
FROM dbo.Ogrenciler
WHERE OgrenciId IN (SELECT OgrenciId FROM dbo.Kayitlar WHERE Durum = N'Tamamlandı');

-- EXISTS: eşleşen satır var mı kontrolü (büyük tablolarda IN'e göre genelde daha verimli)
SELECT e.Ad, e.Soyad
FROM dbo.Egitmenler e
WHERE EXISTS (SELECT 1 FROM dbo.Kurslar k WHERE k.EgitmenId = e.EgitmenId);

SELECT e.Ad, e.Soyad
FROM dbo.Egitmenler e
WHERE NOT EXISTS (SELECT 1 FROM dbo.Kurslar k WHERE k.EgitmenId = e.EgitmenId);

-- İlişkili (correlated) alt sorgu: öğrencinin en yüksek puanı
SELECT o.Ad, o.Soyad,
       (SELECT MAX(ky.Puan) FROM dbo.Kayitlar ky WHERE ky.OgrenciId = o.OgrenciId) AS EnYuksekPuan
FROM dbo.Ogrenciler o
ORDER BY EnYuksekPuan DESC;

-- Kendi kategorisinin ortalama fiyatından pahalı kurslar
SELECT k.KursAdi, k.Kategori, k.Fiyat
FROM dbo.Kurslar k
WHERE k.Fiyat > (SELECT AVG(k2.Fiyat) FROM dbo.Kurslar k2 WHERE k2.Kategori = k.Kategori);

-- Türetilmiş tablo (derived table)
SELECT t.Kategori, t.KursSayisi
FROM (SELECT Kategori, COUNT(*) AS KursSayisi FROM dbo.Kurslar GROUP BY Kategori) t
WHERE t.KursSayisi > 1;

-- CROSS APPLY: her öğrenci için en yüksek puanlı kaydı getirir
SELECT o.Ad, o.Soyad, en.KursAdi, en.Puan
FROM dbo.Ogrenciler o
CROSS APPLY (
    SELECT TOP (1) k.KursAdi, ky.Puan
    FROM dbo.Kayitlar ky
    JOIN dbo.Kurslar k ON k.KursId = ky.KursId
    WHERE ky.OgrenciId = o.OgrenciId AND ky.Puan IS NOT NULL
    ORDER BY ky.Puan DESC
) en
ORDER BY en.Puan DESC;

/* ---------------------------------------------------------------------
   2. CTE (Common Table Expression)
   --------------------------------------------------------------------- */
WITH OgrenciOzet AS
(
    SELECT OgrenciId,
           COUNT(*)  AS KayitSayisi,
           AVG(CAST(Puan AS DECIMAL(5,2))) AS PuanOrtalamasi
    FROM dbo.Kayitlar
    GROUP BY OgrenciId
)
SELECT o.Ad, o.Soyad, oz.KayitSayisi, oz.PuanOrtalamasi
FROM OgrenciOzet oz
JOIN dbo.Ogrenciler o ON o.OgrenciId = oz.OgrenciId
WHERE oz.KayitSayisi >= 2
ORDER BY oz.PuanOrtalamasi DESC;

-- Birden fazla CTE: kurs başına ortalama ve genel ortalamayla kıyas
WITH KursPuan AS
(
    SELECT KursId, AVG(CAST(Puan AS DECIMAL(5,2))) AS Ortalama
    FROM dbo.Kayitlar
    WHERE Puan IS NOT NULL
    GROUP BY KursId
),
GenelPuan AS
(
    SELECT AVG(CAST(Puan AS DECIMAL(5,2))) AS Ortalama FROM dbo.Kayitlar WHERE Puan IS NOT NULL
)
SELECT k.KursAdi, kp.Ortalama AS KursOrtalamasi, gp.Ortalama AS GenelOrtalama,
       CASE WHEN kp.Ortalama >= gp.Ortalama THEN N'Ortalamanın üzerinde' ELSE N'Ortalamanın altında' END AS Durum
FROM KursPuan kp
CROSS JOIN GenelPuan gp
JOIN dbo.Kurslar k ON k.KursId = kp.KursId
ORDER BY kp.Ortalama DESC;

-- CTE ile tekrarlı kayıtları ayıklama deseni (ROW_NUMBER)
-- Her kategorinin en pahalı kursu
WITH Sirali AS
(
    SELECT KursAdi, Kategori, Fiyat,
           ROW_NUMBER() OVER (PARTITION BY Kategori ORDER BY Fiyat DESC) AS Sira
    FROM dbo.Kurslar
)
SELECT KursAdi, Kategori, Fiyat FROM Sirali WHERE Sira = 1 ORDER BY Kategori;

/* ---------------------------------------------------------------------
   3. Özyinelemeli (recursive) CTE
   --------------------------------------------------------------------- */
-- 1'den 10'a kadar sayı üretme
WITH Sayilar AS
(
    SELECT 1 AS N
    UNION ALL
    SELECT N + 1 FROM Sayilar WHERE N < 10
)
SELECT N, N * N AS Kare FROM Sayilar;

-- Takvim üretme: 2026 Ocak ayının her günü ve o gün başlayan kayıt sayısı
WITH Gunler AS
(
    SELECT CAST('2026-01-01' AS DATE) AS Gun
    UNION ALL
    SELECT DATEADD(DAY, 1, Gun) FROM Gunler WHERE Gun < '2026-01-31'
)
SELECT g.Gun, DATENAME(WEEKDAY, g.Gun) AS GunAdi, COUNT(ky.KayitId) AS KayitSayisi
FROM Gunler g
LEFT JOIN dbo.Kayitlar ky ON ky.KayitTarihi = g.Gun
GROUP BY g.Gun
HAVING COUNT(ky.KayitId) > 0
ORDER BY g.Gun
OPTION (MAXRECURSION 100);

/* ---------------------------------------------------------------------
   4. Küme işlemleri: UNION, INTERSECT, EXCEPT
      Sütun sayısı ve veri tipleri uyumlu olmalıdır.
   --------------------------------------------------------------------- */
-- UNION: tekrarları eler; UNION ALL: tekrarları korur
SELECT Ad, Soyad, N'Öğrenci' AS Rol FROM dbo.Ogrenciler WHERE Sehir = N'Ankara'
UNION ALL
SELECT Ad, Soyad, N'Eğitmen' FROM dbo.Egitmenler WHERE Ad LIKE N'[ZS]%'
ORDER BY Soyad;

-- Hem C# hem SQL Server kursuna kayıtlı olan öğrenciler (INTERSECT)
SELECT OgrenciId FROM dbo.Kayitlar WHERE KursId = 1      -- C# ile Programlama
INTERSECT
SELECT OgrenciId FROM dbo.Kayitlar WHERE KursId = 5;     -- SQL Server Temelleri

-- C# kursuna kayıtlı ama SQL Server kursuna kayıtlı olmayan öğrenciler (EXCEPT)
SELECT OgrenciId FROM dbo.Kayitlar WHERE KursId = 1
EXCEPT
SELECT OgrenciId FROM dbo.Kayitlar WHERE KursId = 5;
GO
