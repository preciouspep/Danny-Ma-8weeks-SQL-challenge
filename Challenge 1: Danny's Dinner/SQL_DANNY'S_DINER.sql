----WEEK 1 of Dannys diner 8-Weeks SQL Challenge--- DANNY"S DINNER

--Create dannys_dinner database and the dataset
DROP DATABASE IF EXISTS dannys_dinner
Create Database dannys_dinner

---create the sales table
CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

----insert data into sales table
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
 

 ---create the menu table
CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

---insert data into the menu table
INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

----create the members table
CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

----inserting data into members table
INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

 SELECT *
 FROM menu;

 SELECT *
 FROM  members;

 SELECT *
 FROM sales;

  ----CASE STUDY QUESTIONS

  ---QUESTION 1: What is the total amount each customer spent at the restaurant?

 
  SELECT s.customer_id, sum(m.price) as total_amount_spent_in_dollars
  FROM sales as s
  JOIN menu as m
  ON s.product_id = m.product_id
  group by s.customer_id;

  
  ---- QUESTION 2:How many days has each customer visted the restaurant?

  SELECT customer_id, COUNT(Distinct(DAY(order_date))) as No_of_days
  FROM sales
  group by customer_id;


  ----Question 3: What was the first item from the menu purchased by each customer?

With new_table as (
  Select customer_id, min(order_date) as first_day
  from sales
  Group by customer_id
  )
Select distinct N.customer_id, S.order_date, S.product_id, M.product_name
from sales as S
join new_table as N
on N.first_day = S.order_date
and N.customer_id = S.customer_id
join menu as M
on S.product_id = M.product_id;



-----Question 4: What is the most purchased item on the menu and how many times was it purchased by all customers?

Select M.product_name, count(S.product_id)as Total_orders
from sales as S
join menu as M
on S.product_id = M.product_id
Group by M.product_name
order by 2 desc;

----Question 5: Which item was the most popular for each customer?

SELECT customer_id, most_popular, no_of_orders
FROM ( SELECT S.customer_id, M.product_name as most_popular, COUNT(S.product_id) AS no_of_orders,
         RANK() 
		 OVER(PARTITION BY customer_id ORDER BY COUNT(S.product_id) DESC) AS row_no
		FROM sales as S 
		JOIN menu as M
		ON M.product_id = S.product_id
		GROUP BY S.customer_id, M.product_name 
	 ) as NEW
WHERE row_no = 1



----QUESTION 6: Which item was purchased first by the customer after they became a member?	

SELECT customer_id, join_date, order_date, product_name
FROM ( SELECT s.customer_id, s.order_date, m.product_name, N.join_date,
		RANK()
		OVER(PARTITION BY s.customer_id ORDER BY s.order_date) as row_no
		FROM sales as s
		join menu as m
		ON s.product_id = m.product_id
		join members as N
		on s.customer_id = N.customer_id
		where s.order_date > N.join_date
		) as purchase_from_first_day_joined
where row_no = 1

----QUESTION 7: Which item was purchased just before the customer became a member?

SELECT customer_id, order_date, join_date, product_name
FROM ( SELECT s.customer_id, s.order_date, m.product_name, N.join_date,
		RANK()
		OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) as row_no
		FROM sales as s
		join menu as m
		ON s.product_id = m.product_id
		join members as N
		on s.customer_id = N.customer_id
		where s.order_date < N.join_date
		) as purchase_from_first_joined_date
where row_no = 1


---Question 8: What is the total items and amount spent for each member before they became a member?

With new_table as 
(
SELECT customer_id, count(product_id) as count, price*count(product_id) as cost
from (
		SELECT s.customer_id, s.order_date,s.product_id, m.product_name, m.price, N.join_date
		FROM sales as s
		join menu as m
		ON s.product_id = m.product_id
		join members as N
		on s.customer_id = N.customer_id
		where s.order_date < N.join_date
		) as N
Group by customer_id,price
)
SELECT customer_id, sum(count) as total_items_bought, concat('$', sum(cost)) as total_cost
from new_table
group by customer_id

--- ALTERNATIVE QUERY

SELECT customer_id, count(product_id) as count, concat('$', sum(price)) as cost
from (
		SELECT s.customer_id, s.order_date,s.product_id, m.product_name, m.price, N.join_date
		FROM sales as s
		join menu as m
		ON s.product_id = m.product_id
		join members as N
		on s.customer_id = N.customer_id
		where s.order_date < N.join_date
		) as N
Group by customer_id;

----Question 9:If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT customer_id, 
		SUM(CASE WHEN product_name = 'sushi' THEN 10 * 2 * price 
				ELSE 10 * price
				END) as total_points
FROM sales as s
JOIN menu as m
ON s.product_id = m.product_id
Group by customer_id;

----Question 10:
---In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi 
---how many points do customer A and B have at the end of January?


WITH sub_table as (
SELECT s.customer_id, s.order_date, m.product_name,m.price, N.join_date
		FROM sales as s
		join menu as m
		ON s.product_id = m.product_id
		join members as N
		on s.customer_id = N.customer_id
		where s.order_date >= N.join_date AND MONTH(s.order_date) = 01
		)
SELECT customer_id, SUM( CASE 
							WHEN order_date BETWEEN join_date AND DATEADD(DAY,7,join_date) THEN 10 *2 * price
							ELSE 10* price END) as total_points
FROM sub_table
GROUP BY customer_id


---BONUS QUESTIONS: JOIN ALL THINGS
CREATE VIEW merged_data as 
SELECT s.customer_id, s.order_date,m.product_name, m.price,
		CASE 
			WHEN s.order_date < N.join_date then 'N'
			WHEN N.join_date is NULL then 'N' 
			ELSE 'Y' END as member
FROM sales as s
join menu as m
ON s.product_id = m.product_id
left join members as N
on s.customer_id = N.customer_id;


---Rank all things

WITH sub_table as (
SELECT s.customer_id, s.order_date,m.product_name, m.price,
		CASE 
			WHEN s.order_date < N.join_date then 'N' 
			WHEN N.join_date is NULL then 'N' 
			else 'Y' END as member
FROM sales as s
join menu as m
ON s.product_id = m.product_id
left join members as N
on s.customer_id = N.customer_id
)
SELECT customer_id,order_date, product_name, price, member,
			CASE
				WHEN member = 'Y' then		
			RANK()
			OVER(PARTITION BY customer_id,member order by order_date )
		END as ranking
FROM sub_table


---- ALternative Query: using the view table created earlier
SELECT customer_id,order_date, product_name, price, member,
			CASE
				WHEN member = 'Y' then		
			RANK()
			OVER(PARTITION BY customer_id,member order by order_date )
		END as ranking
FROM merged_data


---THANK YOU FOR READING.
