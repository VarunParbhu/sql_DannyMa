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

-- ALTER TABLE pizza_names
-- ALTER COLUMN pizza_name VARCHAR(20);


-- SELECT table1.pizza_id,
--     pizza_toppings.topping_id,
--     pizza_toppings.topping_name INTO pizza_recipes_temp
-- FROM (
--         SELECT pizza_id,
--             trim(value) AS toppings_list
--         FROM pizza_recipes
--             CROSS APPLY STRING_SPLIT(TRY_CAST(toppings AS nvarchar(50)), ',')
--     ) AS table1
--     JOIN pizza_toppings ON pizza_toppings.topping_id = table1.toppings_list;

-- ALTER TABLE pizza_recipes_temp
-- ALTER COLUMN topping_name NVARCHAR(25);

-- ALTER TABLE runner_orders
-- ALTER COLUMN pickup_time Datetime;

-- ALTER TABLE runner_orders
-- ALTER COLUMN distance float;

-- ALTER TABLE runner_orders
-- ALTER COLUMN duration float;

-- ALTER TABLE pizza_recipes
-- ALTER COLUMN toppings NVARCHAR(50);


-- A. Pizza Metrics

-- How many pizzas were ordered? - 17
SELECT COUNT(order_id) AS 'Pizzas Ordered'
FROM customer_orders;

-- How many unique customer orders were made? - 13
SELECT COUNT(DISTINCT order_id) AS 'Unique Orders'
FROM customer_orders;

-- How many successful orders were delivered by each runner? - 8
SELECT COUNT(*) AS 'Successful Orders'
FROM runner_orders
WHERE pickup_time IS NOT NULL
    AND distance IS NOT NULL
    AND duration IS NOT NULL;

-- How many of each type of pizza was delivered? ML(13)-Veg(4)
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

-- What was the maximum number of pizzas delivered in a single order? - 3
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

-- How many pizzas were delivered that had both exclusions and extras? - 3
SELECT COUNT(*) AS 'Pizza with both exclusions and extras'
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
SELECT DATEPART(WEEK, order_time) AS WeekDayID,
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

-- Is there any relationship between the number of pizzas and how long the order takes to prepare? - TO BE RE-DONE
SELECT pizzaNumTable.order_id,
    pizzaNumTable.pizzaNum,
    DATEDIFF(
        MINUTE,
        pizzaNumTable.order_time,
        runner_orders.pickup_time
    ) AS "Prep Time"
FROM (
        SELECT order_id,
            order_time,
            COUNT(*) AS pizzaNum
        FROM customer_orders
        GROUP BY order_id,
            order_time
    ) AS pizzaNumTable
    JOIN runner_orders ON runner_orders.order_id = pizzaNumTable.order_id
ORDER BY pizzaNum DESC;

-- What was the average distance travelled for each customer?
SELECT table1.customer_id,
        AVG(table1.distance)
FROM (
        SELECT DISTINCT runner_orders.order_id,
            runner_orders.distance,
            customer_orders.customer_id
        from runner_orders
            INNER JOIN customer_orders ON customer_orders.order_id = runner_orders.order_id
    ) AS table1
GROUP BY table1.customer_id;

-- What was the difference between the longest and shortest delivery times for all orders? - 30min
SELECT (
        MAX(duration) - MIN(duration)
    ) AS 'Diff between Max and Min'
FROM runner_orders;

-- What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT runner_orders.order_id,
    FORMAT(
        ROUND(
            (runner_orders.distance * 1000.0) /(runner_orders.duration * 60),
            4
        ),
        'N2'
    ) AS 'Avg Speed',
    table1.numOfPizza
FROM (
        SELECT order_id,
            COUNT(*) AS numOfPizza
        FROM customer_orders
        GROUP BY order_id
    ) AS table1
    JOIN runner_orders ON runner_orders.order_id = table1.order_id
    ORDER BY numOfPizza DESC;

-- What is the successful delivery percentage for each runner?
WITH CTE AS (
    SELECT runner_id,
        COUNT(*) AS 'Total_Orders',
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
    FORMAT(
        ((Successful_Orders * 1.0) / Total_Orders) * 100,
        'N2'
    ) AS 'Percentage Success'
FROM CTE;

-- C. Ingredient Optimisation

-- What are the standard ingredients for each pizza?
SELECT pizza_name,
    con AS 'Receipe'
FROM (
        SELECT toppings_table.pizza_id,
            STRING_AGG(topping_name, ', ') As con
        FROM (
                SELECT pizza_id,
                    TRIM(value) AS toppings
                FROM pizza_recipes
                    CROSS APPLY string_split(toppings, ',')
            ) AS toppings_table
            JOIN pizza_toppings ON pizza_toppings.topping_id = toppings_table.toppings
        GROUP BY pizza_id
    ) AS table2
JOIN pizza_names ON pizza_names.pizza_id = table2.pizza_id;

-- What was the most commonly added extra? - Baconx4
SELECT pizza_toppings.topping_name,
    result_table.total_extra
FROM (
        SELECT extra,
            COUNT(extra) AS total_extra
        FROM (
                SELECT TRIM(value) AS extra
                FROM customer_orders
                    CROSS APPLY string_split(extras, ',')
            ) AS extra_table
        GROUP BY extra
    ) AS result_table
    JOIN pizza_toppings ON pizza_toppings.topping_id = result_table.extra
ORDER BY total_extra DESC;

-- What was the most common exclusion? - Cheesex4
SELECT pizza_toppings.topping_name,
    result_table.total_excl
FROM (
        SELECT exclusion,
            COUNT(exclusion) AS total_excl
        FROM (
                SELECT TRIM(value) AS exclusion
                FROM customer_orders
                    CROSS APPLY string_split(exclusions, ',')
            ) AS exclusion_table
        GROUP BY exclusion
    ) AS result_table
    JOIN pizza_toppings ON pizza_toppings.topping_id = result_table.exclusion
ORDER BY total_excl DESC;

-- Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
WITH CTE AS (
    SELECT order_id,
        customer_id,
        pizza_name,
        (
            CASE
                WHEN (exclusions IS NULL) THEN ''
                ELSE (
                    SELECT STRING_AGG(pizza_toppings.topping_name, ', ')
                    FROM (
                            SELECT TRIM(VALUE) AS topping_id
                            FROM string_split(exclusions, ',')
                        ) AS topping_table
                        JOIN pizza_toppings ON pizza_toppings.topping_id = topping_table.topping_id
                )
            END
        ) As exlc,
        (
            CASE
                WHEN (extras IS NULL) THEN ''
                ELSE (
                    SELECT STRING_AGG(pizza_toppings.topping_name, ', ')
                    FROM (
                            SELECT TRIM(VALUE) AS topping_id
                            FROM string_split(extras, ',')
                        ) AS topping_table
                        JOIN pizza_toppings ON pizza_toppings.topping_id = topping_table.topping_id
                )
            END
        ) As extrs
    FROM customer_orders
        JOIN pizza_names ON pizza_names.pizza_id = customer_orders.pizza_id
)
SELECT order_id,
    customer_id,
    (pizza_name + ' - Exclude ' + exlc + ' - Extra ' + extrs) AS order_item
FROM CTE;

-- Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
WITH cu_order AS (
    SELECT ROW_NUMBER() OVER (
            ORDER BY order_id
        ) AS record_id,
        *
    FROM customer_orders
),
exclu_table AS (
    SELECT cu_order.record_id,
        TRIM(VALUE) AS exclu
    FROM cu_order
        CROSS APPLY string_split(cu_order.exclusions, ',')
),
ext_table AS (
    SELECT cu_order.record_id,
        TRIM(VALUE) AS ext
    FROM cu_order
        CROSS APPLY string_split(cu_order.extras, ',')
),
CTE_ING AS(
    SELECT record_id,
        order_id,
        pizza_name,
        pizza_recipes_temp.topping_name,
        (
            CASE
                WHEN topping_id IN (
                    SELECT ext
                    FROM ext_table
                    WHERE ext_table.record_id = cu_order.record_id
                ) THEN ('2x' + topping_name)
                ELSE topping_name
            END
        ) AS topping
    FROM cu_order
        JOIN pizza_names ON pizza_names.pizza_id = cu_order.pizza_id
        JOIN pizza_recipes_temp ON pizza_recipes_temp.pizza_id = cu_order.pizza_id
    WHERE pizza_recipes_temp.topping_id NOT IN (
            SELECT exclu
            FROM exclu_table
            WHERE exclu_table.record_id = cu_order.record_id
        )
)
SELECT record_id,
    order_id,
    CONCAT(
        pizza_name + ':',
        STRING_AGG(topping, ',') WITHIN GROUP (
            ORDER BY topping_name ASC
        )
    ) AS ingredient
FROM CTE_ING
GROUP BY record_id,
    order_id,
    pizza_name
ORDER BY record_id,
    order_id,
    pizza_name;

-- What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
WITH cu_order AS (
    SELECT ROW_NUMBER() OVER (
            ORDER BY order_id
        ) AS record_id,
        *
    FROM customer_orders
),
exclu_table AS (
    SELECT cu_order.record_id,
        TRIM(VALUE) AS exclu
    FROM cu_order
        CROSS APPLY string_split(cu_order.exclusions, ',')
),
ext_table AS (
    SELECT cu_order.record_id,
        TRIM(VALUE) AS ext
    FROM cu_order
        CROSS APPLY string_split(cu_order.extras, ',')
),
total_ing AS (
    SELECT pizza_recipes_temp.topping_name,
        (
            CASE
                WHEN topping_id IN (
                    SELECT ext
                    FROM ext_table
                    WHERE ext_table.record_id = cu_order.record_id
                ) THEN (2)
                ELSE 1
            END
        ) AS topping
    FROM cu_order
        JOIN pizza_names ON pizza_names.pizza_id = cu_order.pizza_id
        JOIN pizza_recipes_temp ON pizza_recipes_temp.pizza_id = cu_order.pizza_id
        JOIN runner_orders ON runner_orders.order_id = cu_order.order_id
    WHERE pizza_recipes_temp.topping_id NOT IN (
            SELECT exclu
            FROM exclu_table
            WHERE exclu_table.record_id = cu_order.record_id
        )
        AND runner_orders.cancellation IS NULL
)
SELECT topping_name,
    SUM(topping) AS total_ingredients
FROM total_ing
GROUP BY topping_name
ORDER BY SUM(topping) DESC;

-- D. Pricing and Ratings

-- If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
SELECT SUM (
        CASE
            WHEN pizza_id = 1 THEN 12
            WHEN pizza_id = 2 THEN 10
        END
    ) AS cost
FROM customer_orders
    JOIN runner_orders ON customer_orders.order_id = runner_orders.order_id
WHERE runner_orders.cancellation IS NULL;

-- What if there was an additional $1 charge for any pizza extras?
-- Add cheese is $1 extra
WITH cu_order AS (
    SELECT ROW_NUMBER() OVER (
            ORDER BY order_id
        ) AS record_id,
        *
    FROM customer_orders
),
exclu_table AS (
    SELECT cu_order.record_id,
        TRIM(VALUE) AS exclu
    FROM cu_order
        CROSS APPLY string_split(cu_order.exclusions, ',')
),
ext_table AS (
    SELECT cu_order.record_id,
        TRIM(VALUE) AS ext
    FROM cu_order
        CROSS APPLY string_split(cu_order.extras, ',')
),
extra_cost_table AS (
    SELECT ext_table.record_id,
        COUNT(ext_table.record_id) AS cost
    FROM ext_table
    GROUP BY ext_table.record_id
)
SELECT SUM (
        CASE
            WHEN pizza_id = 1 THEN (
                CASE
                    WHEN cu_order.extras IS NULL THEN 12
                    WHEN cu_order.extras IS NOT NULL THEN (extra_cost_table.cost + 12)
                END
            )
            WHEN pizza_id = 2 THEN (
                CASE
                    WHEN cu_order.extras IS NULL THEN 10
                    WHEN cu_order.extras IS NOT NULL THEN (extra_cost_table.cost + 10)
                END
            )
        END
    ) AS cost
FROM cu_order
    JOIN runner_orders ON cu_order.order_id = runner_orders.order_id
    LEFT JOIN extra_cost_table ON extra_cost_table.record_id = cu_order.record_id
WHERE runner_orders.cancellation IS NULL;

-- The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
DROP TABLE IF EXISTS ratings CREATE TABLE ratings (order_id INTEGER, rating INTEGER);
INSERT INTO ratings (order_id, rating)
VALUES (1, 3),
    (2, 4),
    (3, 5),
    (4, 2),
    (5, 1),
    (6, 3),
    (7, 4),
    (8, 1),
    (9, 3),
    (10, 5);

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
WITH pizzNum AS (
    SELECT order_id,
        count(order_id) AS numOfPizza
    FROM customer_orders
    GROUP BY customer_orders.order_id
)
SELECT DISTINCT customer_id,
    customer_orders.order_id,
    runner_id,
    rating,
    order_time,
    pickup_time,
    DATEDIFF(MINUTE, order_time, pickup_time) AS 'prep time',
    duration,
    FORMAT(
        ROUND(
            (
                (
                    runner_orders.distance /(runner_orders.duration / 60)
                )
            ),
            4
        ),
        'N2'
    ) AS 'Avg Km/h',
    numOfPizza AS 'Number of Pizza'
from customer_orders
    JOIN runner_orders on customer_orders.order_id = runner_orders.order_id
    JOIN ratings on customer_orders.order_id = ratings.order_id
    JOIN pizzNum on pizzNum.order_id = customer_orders.order_id
WHERE runner_orders.cancellation IS NULL
ORDER BY order_id;

-- If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
SELECT (
        SELECT SUM (
                CASE
                    WHEN pizza_id = 1 THEN 12
                    WHEN pizza_id = 2 THEN 10
                END
            ) AS cost
        FROM customer_orders
            JOIN runner_orders ON customer_orders.order_id = runner_orders.order_id
        WHERE runner_orders.cancellation IS NULL
    ) - (
        SELECT SUM(distance * 0.3) AS order_delivery_cost
        FROM runner_orders
    ) AS moneyLeft;

-- E. Bonus Questions

-- If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?
SELECT *
FROM pizza_names;

INSERT INTO pizza_names
VALUES (3, 'Supreme');

SELECT *
FROM pizza_names;

INSERT INTO pizza_recipes_temp
VALUES (3, 1, 'Bacon'),
    (3, 2, 'BBQ Sauce'),
    (3, 3, 'Beef'),
    (3, 4, 'Cheese'),
    (3, 5, 'Chicken'),
    (3, 6, 'Mushrooms'),
    (3, 7, 'Onions'),
    (3, 8, 'Pepperoni'),
    (3, 9, 'Peppers'),
    (3, 10, 'Salami'),
    (3, 11, 'Tomatoes'),
    (3, 12, 'Tomato Sauce');
    
SELECT *
FROM pizza_recipes_temp;