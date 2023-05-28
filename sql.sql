explain analyze
select COUNT(1)
from payment p, rental r, customer c, inventory i, film f 
where date(p.payment_date) = '2005-07-30' and p.payment_date = r.rental_date and r.customer_id = c.customer_id and i.inventory_id = r.inventory_id

-> Limit: 200 row(s)  (cost=23.6e+6 rows=1) (actual time=756..756 rows=1 loops=1)
    -> Aggregate: count(1)  (cost=23.6e+6 rows=1) (actual time=756..756 rows=1 loops=1)
        -> Nested loop inner join  (cost=22e+6 rows=16.1e+6) (actual time=0.622..720 rows=642000 loops=1)
            -> Nested loop inner join  (cost=20.4e+6 rows=16.1e+6) (actual time=0.616..630 rows=642000 loops=1)
                -> Nested loop inner join  (cost=18.8e+6 rows=16.1e+6) (actual time=0.607..539 rows=642000 loops=1)
                    -> Inner hash join (no condition)  (cost=1.61e+6 rows=16.1e+6) (actual time=0.587..17.4 rows=634000 loops=1)
                        -> Filter: (cast(p.payment_date as date) = '2005-07-30')  (cost=1.63 rows=16086) (actual time=0.0539..2.3 rows=634 loops=1)
                            -> Table scan on p  (cost=1.63 rows=16086) (actual time=0.0365..1.65 rows=16044 loops=1)
                        -> Hash
                            -> Covering index scan on f using idx_fk_language_id  (cost=103 rows=1000) (actual time=0.0443..0.41 rows=1000 loops=1)
                    -> Covering index lookup on r using rental_date (rental_date=p.payment_date)  (cost=0.969 rows=1) (actual time=513e-6..751e-6 rows=1.01 loops=634000)
                -> Single-row covering index lookup on c using PRIMARY (customer_id=r.customer_id)  (cost=250e-6 rows=1) (actual time=57.4e-6..70.1e-6 rows=1 loops=642000)
            -> Single-row covering index lookup on i using PRIMARY (inventory_id=r.inventory_id)  (cost=250e-6 rows=1) (actual time=54.7e-6..67.2e-6 rows=1 loops=642000)

explain analyze
SELECT COUNT(1)
from payment p
inner join rental r ON p.payment_date = r.rental_date
inner join customer c ON r.customer_id = c.customer_id
inner join inventory i ON i.inventory_id = r.inventory_id
JOIN film_temp ft
where date(p.payment_date) = '2005-07-30'         


-> Limit: 200 row(s)  (cost=23.6e+6 rows=1) (actual time=1806..1806 rows=1 loops=1)
    -> Aggregate: count(1)  (cost=23.6e+6 rows=1) (actual time=1806..1806 rows=1 loops=1)
        -> Nested loop inner join  (cost=22e+6 rows=16.1e+6) (actual time=0.912..1726 rows=642000 loops=1)
            -> Nested loop inner join  (cost=20.4e+6 rows=16.1e+6) (actual time=0.908..1508 rows=642000 loops=1)
                -> Nested loop inner join  (cost=18.8e+6 rows=16.1e+6) (actual time=0.901..1285 rows=642000 loops=1)
                    -> Inner hash join (no condition)  (cost=1.61e+6 rows=16.1e+6) (actual time=0.883..39.5 rows=634000 loops=1)
                        -> Filter: (cast(p.payment_date as date) = '2005-07-30')  (cost=1.63 rows=16086) (actual time=0.0359..5.25 rows=634 loops=1)
                            -> Table scan on p  (cost=1.63 rows=16086) (actual time=0.0214..3.7 rows=16044 loops=1)
                        -> Hash
                            -> Table scan on ft  (cost=103 rows=1000) (actual time=0.025..0.761 rows=1000 loops=1)
                    -> Covering index lookup on r using rental_date (rental_date=p.payment_date)  (cost=0.969 rows=1) (actual time=0.00122..0.00179 rows=1.01 loops=634000)
                -> Single-row covering index lookup on c using PRIMARY (customer_id=r.customer_id)  (cost=250e-6 rows=1) (actual time=145e-6..176e-6 rows=1 loops=642000)
            -> Single-row covering index lookup on i using PRIMARY (inventory_id=r.inventory_id)  (cost=250e-6 rows=1) (actual time=139e-6..169e-6 rows=1 loops=642000)


explain analyze
SELECT COUNT(1)
from payment p
JOIN film f
where date(p.payment_date) = '2005-07-30'  

-> Limit: 200 row(s)  (cost=1.61e+6 rows=200) (actual time=1.15..1.22 rows=200 loops=1)
    -> Inner hash join (no condition)  (cost=1.61e+6 rows=16.1e+6) (actual time=1.15..1.2 rows=200 loops=1)
        -> Filter: (cast(p.payment_date as date) = '2005-07-30')  (cost=1.7 rows=16086) (actual time=0.0359..0.0359 rows=1 loops=1)
            -> Table scan on p  (cost=1.7 rows=16086) (actual time=0.026..0.0291 rows=43 loops=1)
        -> Hash
            -> Table scan on f  (cost=103 rows=1000) (actual time=0.0288..0.833 rows=1000 loops=1)




explain
select distinct concat(c.last_name, ' ', c.first_name), sum(p.amount) over (partition by c.customer_id, f.title)
from payment p, rental r, customer c, inventory i, film f
where date(p.payment_date) = '2005-07-30' and p.payment_date = r.rental_date and r.customer_id = c.customer_id and i.inventory_id = r.inventory_id

-> Limit: 200 row(s)  (cost=0..0 rows=0) (actual time=5090..5090 rows=200 loops=1)
    -> Table scan on <temporary>  (cost=2.5..2.5 rows=0) (actual time=5090..5090 rows=200 loops=1)
        -> Temporary table with deduplication  (cost=0..0 rows=0) (actual time=5090..5090 rows=391 loops=1)
            -> Window aggregate with buffering: sum(payment.amount) OVER (PARTITION BY c.customer_id,f.title )   (actual time=2290..4946 rows=642000 loops=1)
                -> Sort: c.customer_id, f.title  (actual time=2290..2335 rows=642000 loops=1)
                    -> Stream results  (cost=22e+6 rows=16.1e+6) (actual time=2.13..1808 rows=642000 loops=1)
                        -> Nested loop inner join  (cost=22e+6 rows=16.1e+6) (actual time=2.09..1564 rows=642000 loops=1)
                            -> Nested loop inner join  (cost=20.4e+6 rows=16.1e+6) (actual time=2.08..1380 rows=642000 loops=1)
                                -> Nested loop inner join  (cost=18.8e+6 rows=16.1e+6) (actual time=2.05..1194 rows=642000 loops=1)
                                    -> Inner hash join (no condition)  (cost=1.61e+6 rows=16.1e+6) (actual time=1.94..50.2 rows=634000 loops=1)
                                        -> Filter: (cast(p.payment_date as date) = '2005-07-30')  (cost=1.68 rows=16086) (actual time=0.158..5.59 rows=634 loops=1)
                                            -> Table scan on p  (cost=1.68 rows=16086) (actual time=0.103..4.17 rows=16044 loops=1)
                                        -> Hash
                                            -> Covering index scan on f using idx_title  (cost=112 rows=1000) (actual time=0.351..1.34 rows=1000 loops=1)
                                    -> Covering index lookup on r using rental_date (rental_date=p.payment_date)  (cost=0.969 rows=1) (actual time=0.00115..0.00166 rows=1.01 loops=634000)
                                -> Single-row index lookup on c using PRIMARY (customer_id=r.customer_id)  (cost=250e-6 rows=1) (actual time=113e-6..139e-6 rows=1 loops=642000)
                            -> Single-row covering index lookup on i using PRIMARY (inventory_id=r.inventory_id)  (cost=250e-6 rows=1) (actual time=110e-6..136e-6 rows=1 loops=642000)


SELECT *
FROM film_temp;