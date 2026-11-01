# 03 - SELECT Sorguları

Tek tablo üzerinde veri sorgulamanın temelleri.

## Konular

- `SELECT`, sütun takma adları (`AS`) ve hesaplanan sütunlar
- `WHERE`: karşılaştırma, `AND/OR`, `IN`, `BETWEEN`, `LIKE`
- `NULL` mantığı: `IS NULL`, `ISNULL`, `COALESCE`
- `ORDER BY`, `TOP`, `TOP ... WITH TIES`, `DISTINCT`
- `OFFSET ... FETCH` ile sayfalama
- `CASE`, `IIF`, `CHOOSE`
- Metin fonksiyonları: `CONCAT`, `LEFT`, `SUBSTRING`, `CHARINDEX`, `REPLACE`, `UPPER`
- Tarih fonksiyonları: `DATEDIFF`, `DATEADD`, `DATENAME`, `EOMONTH`, `FORMAT`
- Sayısal fonksiyonlar ve `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`

## Çalıştırma

`01` ve `02` modüllerindeki betikler çalıştırıldıktan sonra `03-select-sorgulari.sql` dosyasını SSMS veya Azure Data Studio'da açın. Sorguları tek tek seçip (F5 / Ctrl+E) çalıştırarak sonuçları inceleyin.

```bash
sqlcmd -S localhost -E -d IAkademiDB -i 03-select-sorgulari.sql
```

## Dosyalar

| Dosya | Açıklama |
|-------|----------|
| `03-select-sorgulari.sql` | Dokuz bölümlük, açıklamalı sorgu örnekleri |
