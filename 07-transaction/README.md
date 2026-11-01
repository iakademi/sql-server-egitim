# 07 - Transaction

Birden fazla adımdan oluşan işlemleri güvenli ve tutarlı şekilde yürütme.

## Konular

- ACID ilkeleri
- `BEGIN TRANSACTION`, `COMMIT`, `ROLLBACK`, `@@TRANCOUNT`
- `TRY...CATCH`, `XACT_STATE()`, `SET XACT_ABORT ON`, `THROW`
- İş senaryosu: öğrenciyi bir kurstan diğerine taşıyan atomik yordam
- İç içe işlemler ve `SAVE TRANSACTION` (savepoint)
- İzolasyon seviyeleri: `READ UNCOMMITTED`, `READ COMMITTED`, `REPEATABLE READ`, `SERIALIZABLE`, `SNAPSHOT`
- Kirli okuma, tekrarlanamayan okuma ve hayalet satır deneyleri (iki oturumla)
- Kilit ve bloklama izleme DMV'leri
- Deadlock'un nedeni, önlenmesi ve yeniden deneme (retry) deseni

## Çalıştırma

`01` ve `02` betikleri çalıştırıldıktan sonra `07-transaction.sql` dosyasını SSMS veya Azure Data Studio'da bölüm bölüm çalıştırın.

- 1.-5. ve 7.-8. bölümler tek oturumda çalışır; veriyi değiştirseler de sonunda geri alırlar.
- 6. bölümdeki deneyler **iki ayrı sorgu penceresi** gerektirir. Yorum satırlarındaki adımları belirtilen oturum sırasıyla uygulayın ve deney sonunda `ROLLBACK` yapmayı unutmayın.

```bash
sqlcmd -S localhost -E -d IAkademiDB -i 07-transaction.sql
```

## Dosyalar

| Dosya | Açıklama |
|-------|----------|
| `07-transaction.sql` | Transaction örnekleri, izolasyon deneyleri ve deadlock yönetimi |
