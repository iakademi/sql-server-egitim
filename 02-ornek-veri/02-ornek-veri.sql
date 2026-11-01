/* =====================================================================
   02 - Örnek Veri (INSERT)
   Önce 01-veritabani-ve-tablolar.sql çalıştırılmış olmalıdır.
   Tüm kişi ve e-posta bilgileri KURGUSALDIR (example.com alan adı).

   Not: IDENTITY değerleri 1'den başladığı için aşağıdaki kayıtlarda
        yabancı anahtarlar sıra numaralarıyla yazılmıştır. Betiği yalnızca
        yeni oluşturulmuş boş tablolar üzerinde çalıştırın.
   ===================================================================== */

USE IAkademiDB;
GO

SET NOCOUNT ON;

/* ---------------------------------------------------------------------
   Egitmenler (7 kayıt)
   --------------------------------------------------------------------- */
INSERT INTO dbo.Egitmenler (Ad, Soyad, UzmanlikAlani, Email, IseBaslamaTarihi)
VALUES
    (N'Ahmet',  N'Demir',   N'.NET ve C# ile Yazılım Geliştirme', N'ahmet.demir@example.com',   '2019-02-11'),
    (N'Selin',  N'Arslan',  N'Python ve Veri Analizi',            N'selin.arslan@example.com',  '2020-09-01'),
    (N'Mehmet', N'Kaya',    N'SQL Server ve Veritabanı Yönetimi', N'mehmet.kaya@example.com',   '2018-05-21'),
    (N'Zeynep', N'Aydın',   N'Ağ ve Siber Güvenlik',              N'zeynep.aydin@example.com',  '2021-03-15'),
    (N'Burak',  N'Çelik',   N'Proje Yönetimi (Scrum / PMP)',      N'burak.celik@example.com',   '2017-10-02'),
    (N'Deniz',  N'Yıldız',  N'Ofis ve Power Platform',            N'deniz.yildiz@example.com',  '2022-01-10'),
    (N'Cem',    N'Korkmaz', N'Siber Güvenlik Operasyonları',      N'cem.korkmaz@example.com',   '2024-06-03');   -- henüz kursu yok

/* ---------------------------------------------------------------------
   Kurslar (9 kayıt)
   --------------------------------------------------------------------- */
INSERT INTO dbo.Kurslar (KursAdi, Kategori, SaatSuresi, Fiyat, EgitmenId)
VALUES
    (N'C# ile Programlama',              N'Yazılım',           40, 6500.00, 1),
    (N'ASP.NET Core Web Geliştirme',     N'Yazılım',           48, 7800.00, 1),
    (N'Python ile Programlama',          N'Yazılım',           32, 5200.00, 2),
    (N'Pandas ile Veri Analizi',         N'Veri',              24, 4800.00, 2),
    (N'SQL Server Temelleri',            N'Veritabanı',        36, 5800.00, 3),
    (N'Ağ Temelleri ve Güvenlik',        N'Ağ ve Güvenlik',    40, 6900.00, 4),
    (N'Scrum Temelleri',                 N'Proje Yönetimi',    16, 3900.00, 5),
    (N'Excel ve Power BI',               N'Ofis ve Analitik',  30, 4500.00, 6),
    (N'Power Automate ile Otomasyon',    N'Ofis ve Analitik',  20, 4200.00, 6);   -- henüz kaydı yok

/* ---------------------------------------------------------------------
   Ogrenciler (20 kayıt)
   Son öğrencide doğum tarihi ve şehir bilinmiyor (NULL örneği).
   --------------------------------------------------------------------- */
INSERT INTO dbo.Ogrenciler (Ad, Soyad, Email, DogumTarihi, Sehir, KayitTarihi)
VALUES
    (N'Elif',   N'Yılmaz',  N'elif.yilmaz@example.com',   '1998-03-12', N'İstanbul',  '2025-08-20 10:15:00'),
    (N'Can',    N'Öztürk',  N'can.ozturk@example.com',    '1993-07-25', N'Ankara',    '2025-08-22 14:30:00'),
    (N'Merve',  N'Şahin',   N'merve.sahin@example.com',   '1996-11-02', N'İstanbul',  '2025-09-01 09:00:00'),
    (N'Kaan',   N'Aksoy',   N'kaan.aksoy@example.com',    '2000-01-30', N'İzmir',     '2025-09-03 11:45:00'),
    (N'Deniz',  N'Polat',   N'deniz.polat@example.com',   '1989-05-17', N'Ankara',    '2025-09-10 16:20:00'),
    (N'Sena',   N'Koç',     N'sena.koc@example.com',      '1995-09-08', N'İstanbul',  '2025-09-15 13:10:00'),
    (N'Emre',   N'Güneş',   N'emre.gunes@example.com',    '1992-12-21', N'Bursa',     '2025-09-18 10:00:00'),
    (N'Zehra',  N'Tan',     N'zehra.tan@example.com',     '1999-04-14', N'İstanbul',  '2025-09-25 15:35:00'),
    (N'Oğuz',   N'Erdem',   N'oguz.erdem@example.com',    '1990-08-03', N'Antalya',   '2025-10-01 12:00:00'),
    (N'Büşra',  N'Kılıç',   N'busra.kilic@example.com',   '1997-06-19', N'İzmir',     '2025-10-05 09:40:00'),
    (N'Murat',  N'Doğan',   N'murat.dogan@example.com',   '1985-02-27', N'İstanbul',  '2025-10-07 17:05:00'),
    (N'Ayşe',   N'Çelik',   N'ayse.celik@example.com',    '2001-10-10', N'Eskişehir', '2025-10-09 10:25:00'),
    (N'Tolga',  N'Avcı',    N'tolga.avci@example.com',    '1994-03-05', N'Ankara',    '2025-10-14 14:00:00'),
    (N'Gizem',  N'Yavuz',   N'gizem.yavuz@example.com',   '1998-12-01', N'İstanbul',  '2025-10-16 11:30:00'),
    (N'Barış',  N'Karaca',  N'baris.karaca@example.com',  '1991-07-16', N'Bursa',     '2025-10-21 09:15:00'),
    (N'Naz',    N'Uçar',    N'naz.ucar@example.com',      '2002-05-23', N'İstanbul',  '2025-10-28 16:45:00'),
    (N'Hakan',  N'Bulut',   N'hakan.bulut@example.com',   '1987-09-29', N'İzmir',     '2025-11-02 13:20:00'),
    (N'Ece',    N'Sönmez',  N'ece.sonmez@example.com',    '1996-01-11', N'Ankara',    '2025-11-06 10:50:00'),
    (N'Yusuf',  N'Aslan',   N'yusuf.aslan@example.com',   '1999-08-26', N'İstanbul',  '2025-11-11 15:00:00'),
    (N'Pelin',  N'Taş',     N'pelin.tas@example.com',     NULL,         NULL,         '2025-11-18 12:30:00');   -- hiç kaydı yok

/* ---------------------------------------------------------------------
   Kayitlar (32 kayıt)
   Sütun sırası: OgrenciId, KursId, KayitTarihi, Durum, Puan
   Puan yalnızca 'Tamamlandı' durumunda girilebilir (CHECK kısıtı).
   --------------------------------------------------------------------- */
INSERT INTO dbo.Kayitlar (OgrenciId, KursId, KayitTarihi, Durum, Puan)
VALUES
    ( 1, 1, '2025-09-01', N'Tamamlandı', 88),
    ( 1, 5, '2025-11-03', N'Tamamlandı', 92),
    ( 2, 1, '2025-09-01', N'Tamamlandı', 74),
    ( 2, 3, '2025-12-01', N'Aktif',      NULL),
    ( 3, 3, '2025-10-06', N'Tamamlandı', 95),
    ( 3, 4, '2026-01-12', N'Aktif',      NULL),
    ( 4, 1, '2025-09-01', N'Tamamlandı', 61),
    ( 4, 2, '2026-01-19', N'Aktif',      NULL),
    ( 5, 7, '2025-10-13', N'Tamamlandı', 85),
    ( 5, 6, '2025-11-17', N'İptal',      NULL),
    ( 6, 3, '2025-10-06', N'Tamamlandı', 79),
    ( 6, 1, '2026-02-02', N'Aktif',      NULL),
    ( 7, 5, '2025-11-03', N'Tamamlandı', 67),
    ( 8, 8, '2025-10-20', N'Tamamlandı', 90),
    ( 8, 3, '2026-01-12', N'Aktif',      NULL),
    ( 9, 6, '2025-11-17', N'Tamamlandı', 72),
    (10, 8, '2025-10-20', N'Tamamlandı', 84),
    (10, 5, '2026-01-26', N'Aktif',      NULL),
    (11, 7, '2025-10-13', N'Tamamlandı', 91),
    (11, 6, '2026-02-09', N'Aktif',      NULL),
    (12, 3, '2025-10-06', N'Tamamlandı', 58),
    (13, 2, '2026-01-19', N'Aktif',      NULL),
    (13, 5, '2025-11-03', N'Tamamlandı', 81),
    (14, 4, '2026-01-12', N'Aktif',      NULL),
    (14, 8, '2025-10-20', N'Tamamlandı', 96),
    (15, 1, '2025-09-01', N'Tamamlandı', 70),
    (16, 3, '2025-12-01', N'İptal',      NULL),
    (17, 5, '2025-11-03', N'Tamamlandı', 77),
    (17, 7, '2025-10-13', N'Tamamlandı', 89),
    (18, 8, '2026-02-16', N'Aktif',      NULL),
    (19, 2, '2026-01-19', N'Aktif',      NULL),
    (19, 1, '2025-09-01', N'Tamamlandı', 93);
GO

/* ---------------------------------------------------------------------
   Doğrulama: beklenen satır sayıları 7 / 9 / 20 / 32
   --------------------------------------------------------------------- */
SELECT N'Egitmenler' AS Tablo, COUNT(*) AS SatirSayisi FROM dbo.Egitmenler
UNION ALL SELECT N'Kurslar',    COUNT(*) FROM dbo.Kurslar
UNION ALL SELECT N'Ogrenciler', COUNT(*) FROM dbo.Ogrenciler
UNION ALL SELECT N'Kayitlar',   COUNT(*) FROM dbo.Kayitlar;
GO
