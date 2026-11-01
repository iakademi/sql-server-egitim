# 06 - Index ve Performans

İndekslerin sorgu performansını nasıl etkilediğini 100.000 satırlık bir test tablosu üzerinde ölçerek öğrenin.

## Konular

- Clustered ve nonclustered indeks farkı
- Key Lookup ve covering index (`INCLUDE`)
- Filtered index
- Sargable sorgular: sütun üzerinde fonksiyon ve baştaki `%` joker karakterinin etkisi
- `SET STATISTICS IO / TIME` ile ölçüm, Execution Plan okuma
- İndeks ve boyut bilgileri: `sys.indexes`, `sys.dm_db_partition_stats`
- Kullanım istatistikleri: `sys.dm_db_index_usage_stats`, eksik indeks DMV'leri
- Dizin bakımı: `sys.dm_db_index_physical_stats`, `REORGANIZE`, `REBUILD`, `UPDATE STATISTICS`

## Çalıştırma

1. `01` ve `02` betiklerini çalıştırın.
2. SSMS'te `06-index-performans.sql` dosyasını açın ve **Include Actual Execution Plan** (Ctrl+M) seçeneğini etkinleştirin.
3. Bölümleri sırayla çalıştırın; her sorgudan sonra **Messages** sekmesindeki `logical reads` değerlerini ve plan türünü (Scan / Seek) karşılaştırın.

> Betik, `dbo.IslemGunlugu` adlı bir test tablosu oluşturur ve sonunda siler. `NEWID()` ile rastgele veri ürettiği için süreler ve satır dağılımları her çalıştırmada küçük farklılıklar gösterebilir. Yalnızca eğitim ortamında çalıştırın.

## Dosyalar

| Dosya | Açıklama |
|-------|----------|
| `06-index-performans.sql` | Test verisi üretimi, indeks türleri, ölçüm ve bakım sorguları |
