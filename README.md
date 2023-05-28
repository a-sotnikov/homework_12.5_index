# Домашнее задание к занятию "12.5 Индексы" - `Андрей Сотников`

---

### Задание 1

> Напишите запрос к учебной базе данных, который вернёт процентное отношение общего размера всех индексов к общему размеру всех таблиц.

```sql
SELECT CONCAT(ROUND(SUM(INDEX_LENGTH) / SUM(DATA_LENGTH) * 100, 1), '%') 
FROM INFORMATION_SCHEMA.TABLES
```

### Задание 2

> Выполните explain analyze следующего запроса:
>
> ```sql
> select distinct concat(c.last_name, ' ', c.first_name), sum(p.amount) over (partition by c.customer_id, f.title)
> from payment p, rental r, customer c, inventory i, film f
> where date(p.payment_date) = '2005-07-30' and p.payment_date = r.rental_date and r.customer_id = c.customer_id and i.inventory_id = r.inventory_id
> ```
>
> - перечислите узкие места;
> - оптимизируйте запрос: внесите корректировки по использованию операторов, при необходимости добавьте индексы.

Запрос, если я правильно понял, предназначен для выгрузки суммы платежей, совершенных каждым клиентом в определенный день.  
При этом используются 5 таблиц, тогда как для получения результата достаточно трех (clients, rental, payment).

MySQL как может пытается оптимизировать запрос и выполняет:

- Выгрузку строк из таблицы `payment`, которые удовлетворяют условию `date(p.payment_date) = '2005-07-30'`. Выполняется без индексов, то есть, таблица читается полностью. Получается 634 строки.
- INNER JOIN с таблицей `film` без условия, что приводит к перемножению таблиц. Число строк вырастает до 634000.
- INNER JOIN с таблицей `rental` по условию `p.payment_date = r.rental_date`.
- INNER JOIN с таблицей `customer` по условию `r.customer_id = c.customer_id`.
- INNER JOIN с таблицей `inventory` по условию `i.inventory_id = r.inventory_id`.

Каждый раз проверяется соответствие нескольких сотен тысяч значений.

Затем, при помощи оконной функции производится расчет суммы платежей, которая "растягивается" на каждую строку, после чего происходит `distinct`, который убирает дубликаты и оставляет всего 391 строку.

Оптимизировать запрос можно, убрав лишние таблицы и используя LEFT JOIN:

```sql
select concat(c.last_name, ' ', c.first_name) AS customer_name, SUM(p.amount)
from customer c
LEFT JOIN payment p ON p.customer_id = c.customer_id
LEFT JOIN rental r ON r.rental_id = p.rental_id 
WHERE date(p.payment_date) = '2005-07-30'
GROUP BY customer_name
```

Время выполнения снижается почти в 500 раз (с 5090 до 11.6).
При добавлении индекса к полю `payment.payment_date` и использования условия `WHERE` без использования оператора `DATE`, например

``` sql
WHERE payment_date >= '2005-07-30' and payment_date < DATE_ADD('2005-07-30', INTERVAL 1 DAY)
```

общее время выполнения уменьшается еще в несколько раз (в моем случае составило 2.36).
