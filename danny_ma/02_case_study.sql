USE pizza_runner;
-- Cleanups

-- customer_orders

-- SELECT * FROM customer_orders WHERE exclusions IN ('','null');
-- UPDATE customer_orders
-- SET exclusions = NULL
-- WHERE exclusions IN ('','null');

-- SELECT * FROM customer_orders WHERE extras IN ('','null');
-- UPDATE customer_orders
-- SET extras = NULL
-- WHERE extras IN ('','null');

-- SELECT * FROM runner_orders WHERE cancellation IN ('','null');
-- UPDATE runner_orders
-- SET cancellation = NULL
-- WHERE cancellation IN ('','null');

-- SELECT * FROM runner_orders WHERE pickup_time in ('','null');
-- UPDATE runner_orders
-- SET pickup_time = NULL
-- WHERE pickup_time IN ('','null');

-- SELECT * FROM runner_orders WHERE distance in ('','null');
-- UPDATE runner_orders
-- SET distance = NULL
-- WHERE distance IN ('','null');

-- SELECT * FROM runner_orders WHERE duration in ('','null');
-- UPDATE runner_orders
-- SET duration = NULL
-- WHERE duration IN ('','null');

-- Removing km's from distance
-- UPDATE runner_orders
-- SET distance = REPLACE(distance,'km','')
-- WHERE distance LIKE '%km';

-- Trimming extra white space
-- UPDATE runner_orders
-- SET distance = TRIM(distance);

-- UPDATE runner_orders
-- SET duration = REPLACE(duration,' minute','')
-- WHERE duration LIKE '%min%';

-- UPDATE runner_orders
-- SET duration = TRIM(duration);



-- A. Pizza Metrics


-- How many pizzas were ordered?
SELECT COUNT(order_id) AS 'Pizzas Ordered'
FROM customer_orders;

-- How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) AS 'Unique Orders'
FROM customer_orders;

-- How many successful orders were delivered by each runner?
SELECT COUNT(*) AS 'Successful Orders'
FROM runner_orders
WHERE pickup_time IS NOT NULL
    AND distance IS NOT NULL
    AND duration IS NOT NULL;

-- How many of each type of pizza was delivered?
SELECT pizza_name,
    NumofPizza
FROM (
        SELECT customer_orders.pizza_id,
            COUNT(customer_orders.pizza_id) AS NumofPizza
        FROM customer_orders
        GROUP BY customer_orders.pizza_id
    ) AS table1
    JOIN pizza_names on pizza_names.pizza_id = table1.pizza_id;

-- How many Vegetarian and Meatlovers were ordered by each customer?
SELECT customer_id,
    pizza_name,
    Pizza_Type_Delivered
FROM (
        SELECT customer_id,
            pizza_id,
            COUNT(*) AS Pizza_Type_Delivered
        FROM customer_orders
        GROUP BY customer_orders.customer_id,
            customer_orders.pizza_id
    ) AS table1
    JOIN pizza_names ON pizza_names.pizza_id = table1.pizza_id
ORDER BY customer_id;

-- What was the maximum number of pizzas delivered in a single order?
SELECT TOP 1 COUNT(order_id) AS 'Max Pizza in a single order'
FROM customer_orders
GROUP BY order_id
ORDER BY COUNT(order_id) DESC;

-- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT customer_id,
    SUM(
        CASE
            WHEN exclusions IS NOT NULL
            OR extras IS NOT NULL THEN 1
            ELSE 0
        END
    ) AS 'Pizza with Changes',
    SUM(
        CASE
            WHEN exclusions IS NULL
            AND extras IS NULL THEN 1
            ELSE 0
        END
    ) AS 'Pizza with no Changes'
FROM customer_orders
GROUP BY customer_id;

-- How many pizzas were delivered that had both exclusions and extras?
SELECT COUNT(*) AS 'Pizz with both exclusions and extras'
FROM customer_orders
WHERE exclusions IS NOT NULL
    AND extras IS NOT NULL;

-- What was the total volume of pizzas ordered for each hour of the day?
SELECT DATEPART(HOUR, order_time) AS HourOfDay,
    COUNT(*) AS 'Number of Pizza each hour of the day'
FROM customer_orders
GROUP BY DATEPART(HOUR, order_time)
ORDER BY HourOfDay;

-- What was the volume of orders for each day of the week?
SELECT DATEPART(WEEK, order_time),
    COUNT(*) AS 'Number of Pizza each day of the week',
    (
        CASE
            WHEN DATEPART(WEEK, order_time) = '0' THEN 'SUN'
            WHEN DATEPART(WEEK, order_time) = '1' THEN 'MON'
            WHEN DATEPART(WEEK, order_time) = '2' THEN 'TUE'
            WHEN DATEPART(WEEK, order_time) = '3' THEN 'WED'
            WHEN DATEPART(WEEK, order_time) = '4' THEN 'THU'
            WHEN DATEPART(WEEK, order_time) = '5' THEN 'FRI'
            WHEN DATEPART(WEEK, order_time) = '6' THEN 'SAT'
        END
    ) AS 'Weekday'
FROM customer_orders
GROUP BY DATEPART(WEEK, order_time);


-- B. Runner and Customer Experience

-- How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT (DATEPART(WEEK, registration_date) + 1) AS 'Week of Year',
    COUNT(*) AS 'Runners Signed up'
FROM runners
GROUP BY DATEPART(WEEK, registration_date);

-- What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT runner_orders.runner_id,
    ROUND(
        AVG(
            (
                DATEDIFF(MINUTE,customer_orders.order_time,runner_orders.pickup_time)
            )
        ),
        2
    ) AS 'Avg TimeDiff'
FROM customer_orders
    JOIN runner_orders ON runner_orders.order_id = customer_orders.order_id
GROUP BY runner_id;

-- Is there any relationship between the number of pizzas and how long the order takes to prepare?
SELECT table1.order_id,
    pizzas,
    duration
FROM (
        SELECT order_id,
            COUNT(*) AS pizzas
        FROM customer_orders
        GROUP BY customer_orders.order_id
    ) AS table1
    JOIN runner_orders ON runner_orders.order_id = table1.order_id
ORDER BY duration DESC;

-- What was the average distance travelled for each customer?
SELECT table1.customer_id,
    AVG(TRY_CAST(table1.distance AS FLOAT)) AS 'Avg Distance travelled'
FROM (
        SELECT DISTINCT runner_orders.order_id,
            runner_orders.distance,
            customer_orders.customer_id
        from runner_orders
            INNER JOIN customer_orders ON customer_orders.order_id = runner_orders.order_id
    ) AS table1
GROUP BY table1.customer_id;

-- What was the difference between the longest and shortest delivery times for all orders?
SELECT (
        MAX(TRY_CAST(duration AS FLOAT)) - MIN(TRY_CAST(duration AS FLOAT))
    ) AS 'Diff between Max and Min'
FROM runner_orders;

-- What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT runner_orders.runner_id,
    runner_orders.order_id,
    ROUND(
        (runner_orders.distance * 1000.0) /(runner_orders.duration * 60),
        4
    ) AS 'Avg Speed',
    COUNT() AS 'Number of Pizzas'
FROM runner_orders
    JOIN customer_orders ON runner_orders.order_id = customer_orders.order_id
GROUP BY customer_orders.order_id;

-- What is the successful delivery percentage for each runner?
WITH CTE AS (
    SELECT runner_id,
        COUNT() AS 'Total_Orders',
        SUM(
            CASE
                WHEN cancellation IS NULL THEN 1
                ELSE 0
            END
        ) AS 'Successful_Orders'
    FROM runner_orders
    GROUP BY runner_id
)
SELECT runner_id,
    Total_Orders,
    Successful_Orders,
    ROUND((Successful_Orders * 1.0) / Total_Orders, 4) * 100 AS 'Percentage Success'
FROM CTE;

-- C. Ingredient Optimisation

-- What are the standard ingredients for each pizza?
-- SELECT STRING_SPLIT(toppings,',') from pizza_recipes;
-- What was the most commonly added extra?
-- What was the most common exclusion?
-- Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
-- Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
-- What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?


-- D. Pricing and Ratings

-- If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
-- What if there was an additional $1 charge for any pizza extras?
-- Add cheese is $1 extra
-- The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
-- Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
-- customer_id
-- order_id
-- runner_id
-- rating
-- order_time
-- pickup_time
-- Time between order and pickup
-- Delivery duration
-- Average speed
-- Total number of pizzas
-- If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?


-- E. Bonus Questions

-- If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?