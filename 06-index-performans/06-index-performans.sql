/* =====================================================================
   06 - Index (Dizin) ve Performans
   Konular: clustered / nonclustered index, covering index (INCLUDE),
            filtered index, sargable sorgular, istatistikler, execution plan,
            dizin bakımı, dizin kullanım bilgileri

   Bu betik, etkileri ölçebilmek için 100.000 satırlık bir test tablosu
   (dbo.IslemGunlugu) oluşturur. Yalnızca eğitim ortamında çalıştırın.
   Ölçüm için SSMS'te "Include Actual Execution Plan" (Ctrl+M) seçeneğini açın.
   ===================================================================== */

USE IAkademiDB;
GO

/* ---------------------------------------------------------------------
   1. Test tablosu ve verisi (indeks yok; yalnızca clustered PK)
   --------------------------------------------------------------------- */
DROP TABLE IF EXISTS dbo.IslemGunlugu;
GO

CREATE TABLE dbo.IslemGunlugu
(
    IslemId      INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_IslemGunlugu PRIMARY KEY CLUSTERED,
    OgrenciId    INT           NOT NULL,
    IslemTipi    NVARCHAR(20)  NOT NULL,
    IslemTarihi  DATETIME2(0)  NOT NULL,
    Tutar        DECIMAL(10,2) NOT NULL,
    Aciklama     NVARCHAR(200) NULL
);
GO

-- sys.all_objects tablosunun kendisiyle çarpımı (CROSS JOIN) ile hızlıca 100.000 satır üretilir
INSERT INTO dbo.IslemGunlugu (OgrenciId, IslemTipi, IslemTarihi, Tutar, Aciklama)
SELECT TOP (100000)
       (CHECKSUM(NEWID()) & 0x7FFFFFFF) % 20 + 1,
       CHOOSE((CHECKSUM(NEWID()) & 0x7FFFFFFF) % 4 + 1, N'Giriş', N'Ödeme', N'İndirme', N'Sınav'),
       DATEADD(MINUTE, -((CHECKSUM(NEWID()) & 0x7FFFFFFF) % 525600), SYSDATETIME()),   -- son 1 yıl
       CAST((CHECKSUM(NEWID()) & 0x7FFFFFFF) % 100000 AS DECIMAL(10,2)) / 100,
       N'Otomatik üretilen test kaydı'
FROM sys.all_objects a
CROSS JOIN sys.all_objects b;
GO

SELECT COUNT(*) AS SatirSayisi FROM dbo.IslemGunlugu;
GO

/* ---------------------------------------------------------------------
   2. İndeks olmadan: tablo taraması (Clustered Index Scan)
   --------------------------------------------------------------------- */
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- Mesajlar sekmesinde "logical reads" değerini not edin
SELECT IslemId, IslemTarihi, Tutar
FROM dbo.IslemGunlugu
WHERE OgrenciId = 7 AND IslemTipi = N'Ödeme';
GO

/* ---------------------------------------------------------------------
   3. Nonclustered index
   --------------------------------------------------------------------- */
CREATE NONCLUSTERED INDEX IX_IslemGunlugu_OgrenciId
ON dbo.IslemGunlugu (OgrenciId);
GO

-- Aynı sorgu: artık Index Seek + Key Lookup görülür; logical reads belirgin şekilde düşer
SELECT IslemId, IslemTarihi, Tutar
FROM dbo.IslemGunlugu
WHERE OgrenciId = 7 AND IslemTipi = N'Ödeme';
GO

/* ---------------------------------------------------------------------
   4. Covering index (INCLUDE): Key Lookup'ı ortadan kaldırır
      Anahtar sütunlar eşitlik/aralık aramaları içindir,
      INCLUDE sütunları yalnızca SELECT listesindeki değerler içindir.
   --------------------------------------------------------------------- */
CREATE NONCLUSTERED INDEX IX_IslemGunlugu_Ogrenci_Tip_Kapsayan
ON dbo.IslemGunlugu (OgrenciId, IslemTipi)
INCLUDE (IslemTarihi, Tutar);
GO

SELECT IslemId, IslemTarihi, Tutar
FROM dbo.IslemGunlugu
WHERE OgrenciId = 7 AND IslemTipi = N'Ödeme';     -- yalnızca Index Seek, lookup yok
GO

-- Artık gereksiz olan tek sütunlu indeks kaldırılır (yazma maliyetini düşürür)
DROP INDEX IX_IslemGunlugu_OgrenciId ON dbo.IslemGunlugu;
GO

/* ---------------------------------------------------------------------
   5. Sargable (Search ARGument ABLE) sorgular
      Sütun üzerinde fonksiyon kullanmak indeks aramasını engeller.
   --------------------------------------------------------------------- */
CREATE NONCLUSTERED INDEX IX_IslemGunlugu_IslemTarihi
ON dbo.IslemGunlugu (IslemTarihi) INCLUDE (Tutar);
GO

-- KÖTÜ: sütun fonksiyon içinde -> Index Scan
SELECT SUM(Tutar) AS Toplam
FROM dbo.IslemGunlugu
WHERE YEAR(IslemTarihi) = YEAR(SYSDATETIME()) AND MONTH(IslemTarihi) = MONTH(SYSDATETIME());

-- İYİ: aralık koşulu -> Index Seek
DECLARE @AyBasi DATETIME2(0) = DATEFROMPARTS(YEAR(SYSDATETIME()), MONTH(SYSDATETIME()), 1);
SELECT SUM(Tutar) AS Toplam
FROM dbo.IslemGunlugu
WHERE IslemTarihi >= @AyBasi AND IslemTarihi < DATEADD(MONTH, 1, @AyBasi);

-- KÖTÜ: baştaki % joker karakteri dizin kullanımını engeller
SELECT COUNT(*) FROM dbo.Ogrenciler WHERE Email LIKE N'%@example.com';
-- İYİ: önek araması dizin kullanabilir (Email sütununda UNIQUE indeks vardır)
SELECT COUNT(*) FROM dbo.Ogrenciler WHERE Email LIKE N'elif%';
GO

/* ---------------------------------------------------------------------
   6. Filtered index: yalnızca belirli satırları indeksler (küçük ve hızlı)
   --------------------------------------------------------------------- */
CREATE NONCLUSTERED INDEX IX_IslemGunlugu_Odemeler
ON dbo.IslemGunlugu (IslemTarihi, OgrenciId)
INCLUDE (Tutar)
WHERE IslemTipi = N'Ödeme';
GO

SELECT OgrenciId, SUM(Tutar) AS ToplamOdeme
FROM dbo.IslemGunlugu
WHERE IslemTipi = N'Ödeme' AND IslemTarihi >= DATEADD(DAY, -30, SYSDATETIME())
GROUP BY OgrenciId;
GO

/* ---------------------------------------------------------------------
   7. Mevcut indeksleri ve boyutlarını inceleme
   --------------------------------------------------------------------- */
SELECT i.name AS IndeksAdi,
       i.type_desc AS Tur,
       i.is_unique AS Benzersiz,
       i.has_filter AS Filtreli,
       STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN c.name END, N', ')
           WITHIN GROUP (ORDER BY ic.key_ordinal) AS AnahtarSutunlar,
       STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN c.name END, N', ') AS DahilSutunlar
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns c        ON c.object_id = ic.object_id AND c.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'dbo.IslemGunlugu')
GROUP BY i.name, i.type_desc, i.is_unique, i.has_filter;

-- Sayfa sayısı ve boyut (MB)
SELECT i.name AS IndeksAdi,
       SUM(ps.used_page_count) AS KullanilanSayfa,
       CAST(SUM(ps.used_page_count) * 8 / 1024.0 AS DECIMAL(10,2)) AS BoyutMB
FROM sys.dm_db_partition_stats ps
JOIN sys.indexes i ON i.object_id = ps.object_id AND i.index_id = ps.index_id
WHERE ps.object_id = OBJECT_ID(N'dbo.IslemGunlugu')
GROUP BY i.name;
GO

/* ---------------------------------------------------------------------
   8. İndeks kullanım istatistikleri (sunucu yeniden başlayana kadar birikir)
      Seek/scan/lookup sayıları yüksek, update sayısı çok yüksek ve
      okuması olmayan indeksler kaldırma adayıdır.
   --------------------------------------------------------------------- */
SELECT i.name AS IndeksAdi,
       us.user_seeks, us.user_scans, us.user_lookups, us.user_updates
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats us
       ON us.object_id = i.object_id AND us.index_id = i.index_id AND us.database_id = DB_ID()
WHERE i.object_id = OBJECT_ID(N'dbo.IslemGunlugu') AND i.name IS NOT NULL;

-- SQL Server'ın önerdiği eksik indeksler (öneriler körü körüne uygulanmamalı, incelenmelidir)
SELECT TOP (5)
       mid.statement AS Tablo, mid.equality_columns, mid.inequality_columns, mid.included_columns,
       migs.user_seeks, migs.avg_user_impact
FROM sys.dm_db_missing_index_details mid
JOIN sys.dm_db_missing_index_groups mig ON mig.index_handle = mid.index_handle
JOIN sys.dm_db_missing_index_group_stats migs ON migs.group_handle = mig.index_group_handle
WHERE mid.database_id = DB_ID()
ORDER BY migs.user_seeks * migs.avg_user_impact DESC;
GO

/* ---------------------------------------------------------------------
   9. Dizin bakımı: parçalanma (fragmentation) ve istatistikler
   --------------------------------------------------------------------- */
SELECT i.name AS IndeksAdi, ps.avg_fragmentation_in_percent AS ParcalanmaYuzdesi, ps.page_count AS SayfaSayisi
FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID(N'dbo.IslemGunlugu'), NULL, NULL, 'LIMITED') ps
JOIN sys.indexes i ON i.object_id = ps.object_id AND i.index_id = ps.index_id
WHERE i.name IS NOT NULL;

-- Genel kural: %5-30 arası REORGANIZE, %30 üzeri REBUILD
ALTER INDEX IX_IslemGunlugu_IslemTarihi ON dbo.IslemGunlugu REORGANIZE;
ALTER INDEX ALL ON dbo.IslemGunlugu REBUILD;

-- İstatistikler sorgu planı seçimini etkiler
UPDATE STATISTICS dbo.IslemGunlugu WITH FULLSCAN;
GO

/* ---------------------------------------------------------------------
   10. Diğer performans ipuçları
   --------------------------------------------------------------------- */
-- SELECT * yerine yalnızca gereken sütunları seçin (covering index imkânı doğar)
-- EXISTS, büyük kümelerde IN'e göre çoğu zaman daha verimlidir
-- Gereksiz DISTINCT ve ORDER BY kullanmayın; sıralama maliyetlidir
-- Çok sayıda satırı toplu işlerken tek tek döngü yerine küme tabanlı (set-based) sorgu yazın
-- Gerçek plan: SSMS > Query > Include Actual Execution Plan

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

/* ---------------------------------------------------------------------
   11. Temizlik
   --------------------------------------------------------------------- */
DROP TABLE IF EXISTS dbo.IslemGunlugu;
GO
