# 02 - Örnek Veri

`IAkademiDB` tablolarını eğitim için kurgusal verilerle doldurur.

## Konular

- `INSERT INTO ... VALUES` ile çok satırlı veri ekleme
- Unicode metin için `N'...'` ön eki (Türkçe karakterler)
- `NULL` değerlerin eklenmesi
- Yabancı anahtar sırası: önce üst tablolar (Egitmenler, Kurslar, Ogrenciler), sonra Kayitlar
- `CHECK` kısıtlarına uygun veri girişi
- `UNION ALL` ile satır sayısı doğrulaması

## Veri Seti

| Tablo | Satır | Not |
|-------|-------|-----|
| Egitmenler | 7 | Bir eğitmenin henüz kursu yok (LEFT/RIGHT JOIN örnekleri için) |
| Kurslar | 9 | Bir kursun henüz kaydı yok |
| Ogrenciler | 20 | Bir öğrencinin kaydı ve doğum tarihi/şehri yok (NULL örnekleri) |
| Kayitlar | 32 | Aktif, Tamamlandı ve İptal durumları |

Tüm isimler ve `example.com` e-posta adresleri kurgusaldır; gerçek kişileri temsil etmez. Fiyatlar yalnızca örnek değerlerdir.

## Çalıştırma

Önce `01-veritabani-olusturma` modülündeki betiği çalıştırın, ardından:

```bash
sqlcmd -S localhost -E -i 02-ornek-veri.sql
```

> Betik boş tablolar için tasarlanmıştır. Tekrar çalıştırmak için `01` betiğiyle veritabanını yeniden oluşturun.

## Dosyalar

| Dosya | Açıklama |
|-------|----------|
| `02-ornek-veri.sql` | Dört tabloya örnek veri ekleme ve doğrulama sorgusu |
