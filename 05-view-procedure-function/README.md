# 05 - View, Procedure, Function ve Trigger

Veritabanı nesneleriyle iş mantığını sunucu tarafında paketleme.

## Konular

- **View:** `CREATE OR ALTER VIEW`, `WITH SCHEMABINDING`, `WITH CHECK OPTION`
- **Fonksiyon:** skaler (`fn_YasHesapla`, `fn_HarfNotu`) ve inline tablo değerli fonksiyon (`fn_OgrenciKurslari`), `CROSS APPLY` ile kullanım
- **Stored procedure:** parametreler, varsayılan değerler, `OUTPUT` parametresi, `SCOPE_IDENTITY()`, `THROW` ile iş kuralı denetimi, `TRY...CATCH`
- **Trigger:** `AFTER UPDATE`, `inserted` / `deleted` sanal tabloları, denetim (audit) kaydı

## Oluşturulan Nesneler

| Tür | Ad |
|-----|----|
| View | `vw_KursOzet`, `vw_OgrenciKayitDetay`, `vw_AktifKayitlar` |
| Function | `fn_YasHesapla`, `fn_HarfNotu`, `fn_OgrenciKurslari` |
| Procedure | `usp_KursRaporu`, `usp_OgrenciKayitEkle`, `usp_PuanGir` |
| Trigger | `trg_Kayitlar_DurumLog` (log tablosu: `KayitDurumLog`) |

## Çalıştırma

`01` ve `02` modüllerinden sonra `05-view-procedure-function.sql` dosyasını SSMS veya Azure Data Studio'da çalıştırın. `CREATE OR ALTER` söz dizimi SQL Server 2016 SP1 ve üzerini gerektirir; betik tekrar çalıştırılabilir.

```bash
sqlcmd -S localhost -E -d IAkademiDB -i 05-view-procedure-function.sql
```

Betiğin sonundaki deneme verisi temizlenir; Kayitlar tablosu ilk haline döner.

## Dosyalar

| Dosya | Açıklama |
|-------|----------|
| `05-view-procedure-function.sql` | View, fonksiyon, yordam ve trigger örnekleri |
