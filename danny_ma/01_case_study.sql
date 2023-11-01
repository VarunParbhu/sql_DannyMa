USE dannys_diner;
-- What is the total amount each customer spent at the restaurant?
SELECT customer_id,SUM(price) AS total_spent FROM sales
LEFT JOIN menu
ON sales.product_id = menu.product_id
GROUP BY sales.customer_id;

-- How many days has each customer visited the restaurant?
SELECT DISTINCT customer_id, COUNT(*) OVER (PARTITION BY customer_id) AS TotalVisits FROM sales
GROUP BY customer_id, order_date;

-- What was the first item from the menu purchased by each customer?
SELECT sales.customer_id, MIN(sales.order_date) AS 'order_date',MIN(menu.product_name) AS 'menu item' FROM sales
LEFT JOIN menu
ON sales.product_id = menu.product_id
GROUP BY customer_id;

-- What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT TOP 1 menu.product_name, COUNT(*) AS total_bought FROM sales
LEFT JOIN menu
ON menu.product_id = SALES.product_id
GROUP BY sales.product_id,menu.product_name
ORDER BY total_bought DESC;

-- Which item was the most popular for each customer?

WITH table2 AS (
    SELECT 
            * , 
            ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY total_item DESC) AS rn 
            FROM (
                    SELECT 
                        customer_id, 
                        product_name, 
                        COUNT(product_name) AS total_item 
                    FROM 
                        sales
                    LEFT JOIN 
                        menu
                    ON 
                        sales.product_id = menu.product_id
                    GROUP BY 
                        customer_id, product_name
                ) AS table3)
SELECT customer_id,product_name,total_item FROM table2
WHERE rn = 1;


-- -- Which item was purchased first by the customer after they became a member?
-- WITH CTE AS (
-- SELECT sales.customer_id, sales.order_date,members.join_date, menu.product_name FROM sales
-- LEFT JOIN menu
-- ON menu.product_id = sales.product_id
-- LEFT JOIN members
-- ON members.customer_id = sales.customer_id
-- WHERE sales.order_date > members.join_date
-- )
-- SELECT customer_id, MIN(order_date),join_date,product_name
-- FROM CTE
-- GROUP BY customer_id;

-- -- Which item was purchased just before the customer became a member?
-- WITH CTE AS (
-- SELECT sales.customer_id, sales.order_date,members.join_date, menu.product_name FROM sales
-- LEFT JOIN menu
-- ON menu.product_id = sales.product_id
-- LEFT JOIN members
-- ON members.customer_id = sales.customer_id
-- WHERE sales.order_date <= members.join_date
-- )
-- SELECT customer_id, MAX(order_date),join_date,product_name
-- FROM CTE
-- GROUP BY customer_id;

-- -- What is the total items and amount spent for each member before they became a member?
-- SELECT sales.customer_id, SUM(menu.price) AS total_spent
-- FROM sales
-- LEFT JOIN members
-- ON members.customer_id = sales.customer_id
-- LEFT JOIN menu
-- on menu.product_id = sales.product_id
-- WHERE members.join_date <= sales.order_date
-- GROUP BY sales.customer_id;

-- -- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- SELECT customer_id, sales.product_id, menu.price,
--     SUM(
--         CASE
--             WHEN menu.product_name != 'sushi' THEN 10*menu.price
--             WHEN menu.product_name  = 'sushi' THEN 20*menu.price
--         END
--     ) AS points
-- FROM sales
-- LEFT JOIN menu
-- ON menu.product_id = sales.product_id
-- GROUP BY customer_id;

-- -- In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
-- SELECT sales.customer_id, sales.product_id, menu.price,
--     SUM(
--         CASE
--             WHEN sales.order_date BETWEEN members.join_date AND DATE(members.join_date,'+7 days') THEN
--                 (menu.price*20)
--             ELSE
--                 CASE
--                     WHEN menu.product_name != 'sushi' THEN 10*menu.price
--                     WHEN menu.product_name  = 'sushi' THEN 20*menu.price
--                 END
--         END
--     ) AS points
-- FROM sales
-- LEFT JOIN menu
-- ON menu.product_id = sales.product_id
-- LEFT JOIn members
-- on sales.customer_id = members.customer_id
-- GROUP BY sales.customer_id;

-- -- BONUS Question - Create a table that indicates whether the order is from a member or not
-- SELECT sales.customer_id, sales.order_date, menu.product_name, menu.price,
-- CASE
--     WHEN order_date < join_date THEN 'N'
--     WHEN join_date IS NULL THEN 'N'
--     ELSE 'Y'
-- END AS member
-- FROM sales
-- LEFT JOIN menu
-- ON sales.product_id = menu.product_id
-- LEFT JOIN members
-- ON sales.customer_id = members.customer_id;

-- -- BONUS Question - Create a table that indicates the ranking of the products when bought after becoming a member

-- WITH CTE AS (
-- SELECT sales.customer_id, sales.order_date, menu.product_name, menu.price,
-- CASE
--     WHEN order_date < join_date THEN 'N'
--     WHEN join_date IS NULL THEN 'N'
--     ELSE 'Y'
-- END AS member
-- FROM sales
-- LEFT JOIN menu
-- ON sales.product_id = menu.product_id
-- LEFT JOIN members
-- ON sales.customer_id = members.customer_id)
-- SELECT *
-- ,
-- CASE 
--     WHEN member = 'Y' THEN RANK() OVER (PARTITION BY customer_id,member ORDER by customer_id,order_date ASC)
--     ELSE NULL
-- END AS ranking
-- FROM CTE
-- ;