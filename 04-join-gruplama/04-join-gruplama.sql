/* =====================================================================
   04 - JOIN ve Gruplama
   Konular: INNER / LEFT / RIGHT / FULL / CROSS JOIN, GROUP BY, HAVING,
            ROLLUP, STRING_AGG, pencere fonksiyonları (OVER)
   ===================================================================== */

USE IAkademiDB;
GO

/* ---------------------------------------------------------------------
   1. INNER JOIN: iki tabloda da eşleşen satırlar
   --------------------------------------------------------------------- */
SELECT k.KursAdi, k.Kategori, e.Ad + N' ' + e.Soyad AS Egitmen
FROM dbo.Kurslar k
INNER JOIN dbo.Egitmenler e ON e.EgitmenId = k.EgitmenId
ORDER BY k.KursAdi;

-- Üç tablo: öğrenci - kayıt - kurs
SELECT o.Ad + N' ' + o.Soyad AS Ogrenci, k.KursAdi, ky.Durum, ky.Puan
FROM dbo.Kayitlar ky
JOIN dbo.Ogrenciler o ON o.OgrenciId = ky.OgrenciId
JOIN dbo.Kurslar    k ON k.KursId    = ky.KursId
WHERE ky.Durum = N'Tamamlandı'
ORDER BY ky.Puan DESC, Ogrenci;

/* ---------------------------------------------------------------------
   2. LEFT JOIN: soldaki tablonun tüm satırları, eşleşme yoksa NULL
   --------------------------------------------------------------------- */
-- Hiç kursa kaydolmamış öğrenciler
SELECT o.OgrenciId, o.Ad, o.Soyad
FROM dbo.Ogrenciler o
LEFT JOIN dbo.Kayitlar ky ON ky.OgrenciId = o.OgrenciId
WHERE ky.KayitId IS NULL;

-- Hiç kaydı olmayan kurslar
SELECT k.KursAdi
FROM dbo.Kurslar k
LEFT JOIN dbo.Kayitlar ky ON ky.KursId = k.KursId
WHERE ky.KayitId IS NULL;

-- Kursu olmayan eğitmenler
SELECT e.Ad, e.Soyad, e.UzmanlikAlani
FROM dbo.Egitmenler e
LEFT JOIN dbo.Kurslar k ON k.EgitmenId = e.EgitmenId
WHERE k.KursId IS NULL;

/* ---------------------------------------------------------------------
   3. RIGHT JOIN ve FULL OUTER JOIN
   --------------------------------------------------------------------- */
-- Bu sorgu, yukarıdaki "kursu olmayan eğitmenler" sorgusunun RIGHT JOIN ile yazılmış halidir
SELECT e.Ad, e.Soyad, k.KursAdi
FROM dbo.Kurslar k
RIGHT JOIN dbo.Egitmenler e ON e.EgitmenId = k.EgitmenId
ORDER BY e.Soyad;

-- FULL JOIN: her iki taraftaki eşleşmeyen satırlar da gelir
SELECT o.Ad, o.Soyad, ky.KayitId
FROM dbo.Ogrenciler o
FULL OUTER JOIN dbo.Kayitlar ky ON ky.OgrenciId = o.OgrenciId
WHERE o.OgrenciId IS NULL OR ky.KayitId IS NULL;

/* ---------------------------------------------------------------------
   4. CROSS JOIN ve SELF JOIN
   --------------------------------------------------------------------- */
-- CROSS JOIN: tüm kombinasyonlar (5 şehir x 3 kategori gibi planlama tabloları için)
SELECT s.Sehir, c.Kategori
FROM (SELECT DISTINCT Sehir FROM dbo.Ogrenciler WHERE Sehir IS NOT NULL) s
CROSS JOIN (SELECT DISTINCT Kategori FROM dbo.Kurslar) c
ORDER BY s.Sehir, c.Kategori;

-- SELF JOIN: aynı şehirde yaşayan öğrenci çiftleri
SELECT a.Ad + N' ' + a.Soyad AS Ogrenci1, b.Ad + N' ' + b.Soyad AS Ogrenci2, a.Sehir
FROM dbo.Ogrenciler a
JOIN dbo.Ogrenciler b ON a.Sehir = b.Sehir AND a.OgrenciId < b.OgrenciId   -- her çifti bir kez getirir
WHERE a.Sehir = N'Bursa';

/* ---------------------------------------------------------------------
   5. GROUP BY ve toplama fonksiyonları
   --------------------------------------------------------------------- */
-- Şehre göre öğrenci sayısı
SELECT ISNULL(Sehir, N'Belirtilmemiş') AS Sehir, COUNT(*) AS OgrenciSayisi
FROM dbo.Ogrenciler
GROUP BY Sehir
ORDER BY OgrenciSayisi DESC, Sehir;

-- Kategoriye göre kurs sayısı, ortalama fiyat ve toplam süre
SELECT Kategori,
       COUNT(*)        AS KursSayisi,
       AVG(Fiyat)      AS OrtalamaFiyat,
       SUM(SaatSuresi) AS ToplamSaat
FROM dbo.Kurslar
GROUP BY Kategori;

-- Kurs bazında kayıt sayısı, tamamlanan sayısı ve puan ortalaması (kaydı olmayan kurslar dahil)
SELECT k.KursAdi,
       COUNT(ky.KayitId)                                   AS KayitSayisi,
       SUM(CASE WHEN ky.Durum = N'Tamamlandı' THEN 1 ELSE 0 END) AS Tamamlanan,
       AVG(CAST(ky.Puan AS DECIMAL(5,2)))                  AS PuanOrtalamasi
FROM dbo.Kurslar k
LEFT JOIN dbo.Kayitlar ky ON ky.KursId = k.KursId
GROUP BY k.KursAdi
ORDER BY KayitSayisi DESC, k.KursAdi;

-- Tahmini ciro: tamamlanan ve aktif kayıtların kurs fiyatları toplamı (iptaller hariç)
SELECT k.Kategori, SUM(k.Fiyat) AS TahminiCiro
FROM dbo.Kayitlar ky
JOIN dbo.Kurslar k ON k.KursId = ky.KursId
WHERE ky.Durum <> N'İptal'
GROUP BY k.Kategori
ORDER BY TahminiCiro DESC;

/* ---------------------------------------------------------------------
   6. HAVING: gruplanmış sonuçları filtreler (WHERE gruplamadan ÖNCE çalışır)
   --------------------------------------------------------------------- */
-- 3 veya daha fazla kaydı olan kurslar
SELECT k.KursAdi, COUNT(*) AS KayitSayisi
FROM dbo.Kayitlar ky
JOIN dbo.Kurslar k ON k.KursId = ky.KursId
GROUP BY k.KursAdi
HAVING COUNT(*) >= 3
ORDER BY KayitSayisi DESC;

-- Puan ortalaması 80'in üzerinde olan eğitmenler
SELECT e.Ad + N' ' + e.Soyad AS Egitmen, AVG(CAST(ky.Puan AS DECIMAL(5,2))) AS PuanOrtalamasi
FROM dbo.Egitmenler e
JOIN dbo.Kurslar  k  ON k.EgitmenId = e.EgitmenId
JOIN dbo.Kayitlar ky ON ky.KursId   = k.KursId
WHERE ky.Puan IS NOT NULL
GROUP BY e.Ad, e.Soyad
HAVING AVG(CAST(ky.Puan AS DECIMAL(5,2))) > 80;

/* ---------------------------------------------------------------------
   7. ROLLUP, GROUPING SETS ve STRING_AGG
   --------------------------------------------------------------------- */
-- ROLLUP: ara toplam ve genel toplam satırları
SELECT ISNULL(k.Kategori, N'GENEL TOPLAM') AS Kategori,
       ISNULL(ky.Durum, N'Tüm durumlar')   AS Durum,
       COUNT(*)                            AS KayitSayisi
FROM dbo.Kayitlar ky
JOIN dbo.Kurslar k ON k.KursId = ky.KursId
GROUP BY ROLLUP (k.Kategori, ky.Durum)
ORDER BY GROUPING(k.Kategori), k.Kategori, GROUPING(ky.Durum), ky.Durum;

-- STRING_AGG (SQL Server 2017+): grup değerlerini tek metinde birleştirir
SELECT k.KursAdi, STRING_AGG(o.Ad + N' ' + o.Soyad, N', ') WITHIN GROUP (ORDER BY o.Soyad) AS Ogrenciler
FROM dbo.Kurslar k
JOIN dbo.Kayitlar  ky ON ky.KursId = k.KursId
JOIN dbo.Ogrenciler o ON o.OgrenciId = ky.OgrenciId
WHERE ky.Durum = N'Aktif'
GROUP BY k.KursAdi;

/* ---------------------------------------------------------------------
   8. Pencere fonksiyonları: satırları gruplamadan hesaplama yapar
   --------------------------------------------------------------------- */
-- Kurs içinde puana göre sıralama
SELECT k.KursAdi, o.Ad + N' ' + o.Soyad AS Ogrenci, ky.Puan,
       ROW_NUMBER() OVER (PARTITION BY k.KursId ORDER BY ky.Puan DESC) AS SiraNo,
       RANK()       OVER (PARTITION BY k.KursId ORDER BY ky.Puan DESC) AS Rank_,
       DENSE_RANK() OVER (PARTITION BY k.KursId ORDER BY ky.Puan DESC) AS DenseRank_
FROM dbo.Kayitlar ky
JOIN dbo.Kurslar    k ON k.KursId    = ky.KursId
JOIN dbo.Ogrenciler o ON o.OgrenciId = ky.OgrenciId
WHERE ky.Puan IS NOT NULL
ORDER BY k.KursAdi, SiraNo;

-- Kurs ortalamasıyla karşılaştırma ve kümülatif sayım
SELECT k.KursAdi, ky.KayitTarihi, ky.Puan,
       AVG(CAST(ky.Puan AS DECIMAL(5,2))) OVER (PARTITION BY k.KursId)              AS KursOrtalamasi,
       ky.Puan - AVG(CAST(ky.Puan AS DECIMAL(5,2))) OVER (PARTITION BY k.KursId)    AS OrtalamaFarki,
       COUNT(*) OVER (ORDER BY ky.KayitId ROWS UNBOUNDED PRECEDING)                 AS KumulatifSayim
FROM dbo.Kayitlar ky
JOIN dbo.Kurslar k ON k.KursId = ky.KursId
WHERE ky.Puan IS NOT NULL
ORDER BY ky.KayitId;

-- LAG: bir önceki kaydın tarihi ve aradaki gün sayısı (öğrenci bazında)
SELECT ky.OgrenciId, ky.KursId, ky.KayitTarihi,
       LAG(ky.KayitTarihi) OVER (PARTITION BY ky.OgrenciId ORDER BY ky.KayitTarihi) AS OncekiKayit,
       DATEDIFF(DAY,
                LAG(ky.KayitTarihi) OVER (PARTITION BY ky.OgrenciId ORDER BY ky.KayitTarihi),
                ky.KayitTarihi) AS GunFarki
FROM dbo.Kayitlar ky
ORDER BY ky.OgrenciId, ky.KayitTarihi;
GO
