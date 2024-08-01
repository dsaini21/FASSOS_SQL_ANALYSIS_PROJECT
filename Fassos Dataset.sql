drop table if exists driver;
CREATE TABLE driver(driver_id integer,reg_date date);

INSERT INTO driver (driver_id, reg_date)
VALUES (1, '2021-01-01'),
       (2, '2021-01-03'),
       (3, '2021-01-08'),
       (4, '2021-01-15');


drop table if exists ingredients;
CREATE TABLE ingredients(ingredients_id integer,ingredients_name varchar(60));

INSERT INTO ingredients(ingredients_id ,ingredients_name)
 VALUES (1,'BBQ Chicken'),
(2,'Chilli Sauce'),
(3,'Chicken'),
(4,'Cheese'),
(5,'Kebab'),
(6,'Mushrooms'),
(7,'Onions'),
(8,'Egg'),
(9,'Peppers'),
(10,'schezwan sauce'),
(11,'Tomatoes'),
(12,'Tomato Sauce');

drop table if exists rolls;
CREATE TABLE rolls(roll_id integer,roll_name varchar(30));

INSERT INTO rolls(roll_id ,roll_name)
 VALUES (1	,'Non Veg Roll'),
(2	,'Veg Roll');

drop table if exists rolls_recipes;
CREATE TABLE rolls_recipes(roll_id integer,ingredients varchar(24));

INSERT INTO rolls_recipes(roll_id ,ingredients)
 VALUES (1,'1,2,3,4,5,6,8,10'),
(2,'4,6,7,9,11,12');

drop table if exists driver_order;
CREATE TABLE driver_order(order_id integer,driver_id integer,pickup_time datetime,distance VARCHAR(7),duration VARCHAR(10),cancellation VARCHAR(23));
INSERT INTO driver_order(order_id,driver_id,pickup_time,distance,duration,cancellation)
 VALUES(1,1,'2021-01-01 18:15:34','20km','32 minutes',''),
(2,1,'2021-01-01 19:10:54','20km','27 minutes',''),
(3,1,'2021-01-03 00:12:37','13.4km','20 mins','NaN'),
(4,2,'2021-01-04 13:53:03','23.4','40','NaN'),
(5,3,'2021-01-08 21:10:57','10','15','NaN'),
(6,3,null,null,null,'Cancellation'),
(7,2,'2021-01-08 21:30:45','25km','25mins',null),
(8,2,'2021-01-10 00:15:02','23.4 km','15 minute',null),
(9,2,null,null,null,'Customer Cancellation'),
(10,1,'2021-01-11 18:50:20','10km','10minutes',null);


drop table if exists customer_orders;
CREATE TABLE customer_orders(order_id integer,customer_id integer,roll_id integer,not_include_items VARCHAR(4),extra_items_included VARCHAR(4),order_date datetime);
INSERT INTO customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date)
VALUES
    (1, 101, 1, '', '', '2021-01-01 18:05:02'),
    (2, 101, 1, '', '', '2021-01-01 19:00:52'),
    (3, 102, 1, '', '', '2021-01-02 23:51:23'),
    (3, 102, 2, '', 'NaN', '2021-01-02 23:51:23'),
    (4, 103, 1, '4', '', '2021-01-04 13:23:46'),
    (4, 103, 1, '4', '', '2021-01-04 13:23:46'),
    (4, 103, 2, '4', '', '2021-01-04 13:23:46'),
    (5, 104, 1, null, '1', '2021-01-08 21:00:29'),
    (6, 101, 2, null, null, '2021-01-08 21:03:13'),
    (7, 105, 2, null, '1', '2021-01-08 21:20:29'),
    (8, 102, 1, null, null, '2021-01-09 23:54:33'),
    (9, 103, 1, '4', '1.5', '2021-01-10 11:22:59'),
    (10, 104, 1, null, null, '2021-01-11 18:34:49'),
    (10, 104, 1, '2.6', '1.4', '2021-01-11 18:34:49');

select * from customer_orders;
select * from driver_order;
select * from ingredients;
select * from driver;
select * from rolls;
select * from rolls_recipes;

# Roll Metrics.

-- 1. How many rolls were ordered?
select count(roll_id)
from customer_orders;

-- 2. How many unique customer order were made?
select  count(distinct customer_id)
from customer_orders;

-- 3. How many successful order were delivered by each driver?

select driver_id, count(distance)
from driver_order
where distance > 0
group by driver_id;

-- 4. How many each type of rolls was delivered?

select roll_name, count(co.roll_id)
from driver_order
join customer_orders co on driver_order.order_id = co.order_id
JOIN rolls r on co.roll_id = r.roll_id
where distance > 0
group by roll_name ;

# No. of total orders
select  roll_name, count(customer_orders.roll_id) as Order_count
from customer_orders
JOIN rolls r on customer_orders.roll_id = r.roll_id
group by roll_name;

-- 5. How many veg or non-veg Rolls were ordered by each customer?

select customer_id, roll_name,count(roll_name) as order_count
from customer_orders
join rolls r on customer_orders.roll_id = r.roll_id
group by customer_id, roll_name
order by customer_id


-- 6. what was the maximum number of rolls delivered in a single order?

select max(order_total) from(
select count(*) as order_total from customer_orders where order_id in (
select order_id from driver_order
where distance > 0)
group by order_id) X;

-- 7. For each customer, how many delivered rolls had at least 1 change and how many had no changes?
select customer_id,chg_no_chg,count(order_id) as number_of_change
from(
select *,
       case when new_extra_included_items = 0 and new_extra_included_items = 0 then 'no change' else 'change' end as chg_no_chg
from (
select customer_id,order_id,
       (case when not_include_items is null or not_include_items = '' then 0 else not_include_items end) as new_not_included_items,
       (case when extra_items_included is null or extra_items_included = '' or extra_items_included = 'NaN' then 0 else extra_items_included end) as new_extra_included_items
from customer_orders
where order_id in (select order_id from driver_order
where distance > 0)) x) z
group by customer_id, chg_no_chg;


-- 8. How many rolls were delivered that had both exclusions and extras?
select  change_status, count(order_id)
from(
select *,
       case when new_not_included > 0 and new_extra_item_included >0 then 'change' else 'no change' end as change_status
from(
select order_id,customer_id,roll_id,
       case when not_include_items is null or not_include_items = '' then 0 else not_include_items end as new_not_included,
       case when extra_items_included is null or extra_items_included = '' or extra_items_included = 'NaN' then 0 else extra_items_included end as new_extra_item_included
from customer_orders
where order_id in (select order_id
from driver_order
where distance > 0)) x) z
group by  change_status;

-- 9. what is the total number of rolls ordered for each hour of the day?

select hour_bucket, count(hour_bucket)
from(
SELECT *,
       CONCAT(CAST(HOUR(order_date) AS CHAR), '-', (HOUR(order_date) + 1)) AS hour_bucket
FROM customer_orders) x
group by hour_bucket
order by hour_bucket;

-- 10. what was the number of orders for each day of week?
select dayname(order_date), count(distinct order_id) from customer_orders
group by dayname(order_date)


-- 11. what was the average time in minutes it took for each driver to arrive at fassos HQ to pickup the order?

select  driver_id,avg(time)
from(
select driver_id,order_date, pickup_time, timestampdiff(minute,order_date,pickup_time) as time
from customer_orders
join driver_order  on driver_order.order_id = customer_orders.order_id
where distance >0) a
group by driver_id ;

-- 12. Is there any relationship between the number of rolls and how long the order takes to prepare?
select order_id,count(roll_id) as number,round(sum(time)/count(roll_id),2)
from(
select co.order_id,customer_id,roll_id,order_date,pickup_time,cancellation, distance,timestampdiff(minute,order_date,pickup_time) as time
from customer_orders co
join driver_order do on co.order_id = do.order_id
where distance>0) x
group by order_id, time;

## OR

select order_id,count(roll_id) as number,time
from(
select co.order_id,customer_id,roll_id,order_date,pickup_time,cancellation, distance,timestampdiff(minute,order_date,pickup_time) as time
from customer_orders co
join driver_order do on co.order_id = do.order_id
where distance>0) x
group by order_id, time;


-- 13. what was the average distance travelled for each of the customer?

select customer_id, sum(distance)/count(order_id)
from(
select * from (
select *,
       row_number() over (partition by order_id order by time) rnk
from(
select order_id,customer_id,
       cast(trim(replace(lower(distance),'km','')) as decimal(4,2)) as distance,
       duration, timestampdiff(minute,order_date,pickup_time) as time
from customer_orders
join driver_order using(order_id)
where distance >0) x)a
where rnk = 1) b
group by customer_id;