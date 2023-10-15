-- What is the total amount each customer spent at the restaurant?
SELECT customer_id,SUM(price) AS total_spent FROM sales
LEFT JOIN menu
ON sales.product_id = menu.product_id
GROUP BY sales.customer_id;

-- How many days has each customer visited the restaurant?
SELECT DISTINCT customer_id, COUNT(*) OVER (PARTITION BY customer_id) AS TotalRecords FROM sales
GROUP BY customer_id, order_date
;


-- What was the first item from the menu purchased by each customer?





-- What is the most purchased item on the menu and how many times was it purchased by all customers?
-- Which item was the most popular for each customer?
-- Which item was purchased first by the customer after they became a member?
-- Which item was purchased just before the customer became a member?
-- What is the total items and amount spent for each member before they became a member?
-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?