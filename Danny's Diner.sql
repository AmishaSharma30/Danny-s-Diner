-- Danny's Diner Case Study

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT * FROM members;
SELECT * FROM menu;
SELECT * FROM sales;

-- 1.
SELECT a.customer_id, SUM(b.price) AS total_amount
FROM sales AS a
JOIN menu AS b
ON a.product_id = b.product_id
GROUP BY a.customer_id
ORDER BY a.customer_id;

-- 2.
SELECT customer_id, COUNT(DISTINCT order_date) AS total_days
FROM sales
GROUP BY customer_id
ORDER BY customer_id;

-- 3.
SELECT customer_id, order_date, product_name
FROM(
SELECT a.customer_id, b.product_name, a.order_date,
RANK() OVER (PARTITION BY customer_id ORDER BY order_date) AS rnk
FROM sales AS a
JOIN menu AS b
ON a.product_id = b.product_id
GROUP BY a.customer_id, b.product_name, a.order_date) AS x
WHERE x.rnk = 1;

-- 4.
WITH temp AS
(SELECT product_name, COUNT(*) AS total
FROM sales AS a
JOIN menu AS b
ON a.product_id = b.product_id
GROUP BY product_name),
temp2 AS
(SELECT MAX(total) AS max_num FROM temp)
SELECT product_name, total AS most_purchased_item_count
FROM temp
WHERE total = (SELECT max_num FROM temp2);

-- 5.
WITH t_table AS
(SELECT customer_id, product_name, COUNT(a.product_id) AS total_cnt
FROM sales AS a
JOIN menu AS b
ON a.product_id = b.product_id 
GROUP BY customer_id, product_name
ORDER BY customer_id)
SELECT customer_id, product_name
FROM t_table
WHERE (customer_id, total_cnt) IN (SELECT customer_id, MAX(total_cnt) AS max_cnt FROM t_table GROUP BY customer_id);

-- 5. (Another way to solve)
WITH t_table AS
(SELECT customer_id, product_name, COUNT(a.product_id) AS total_cnt
FROM sales AS a
JOIN menu AS b
ON a.product_id = b.product_id 
GROUP BY customer_id, product_name
ORDER BY customer_id)
SELECT customer_id, customer_id
FROM 
(SELECT customer_id, product_name, RANK() OVER(PARTITION BY customer_id ORDER BY total_cnt DESC) AS rnk
FROM t_table) AS x
WHERE x.rnk = 1;

-- 6.
SELECT customer_id, order_date, product_name
FROM(
SELECT a.customer_id, order_date, product_name, join_date,
RANK() OVER(PARTITION BY a.customer_id ORDER BY order_date) AS rnk
FROM sales AS a
JOIN members AS b
ON (a.order_date = b.join_date
OR a.order_date > b.join_date)
AND a.customer_id = b.customer_id
JOIN menu AS c
ON a.product_id = c.product_id) AS y
WHERE y.rnk = 1;

-- 7.
SELECT customer_id, order_date, product_name
FROM(
SELECT a.customer_id, order_date, product_name, join_date,
RANK() OVER(PARTITION BY a.customer_id ORDER BY order_date DESC) AS rnk
FROM sales AS a
JOIN members AS b
ON a.order_date < b.join_date
AND a.customer_id = b.customer_id
JOIN menu AS c
ON a.product_id = c.product_id) AS z
WHERE z.rnk = 1;

-- 8.
SELECT a.customer_id, COUNT(product_name) AS total_items, SUM(price) AS total_amount
FROM sales AS a
JOIN members AS b
ON a.order_date < b.join_date
AND a.customer_id = b.customer_id
JOIN menu AS c
ON a.product_id = c.product_id
GROUP BY a.customer_id
ORDER BY a.customer_id;

-- 9.
WITH temp AS
(SELECT a.customer_id,
CASE WHEN product_name = 'sushi' THEN 2 *(price * 10)
	 ELSE price * 10
	 END AS total_points
FROM sales AS a
JOIN menu AS b
ON a.product_id = b.product_id
ORDER BY a.customer_id)
SELECT customer_id, SUM(total_points) AS total_points
FROM temp
GROUP BY customer_id
ORDER BY customer_id;

-- 10.
WITH temp AS
(SELECT a.customer_id, CASE WHEN order_date - join_date < 6
			THEN 2 * (price * 10)
			ELSE 
				(CASE WHEN product_name = 'sushi' THEN 2 * (price * 10)
				      ELSE price * 10 
					  END)
			END AS total_points
FROM sales AS a
JOIN members AS b
ON a.order_date >= b.join_date
AND a.customer_id = b.customer_id
JOIN menu AS c
ON a.product_id = c.product_id
ORDER BY a.customer_id)
SELECT customer_id, SUM(total_points) AS total_points
FROM temp
GROUP BY customer_id;


















