SELECT * FROM customers;
SELECT * FROM restaurants;
SELECT * FROM orders;
SELECT * FROM riders;
SELECT * FROM deliveries;

--  HANDLING NULL VALUES

SELECT COUNT(*) FROM customers
WHERE
	customer_name is null
	or
	ref_date is null;

SELECT COUNT(*) FROM restaurants
WHERE 
	restaurant_name IS NULL
	OR
	city IS NULL
	OR
	opening_hours IS NULL;


SELECT count(*) FROM orders
WHERE 
	order_item IS NULL
	OR
	order_date IS NULL
	OR
	order_time IS NULL
	OR
	order_status IS NULL
	OR 
	total_amount IS NULL;


DELETE FROM orders
WHERE 
	order_item IS NULL
	OR
	order_date IS NULL
	OR
	order_time IS NULL
	OR
	order_status IS NULL
	OR 
	total_amount IS NULL




-- Easy Business Problems

-- 1. Find the total number of orders each restaurant has received.

select distinct restaurant_id from orders;

select r.restaurant_id,
	   r.restaurant_name,
	   count(o.order_id) as total_orders
from restaurants r
left join orders o 
on o.restaurant_id = r.restaurant_id
GROUP by r.restaurant_id,r.restaurant_name
order by total_orders desc;

-- 2. Calculate the average amount spent by each customer.
SELECT c.customer_id,
       c.customer_name,
       AVG(o.total_amount) AS avg_spent
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY avg_spent DESC NULLS LAST;

-- 3. Find the total sales amount for each restaurant.
SELECT r.restaurant_id,
       r.restaurant_name,
       COALESCE(SUM(o.total_amount), 0) AS total_sales
FROM restaurants r
LEFT JOIN orders o ON o.restaurant_id = r.restaurant_id
GROUP BY r.restaurant_id, r.restaurant_name
ORDER BY total_sales DESC;


-- 4. Identify the order with the highest number of items.
SELECT order_item,
       COUNT(*) AS order_count
FROM orders
GROUP BY order_item
ORDER BY order_count DESC
LIMIT 1;


-- 5. Find the top 5 customers who have placed the most orders.
SELECT c.customer_id,
       c.customer_name,
       COUNT(o.order_id) AS orders_count
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY orders_count DESC
LIMIT 5;

-- 6. Retrieve orders placed in the last 30 days.
SELECT *
FROM orders
WHERE order_date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY order_date DESC, order_time DESC;

SELECT *
FROM orders
WHERE order_date >= (
  (SELECT MAX(order_date) FROM orders) - INTERVAL '30 days'
)
ORDER BY order_date DESC, order_time DESC;



-- 7. Calculate the average delivery time for each rider.
SELECT r.rider_id,
       r.rider_name,
       AVG(d.delivery_time - o.order_time) AS avg_delivery_interval
FROM deliveries d
JOIN orders o   ON o.order_id = d.order_id
JOIN riders r   ON r.rider_id = d.rider_id
WHERE d.delivery_status = 'Completed'
GROUP BY r.rider_id, r.rider_name
ORDER BY avg_delivery_interval;

WITH cleaned AS (
  SELECT r.rider_id,
         r.rider_name,
         (o.order_date + o.order_time) AS ordered_ts,
         CASE
           WHEN d.delivery_time IS NULL THEN NULL
           WHEN d.delivery_time >= o.order_time
                THEN (o.order_date + d.delivery_time)
           ELSE (o.order_date + INTERVAL '1 day' + d.delivery_time)
         END AS delivered_ts
  FROM deliveries d
  JOIN orders o  ON o.order_id = d.order_id
  JOIN riders r  ON r.rider_id = d.rider_id
  WHERE d.delivery_time IS NOT NULL
    AND lower(coalesce(d.delivery_status,'')) IN ('completed','delivered')
)
SELECT rider_id,
       rider_name,
       AVG(delivered_ts - ordered_ts) AS avg_delivery_interval
FROM cleaned
WHERE delivered_ts IS NOT NULL
GROUP BY rider_id, rider_name
ORDER BY avg_delivery_interval;


-- 8. List restaurants that are open 24 hours.
SELECT DISTINCT opening_hours
FROM restaurants
ORDER BY opening_hours;

SELECT *
FROM restaurants
WHERE opening_hours ILIKE '%24/7%'
   OR opening_hours ILIKE '%24x7%'
   OR opening_hours ILIKE '%24 x 7%'
   OR opening_hours ILIKE '%open 24 hour%'
   OR opening_hours ~* '\y24(\s*hours?)?\y';




-- 9. Get the count of each order status.
SELECT order_status, COUNT(*) AS status_count
FROM orders
GROUP BY order_status
ORDER BY status_count DESC;

-- 10. Find out how many deliveries each rider has completed.
SELECT r.rider_id,
       r.rider_name,
       COUNT(d.delivery_id) AS completed_deliveries
FROM riders r
LEFT JOIN deliveries d
  ON d.rider_id = r.rider_id
 AND d.delivery_status = 'Completed'
GROUP BY r.rider_id, r.rider_name
ORDER BY completed_deliveries DESC;

-- 11. Identify the top 5 restaurants with the highest total sales.
SELECT r.restaurant_id,
       r.restaurant_name,
       SUM(o.total_amount) AS total_sales
FROM orders o
JOIN restaurants r ON r.restaurant_id = o.restaurant_id
GROUP BY r.restaurant_id, r.restaurant_name
ORDER BY total_sales DESC
LIMIT 5;

-- 12. Get the number of orders per city.
SELECT r.city,
       COUNT(o.order_id) AS orders_count
FROM restaurants r
LEFT JOIN orders o ON o.restaurant_id = r.restaurant_id
GROUP BY r.city
ORDER BY orders_count DESC NULLS LAST;

-- 13. Find the most frequently ordered item.
SELECT order_item,
       COUNT(*) AS times_ordered
FROM orders
GROUP BY order_item
ORDER BY times_ordered DESC
LIMIT 1;

-- 14. List orders where the delivery was completed on time.
SELECT o.order_id,
       o.order_date,
       o.order_time,
       d.delivery_time,
       (d.delivery_time - o.order_time) AS delivery_interval
FROM deliveries d
JOIN orders o ON o.order_id = d.order_id
WHERE d.delivery_status = 'Completed'
  AND (d.delivery_time - o.order_time) <= INTERVAL '45 minutes'
ORDER BY o.order_date DESC, o.order_time DESC;

-- 15. Calculate the average order amount for each day of the week.
SELECT EXTRACT(DOW FROM order_date) AS dow,  -- 0=Sunday ... 6=Saturday
       TO_CHAR(order_date, 'Dy') AS day_name,
       AVG(total_amount) AS avg_amount
FROM orders
GROUP BY EXTRACT(DOW FROM order_date), TO_CHAR(order_date, 'Dy')
ORDER BY dow;

-- 16. List customers who have placed orders in the last 90 days.
SELECT DISTINCT c.customer_id, c.customer_name
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_date >= CURRENT_DATE - INTERVAL '90 days'
ORDER BY c.customer_name;

-- 17. Get delivery times and statuses for completed deliveries.
SELECT d.delivery_id,
       d.order_id,
       d.delivery_status,
       o.order_date,
       o.order_time,
       d.delivery_time,
       (CASE
          WHEN d.delivery_time IS NULL THEN NULL
          WHEN d.delivery_time >= o.order_time
               THEN (o.order_date + d.delivery_time) - (o.order_date + o.order_time)
          ELSE (o.order_date + INTERVAL '1 day' + d.delivery_time) - (o.order_date + o.order_time)
        END) AS delivery_interval
FROM deliveries d
JOIN orders o ON o.order_id = d.order_id
WHERE d.delivery_time IS NOT NULL
  AND lower(coalesce(d.delivery_status,'')) IN ('completed','delivered')
ORDER BY o.order_date DESC, o.order_time DESC;



-- 18. Find restaurants that have not received any orders.
SELECT r.*
FROM restaurants r
LEFT JOIN orders o ON o.restaurant_id = r.restaurant_id
WHERE o.order_id IS NULL
ORDER BY r.restaurant_name;

-- 19. Calculate the total number of orders for each month.
SELECT date_trunc('month', order_date) AS month,
       COUNT(*) AS orders_count
FROM orders
GROUP BY date_trunc('month', order_date)
ORDER BY month;

-- 20. Find the order with the longest time from order placement to delivery.
WITH intervals AS (
  SELECT o.order_id,
         o.order_date,
         o.order_time,
         d.delivery_time,
         (CASE
            WHEN d.delivery_time IS NULL THEN NULL
            WHEN d.delivery_time >= o.order_time
                 THEN (o.order_date + d.delivery_time) - (o.order_date + o.order_time)
            ELSE (o.order_date + INTERVAL '1 day' + d.delivery_time) - (o.order_date + o.order_time)
          END) AS delivery_interval
  FROM deliveries d
  JOIN orders o ON o.order_id = d.order_id
  WHERE d.delivery_time IS NOT NULL
    AND lower(coalesce(d.delivery_status,'')) IN ('completed','delivered')
)
SELECT *
FROM intervals
WHERE delivery_interval IS NOT NULL
ORDER BY delivery_interval DESC
LIMIT 1;



-- Are there any orders at all, and how recent are they?
SELECT COUNT(*) AS orders_total,
       MIN(order_date) AS first_order,
       MAX(order_date) AS last_order
FROM orders;

-- What delivery statuses/NULLs do you have?
SELECT delivery_status, COUNT(*)
FROM deliveries
GROUP BY delivery_status;

-- Do you have delivery_time values?
SELECT COUNT(*) AS deliveries_total,
       COUNT(delivery_time) AS non_null_delivery_time
FROM deliveries;

-- What does opening_hours look like?
SELECT opening_hours, COUNT(*)
FROM restaurants
GROUP BY opening_hours
ORDER BY COUNT(*) DESC;
