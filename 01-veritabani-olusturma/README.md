# 01 - Veritabanı Oluşturma

Eğitim boyunca kullanılacak **IAkademiDB** örnek veritabanının şemasını oluşturur.

## Konular

- `CREATE DATABASE` ve Türkçe `COLLATE` ayarı (`Turkish_CI_AS`)
- `CREATE TABLE`, veri tipleri (`INT`, `NVARCHAR`, `DECIMAL`, `DATE`, `DATETIME2`, `TINYINT`)
- `IDENTITY`, `PRIMARY KEY`, `UNIQUE`, `DEFAULT`, `CHECK`, `FOREIGN KEY` kısıtları
- Çoka-çok ilişkinin ara tabloyla (Kayitlar) modellenmesi
- Yabancı anahtar sütunları için dizin oluşturma
- Sistem katalog görünümleriyle (`sys.tables`, `sys.columns`) şemayı sorgulama

## Şema Özeti

```text
Egitmenler (EgitmenId PK) 1 ───< Kurslar (KursId PK, EgitmenId FK)
Ogrenciler (OgrenciId PK) 1 ───< Kayitlar >─── 1 Kurslar
                                 (OgrenciId FK, KursId FK, Durum, Puan)
```

## Çalıştırma

SSMS veya Azure Data Studio'da `01-veritabani-ve-tablolar.sql` dosyasını açıp tamamını çalıştırın. Komut satırından:

```bash
sqlcmd -S localhost -E -i 01-veritabani-ve-tablolar.sql
```

> Betik varsa mevcut `IAkademiDB` veritabanını siler. Yalnızca eğitim ortamında çalıştırın.

## Dosyalar

| Dosya | Açıklama |
|-------|----------|
| `01-veritabani-ve-tablolar.sql` | Veritabanı, dört tablo, kısıtlar ve dizinler |
