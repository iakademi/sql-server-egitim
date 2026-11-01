# 04 - JOIN, Gruplama, Alt Sorgu ve CTE

Birden fazla tabloyu birleştirme, veriyi özetleme ve karmaşık sorgulara yapı kazandırma.

## Konular

**04-join-gruplama.sql**
- `INNER`, `LEFT`, `RIGHT`, `FULL OUTER`, `CROSS` ve self join
- Eşleşmeyen kayıtları bulma (`LEFT JOIN ... WHERE ... IS NULL`)
- `GROUP BY`, toplama fonksiyonları, `HAVING`
- `ROLLUP` ve `STRING_AGG`
- Pencere fonksiyonları: `ROW_NUMBER`, `RANK`, `DENSE_RANK`, `AVG() OVER`, `LAG`

**04-alt-sorgu-ve-cte.sql**
- Skaler, `IN`, `EXISTS`, ilişkili alt sorgular ve türetilmiş tablolar
- `CROSS APPLY`
- CTE, birden fazla CTE ve özyinelemeli CTE (sayı ve takvim üretme)
- `UNION`, `UNION ALL`, `INTERSECT`, `EXCEPT`

## Çalıştırma

`01` ve `02` modüllerindeki betikler çalıştırıldıktan sonra dosyaları SSMS veya Azure Data Studio'da açıp sorguları tek tek çalıştırın.

```bash
sqlcmd -S localhost -E -d IAkademiDB -i 04-join-gruplama.sql
sqlcmd -S localhost -E -d IAkademiDB -i 04-alt-sorgu-ve-cte.sql
```

## Dosyalar

| Dosya | Açıklama |
|-------|----------|
| `04-join-gruplama.sql` | JOIN türleri, gruplama ve pencere fonksiyonları |
| `04-alt-sorgu-ve-cte.sql` | Alt sorgular, CTE ve küme işlemleri |
