/* =====================================================================
   07 - Transaction (İşlem) Yönetimi
   Konular: ACID, BEGIN TRAN / COMMIT / ROLLBACK, @@TRANCOUNT,
            TRY...CATCH + XACT_STATE, SET XACT_ABORT, savepoint,
            izolasyon seviyeleri, kilitler, deadlock
   Önce 01 ve 02 betikleri çalıştırılmış olmalıdır.
   Bu betikteki örnekler, veriyi ilk haline döndürecek şekilde yazılmıştır.
   ===================================================================== */

USE IAkademiDB;
GO

/* ---------------------------------------------------------------------
   ACID özeti
   Atomicity   (Bölünmezlik) : İşlemin tüm adımları ya birlikte uygulanır ya da hiçbiri.
   Consistency (Tutarlılık)  : İşlem, veritabanını tutarlı bir durumdan başka bir tutarlı duruma taşır.
   Isolation   (Yalıtım)     : Eşzamanlı işlemler birbirinin ara durumunu görmez.
   Durability  (Kalıcılık)   : Onaylanan (commit) veri, sistem çökse bile kaybolmaz.
   --------------------------------------------------------------------- */

/* ---------------------------------------------------------------------
   1. Temel: BEGIN TRANSACTION, COMMIT ve ROLLBACK
   --------------------------------------------------------------------- */
SELECT KursId, KursAdi, Fiyat FROM dbo.Kurslar WHERE Kategori = N'Yazılım';

BEGIN TRANSACTION;

    UPDATE dbo.Kurslar SET Fiyat = Fiyat * 1.10 WHERE Kategori = N'Yazılım';
    SELECT @@TRANCOUNT AS AcikIslemSayisi;                           -- 1
    SELECT KursId, KursAdi, Fiyat FROM dbo.Kurslar WHERE Kategori = N'Yazılım';   -- değişiklik bu oturumda görünür

ROLLBACK TRANSACTION;                                                -- her şey geri alındı

SELECT KursId, KursAdi, Fiyat FROM dbo.Kurslar WHERE Kategori = N'Yazılım';       -- eski fiyatlar
GO

/* ---------------------------------------------------------------------
   2. TRY...CATCH ile güvenli işlem şablonu
      Senaryo: Bir öğrenciyi bir kurstan başka bir kursa taşımak.
        Adım 1) Eski kaydı 'İptal' yap
        Adım 2) Yeni kursa kayıt oluştur
      İkisinden biri başarısız olursa her ikisi de geri alınmalıdır.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.usp_KursDegistir
    @OgrenciId   INT,
    @EskiKursId  INT,
    @YeniKursId  INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;      -- çalışma zamanı hatasında işlem otomatik geri alınır

    BEGIN TRY
        BEGIN TRANSACTION;

            UPDATE dbo.Kayitlar
            SET Durum = N'İptal', Puan = NULL
            WHERE OgrenciId = @OgrenciId AND KursId = @EskiKursId AND Durum = N'Aktif';

            IF @@ROWCOUNT = 0
                THROW 51001, N'Taşınacak aktif kayıt bulunamadı.', 1;

            -- Aynı kursa tekrar kayıt UNIQUE kısıtını ihlal eder -> CATCH bloğuna düşer
            INSERT INTO dbo.Kayitlar (OgrenciId, KursId, Durum)
            VALUES (@OgrenciId, @YeniKursId, N'Aktif');

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- XACT_STATE(): 1 = onaylanabilir, -1 = onaylanamaz (yalnızca ROLLBACK), 0 = açık işlem yok
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        THROW;   -- hatayı çağırana olduğu gibi ilet
    END CATCH;
END;
GO

-- Başarılı senaryo: öğrenci 6'nın aktif C# kaydı (kurs 1) iptal edilir ve SQL Server kursuna (kurs 5) kayıt açılır
BEGIN TRANSACTION;                          -- dışarıdan sarmalayıp sonunda geri alacağız (veri değişmesin)
    EXEC dbo.usp_KursDegistir @OgrenciId = 6, @EskiKursId = 1, @YeniKursId = 5;
    SELECT KayitId, OgrenciId, KursId, Durum FROM dbo.Kayitlar WHERE OgrenciId = 6 ORDER BY KursId;
ROLLBACK TRANSACTION;
GO

-- Başarısız senaryo: öğrenci 6 zaten Python kursuna (kurs 3) kayıtlı -> UNIQUE ihlali, eski kayıt da geri alınır
BEGIN TRY
    EXEC dbo.usp_KursDegistir @OgrenciId = 6, @EskiKursId = 1, @YeniKursId = 3;
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS HataNo, ERROR_MESSAGE() AS Mesaj;
END CATCH;

-- Eski kayıt hâlâ 'Aktif' olmalıdır:
SELECT KayitId, KursId, Durum FROM dbo.Kayitlar WHERE OgrenciId = 6 AND KursId = 1;
GO

/* ---------------------------------------------------------------------
   3. İç içe işlemler ve @@TRANCOUNT
      İç COMMIT yalnızca sayacı azaltır; gerçek onay en dıştaki COMMIT ile olur.
      ROLLBACK ise (savepoint yoksa) tüm işlemleri geri alır.
   --------------------------------------------------------------------- */
BEGIN TRAN;                                       -- @@TRANCOUNT = 1
    BEGIN TRAN;                                   -- @@TRANCOUNT = 2
        SELECT @@TRANCOUNT AS IcIslemde;
    COMMIT;                                       -- @@TRANCOUNT = 1 (henüz kalıcı değil)
    SELECT @@TRANCOUNT AS DisIslemde;
ROLLBACK;                                         -- @@TRANCOUNT = 0
SELECT @@TRANCOUNT AS Bitti;
GO

/* ---------------------------------------------------------------------
   4. Savepoint: işlemin yalnızca bir kısmını geri alma
   --------------------------------------------------------------------- */
BEGIN TRANSACTION;

    UPDATE dbo.Kurslar SET Fiyat = Fiyat + 100 WHERE KursId = 1;       -- kalıcı kalacak adım

    SAVE TRANSACTION OnemliNokta;

    UPDATE dbo.Kurslar SET Fiyat = Fiyat + 100000 WHERE KursId = 1;    -- hatalı adım
    SELECT Fiyat AS HataliFiyat FROM dbo.Kurslar WHERE KursId = 1;

    ROLLBACK TRANSACTION OnemliNokta;                                  -- yalnızca savepoint sonrası geri alınır
    SELECT Fiyat AS DuzeltilmisFiyat FROM dbo.Kurslar WHERE KursId = 1;

ROLLBACK TRANSACTION;   -- demo verisini tamamen geri al (gerçek senaryoda COMMIT kullanılır)
GO

/* ---------------------------------------------------------------------
   5. Hata sonrası işlem durumu: XACT_ABORT OFF/ON farkı
   --------------------------------------------------------------------- */
SET XACT_ABORT OFF;
BEGIN TRY
    BEGIN TRANSACTION;
        INSERT INTO dbo.Kurslar (KursAdi, Kategori, SaatSuresi, Fiyat, EgitmenId)
        VALUES (N'Geçici Kurs', N'Deneme', 10, 1000, 999);            -- yok olan eğitmen -> yabancı anahtar hatası
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    PRINT N'Hata yakalandı: ' + ERROR_MESSAGE();
    PRINT N'XACT_STATE = ' + CAST(XACT_STATE() AS NVARCHAR(5)) + N', @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS NVARCHAR(5));
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
END CATCH;
GO

/* ---------------------------------------------------------------------
   6. İzolasyon seviyeleri
      Aşağıdaki deneyler İKİ AYRI SORGU PENCERESİ (oturum) gerektirir.
      Yorum satırlarındaki adımları belirtilen sırayla çalıştırın.
   --------------------------------------------------------------------- */

-- Mevcut izolasyon seviyesi (varsayılan: READ COMMITTED)
DBCC USEROPTIONS;
GO

/* --- Deney A: Kirli okuma (dirty read) ve READ UNCOMMITTED --------------
   Oturum 1:
       BEGIN TRAN;
       UPDATE dbo.Kurslar SET Fiyat = 1 WHERE KursId = 1;       -- onaylanmadı!
   Oturum 2:
       SELECT Fiyat FROM dbo.Kurslar WHERE KursId = 1;           -- BEKLER (READ COMMITTED, satır kilitli)
       SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
       SELECT Fiyat FROM dbo.Kurslar WHERE KursId = 1;           -- 1 döner (kirli okuma!)
       -- Aynı etki: SELECT Fiyat FROM dbo.Kurslar WITH (NOLOCK) WHERE KursId = 1;
   Oturum 1:
       ROLLBACK;                                                 -- Oturum 2'nin okuduğu değer hiç var olmamıştı
   ----------------------------------------------------------------------- */

/* --- Deney B: Tekrarlanamayan okuma (non-repeatable read) ---------------
   Oturum 1 (READ COMMITTED):
       BEGIN TRAN;
       SELECT Fiyat FROM dbo.Kurslar WHERE KursId = 1;           -- ilk okuma
   Oturum 2:
       UPDATE dbo.Kurslar SET Fiyat = Fiyat + 50 WHERE KursId = 1;   -- hemen tamamlanır
   Oturum 1:
       SELECT Fiyat FROM dbo.Kurslar WHERE KursId = 1;           -- farklı değer! (non-repeatable read)
       ROLLBACK;
   Oturum 2 (deneyi eski haline döndürmek için):
       UPDATE dbo.Kurslar SET Fiyat = Fiyat - 50 WHERE KursId = 1;
   REPEATABLE READ seviyesinde Oturum 1 satırı kilitli tutar; Oturum 2'nin UPDATE'i bekler.
   ----------------------------------------------------------------------- */

/* --- Deney C: Hayalet satır (phantom) ve SERIALIZABLE -------------------
   Oturum 1:
       SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
       BEGIN TRAN;
       SELECT COUNT(*) FROM dbo.Kurslar WHERE Fiyat BETWEEN 4000 AND 5000;
   Oturum 2:
       INSERT INTO dbo.Kurslar (KursAdi, Kategori, SaatSuresi, Fiyat, EgitmenId)
       VALUES (N'Hayalet Kurs', N'Deneme', 8, 4500, 1);          -- BEKLER (aralık kilitli)
   Oturum 1:
       ROLLBACK;                                                 -- Oturum 2'nin INSERT'ü şimdi tamamlanır
   Oturum 2: DELETE FROM dbo.Kurslar WHERE KursAdi = N'Hayalet Kurs';   -- temizlik
   ----------------------------------------------------------------------- */

-- SNAPSHOT izolasyonu: okuyucular yazıcıları, yazıcılar okuyucuları bloklamaz (satır sürümleme, tempdb kullanır)
-- ALTER DATABASE IAkademiDB SET ALLOW_SNAPSHOT_ISOLATION ON;
-- ALTER DATABASE IAkademiDB SET READ_COMMITTED_SNAPSHOT ON WITH ROLLBACK IMMEDIATE;   -- varsayılan READ COMMITTED davranışını sürümlemeli hale getirir

/* ---------------------------------------------------------------------
   7. Kilitleri ve bekleyen oturumları izleme
   --------------------------------------------------------------------- */
-- Açık işlemler
SELECT s.session_id, s.login_name, t.transaction_id, t.name, t.transaction_begin_time
FROM sys.dm_tran_session_transactions st
JOIN sys.dm_exec_sessions s       ON s.session_id = st.session_id
JOIN sys.dm_tran_active_transactions t ON t.transaction_id = st.transaction_id
WHERE s.is_user_process = 1;

-- Bu veritabanındaki mevcut kilitler
SELECT request_session_id AS Oturum, resource_type AS KaynakTuru, request_mode AS Mod, request_status AS Durum
FROM sys.dm_tran_locks
WHERE resource_database_id = DB_ID()
ORDER BY request_session_id;

-- Başka bir oturum tarafından bloklanan istekler
SELECT r.session_id AS BeklayanOturum, r.blocking_session_id AS BloklayanOturum, r.wait_type, r.wait_time
FROM sys.dm_exec_requests r
WHERE r.blocking_session_id <> 0;
GO

/* ---------------------------------------------------------------------
   8. Deadlock (kilitlenme) nedir, nasıl önlenir?
      İki oturum, birbirinin kilitli olduğu kaynağı beklerse SQL Server birini
      "kurban" seçip hata 1205 ile sonlandırır.

      Oturum 1:                                  Oturum 2:
        BEGIN TRAN;                                BEGIN TRAN;
        UPDATE Kurslar  ... KursId = 1;            UPDATE Egitmenler ... EgitmenId = 1;
        -- (bekle)                                 -- (bekle)
        UPDATE Egitmenler ... EgitmenId = 1;       UPDATE Kurslar ... KursId = 1;   -> DEADLOCK

      Önlemek için:
        - Tabloları HER ZAMAN aynı sırayla güncelleyin.
        - İşlemleri kısa tutun; kullanıcı etkileşimini işlem içinde beklemeyin.
        - Uygun indekslerle kilitlenen satır sayısını azaltın.
        - Gerekirse SNAPSHOT / RCSI kullanın.
        - Uygulamada 1205 hatasında işlemi kısa bir bekleme ile yeniden deneyin.
   --------------------------------------------------------------------- */

-- Yeniden deneme (retry) deseni: deadlock kurbanı olunursa en fazla 3 kez tekrar dener
DECLARE @Deneme INT = 1, @MaksDeneme INT = 3, @Bitti BIT = 0;

WHILE @Bitti = 0 AND @Deneme <= @MaksDeneme
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            UPDATE dbo.Kurslar SET Fiyat = Fiyat WHERE KursId = 1;     -- gerçek iş burada yapılır
        COMMIT TRANSACTION;

        SET @Bitti = 1;
        PRINT N'İşlem ' + CAST(@Deneme AS NVARCHAR(5)) + N'. denemede tamamlandı.';
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;

        IF ERROR_NUMBER() = 1205 AND @Deneme < @MaksDeneme
        BEGIN
            SET @Deneme += 1;
            WAITFOR DELAY '00:00:01';          -- kısa bekleyip yeniden dene
        END
        ELSE
            THROW;
    END CATCH;
END;
GO

/* ---------------------------------------------------------------------
   9. Temizlik
   --------------------------------------------------------------------- */
DROP PROCEDURE IF EXISTS dbo.usp_KursDegistir;
GO
