# SQL Server Eğitimi (T-SQL)

![SQL Server](https://img.shields.io/badge/SQL%20Server-2017%2B-CC2927?logo=microsoftsqlserver&logoColor=white)
![T-SQL](https://img.shields.io/badge/dil-T--SQL-blue)
![Seviye](https://img.shields.io/badge/seviye-ba%C5%9Flang%C4%B1%C3%A7%20%E2%86%92%20orta-blue)
![Dil](https://img.shields.io/badge/dil-T%C3%BCrk%C3%A7e-red)
![Lisans](https://img.shields.io/badge/lisans-MIT-green)

Microsoft SQL Server ve T-SQL'i örnek bir eğitim veritabanı (**IAkademiDB**) üzerinden adım adım öğrenmek için hazırlanmış, Türkçe açıklamalı betikler.

## Hakkında

Bu depo, **İ-Akademi** veritabanı eğitimlerinde kullanılabilecek T-SQL örneklerini içerir. Tüm modüller aynı şemayı kullanır: **Egitmenler**, **Ogrenciler**, **Kurslar** ve **Kayitlar** tabloları. Böylece veritabanı oluşturmadan sorgulara, programlanabilir nesnelerden performans ve transaction yönetimine kadar tüm konular tek bir bağlamda ilerler.

Betikler numaralandırılmıştır ve sırayla çalıştırılmak üzere tasarlanmıştır. Örnekteki tüm kişi bilgileri ve fiyatlar **kurgusaldır**.

### Veri Modeli

```text
Egitmenler (EgitmenId, Ad, Soyad, UzmanlikAlani, Email, IseBaslamaTarihi)
     │ 1
     │
     ∞
Kurslar (KursId, KursAdi, Kategori, SaatSuresi, Fiyat, EgitmenId)
     │ 1
     │
     ∞
Kayitlar (KayitId, OgrenciId, KursId, KayitTarihi, Durum, Puan)
     ∞
     │
     │ 1
Ogrenciler (OgrenciId, Ad, Soyad, Email, DogumTarihi, Sehir, KayitTarihi)
```

## İçindekiler

| Modül | Konular |
|-------|---------|
| [01-veritabani-olusturma](./01-veritabani-olusturma) | `CREATE DATABASE`, tablolar, anahtarlar ve kısıtlar |
| [02-ornek-veri](./02-ornek-veri) | `INSERT` ile örnek veri yükleme |
| [03-select-sorgulari](./03-select-sorgulari) | `SELECT`, `WHERE`, `LIKE`, `ORDER BY`, `CASE`, yerleşik fonksiyonlar |
| [04-join-gruplama](./04-join-gruplama) | JOIN türleri, `GROUP BY`, `HAVING`, pencere fonksiyonları, alt sorgu, CTE |
| [05-view-procedure-function](./05-view-procedure-function) | View, stored procedure, fonksiyon, trigger |
| [06-index-performans](./06-index-performans) | İndeks türleri, execution plan, sargable sorgular, bakım |
| [07-transaction](./07-transaction) | Transaction, hata yönetimi, izolasyon seviyeleri, deadlock |

## Kurulum / Başlarken

### Gereksinimler

- **SQL Server 2017 veya üzeri** (Developer veya Express sürümü eğitim için yeterlidir). `CREATE OR ALTER` için en az 2016 SP1, `STRING_AGG` için 2017 gereklidir.
- İstemci aracı: [SQL Server Management Studio (SSMS)](https://learn.microsoft.com/sql/ssms/download-sql-server-management-studio-ssms) veya [Azure Data Studio](https://learn.microsoft.com/azure-data-studio/download-azure-data-studio)
- Docker kullanıyorsanız örnek bir SQL Server kapsayıcısı:

```bash
docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=<guclu-bir-parola>" \
  -p 1433:1433 --name sqlserver -d mcr.microsoft.com/mssql/server:2022-latest
```

### Depoyu klonlama

```bash
git clone https://github.com/iakademi/sql-server-egitim.git
cd sql-server-egitim
```

### Betikleri çalıştırma

Dosyaları SSMS / Azure Data Studio'da açarak ya da `sqlcmd` ile çalıştırabilirsiniz. Önce şema ve veriyi yükleyin:

```bash
sqlcmd -S localhost -E -i 01-veritabani-olusturma/01-veritabani-ve-tablolar.sql
sqlcmd -S localhost -E -d IAkademiDB -i 02-ornek-veri/02-ornek-veri.sql
```

Ardından diğer modülleri numara sırasıyla çalıştırın. SQL kimlik doğrulaması kullanıyorsanız `-E` yerine `-U kullanici -P parola` parametrelerini kullanın.

> **Uyarı:** `01` numaralı betik varsa mevcut `IAkademiDB` veritabanını siler. Üretim sunucularında çalıştırmayın.

## Klasör Yapısı

```text
sql-server-egitim/
├── 01-veritabani-olusturma/
│   ├── 01-veritabani-ve-tablolar.sql
│   └── README.md
├── 02-ornek-veri/
│   ├── 02-ornek-veri.sql
│   └── README.md
├── 03-select-sorgulari/
│   ├── 03-select-sorgulari.sql
│   └── README.md
├── 04-join-gruplama/
│   ├── 04-join-gruplama.sql
│   ├── 04-alt-sorgu-ve-cte.sql
│   └── README.md
├── 05-view-procedure-function/
│   ├── 05-view-procedure-function.sql
│   └── README.md
├── 06-index-performans/
│   ├── 06-index-performans.sql
│   └── README.md
├── 07-transaction/
│   ├── 07-transaction.sql
│   └── README.md
├── .gitignore
├── LICENSE
└── README.md
```

## Katkıda Bulunma

Katkılarınızı bekliyoruz:

1. Depoyu fork'layın.
2. Yeni bir dal oluşturun: `git checkout -b ozellik/yeni-sorgu`
3. Değişikliklerinizi açıklayıcı bir mesajla commit'leyin.
4. Bir Pull Request açın.

Lütfen betiklerin `IAkademiDB` şemasıyla çalıştığından emin olun, açıklamaları Türkçe yazın ve dosya adlandırma düzenine (`NN-konu.sql`) uyun. Hata bildirimleri ve öneriler için [Issues](https://github.com/iakademi/sql-server-egitim/issues) bölümünü kullanabilirsiniz.

## Lisans

Bu proje [MIT Lisansı](./LICENSE) ile lisanslanmıştır.

## İ-Akademi Hakkında

[İ-Akademi](https://iakademi.com), İstanbul merkezli bir BT eğitim merkezidir. Microsoft, Office ve Power Platform, Cisco, siber güvenlik, yazılım geliştirme, PMP/Scrum gibi alanlarda eğitimler sunar; ayrıca Pearson VUE ve Kryterion sınav merkezi olarak hizmet verir.

- Web sitesi: <https://iakademi.com>
- Microsoft ve veritabanı eğitimleri için: [iakademi.com](https://iakademi.com) adresindeki Microsoft eğitimleri kategorisine göz atabilirsiniz.
