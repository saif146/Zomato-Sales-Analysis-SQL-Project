# 🍔 Zomato Sales Analysis — SQL Project

A complete end-to-end SQL case study analyzing customer orders, revenue, product demand, and the Zomato Gold loyalty program using PostgreSQL. The project covers everything from schema design to advanced window-function analytics, answering 17 real-world business questions a food-delivery analytics team would actually ask.

---

## 📌 Project Overview

This project simulates a Zomato-style sales database with four core tables — **users**, **products**, **sales**, and **gold_users** — and uses pure SQL to extract actionable business insights: revenue trends, customer loyalty behavior, product popularity, and a custom rewards-points engine.

**Tools used:** PostgreSQL, SQL (CTEs, Window Functions, Joins, Aggregations)

---

## 🗂️ Database Schema

| Table | Description |
|---|---|
| `users` | Customer ID, signup date, and address |
| `products` | Product catalog with name and price |
| `sales` | Order-level transactional data (date, quantity, product, customer) |
| `gold_users` | Customers enrolled in the Zomato Gold membership program |

```sql
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    signup_date DATE,
    address VARCHAR(200)
);

CREATE TABLE products (
    products_id INT PRIMARY KEY,
    product_name VARCHAR(30),
    price VARCHAR(20),
    price_i INT
);

CREATE TABLE gold_users (
    user_id INT,
    gold_signup_date DATE,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE sales (
    order_id INT PRIMARY KEY,
    user_id INT,
    order_date DATE,
    products_id INT,
    qty INT,
    year VARCHAR(20),
    month INT,
    month_name VARCHAR(20),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (products_id) REFERENCES products(products_id)
);
```

---

## 💡 Business Questions & SQL Solutions

### Q1. What is the total revenue generated so far?

```sql
SELECT SUM(s.qty * p.price_i) AS total_revenue
FROM sales AS s
JOIN products AS p
  ON s.products_id = p.products_id;
```

---

### Q2. Who are the top 5 customers by revenue, and what is their membership status (Gold / Regular)?

```sql
SELECT a.user_id,
       SUM(a.qty * p.price_i) AS revenue,
       CASE
           WHEN a.user_id IN (SELECT g.user_id FROM gold_users AS g) THEN 'Gold'
           ELSE 'Regular'
       END AS status
FROM sales AS a
JOIN users AS u ON a.user_id = u.user_id
JOIN products AS p ON a.products_id = p.products_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;
```

---

### Q3. What are the top 5 and bottom 5 most popular products by demand?

```sql
(SELECT p.products_id, p.product_name, COUNT(p.products_id) AS repeated_products, 'Top 5' AS tag
 FROM sales AS s
 JOIN products AS p ON s.products_id = p.products_id
 GROUP BY 1, 2
 ORDER BY 3 DESC
 LIMIT 5)

UNION

(SELECT p.products_id, p.product_name, COUNT(p.products_id) AS repeated_products, 'Bottom 5' AS tag
 FROM sales AS s
 JOIN products AS p ON s.products_id = p.products_id
 GROUP BY 1, 2
 ORDER BY 3 ASC
 LIMIT 5);
```

---

### Q4. Which products are low in demand and need promotional offers?

```sql
SELECT p.products_id, p.product_name, COUNT(p.products_id) AS repeated_products
FROM sales AS s
JOIN products AS p ON s.products_id = p.products_id
GROUP BY 1, 2
ORDER BY 3 ASC
LIMIT 5;
```

---

### Q5. How many days has each customer visited Zomato to place an order?

```sql
SELECT user_id,
       COUNT(DISTINCT order_date) AS visit
FROM sales
GROUP BY user_id
ORDER BY visit DESC;
```

---

### Q6. What was the first product purchased by each of the top 5 customers?

```sql
WITH cte_table AS (
    SELECT s.user_id AS user_id,
           SUM(s.qty * p.price_i) AS total_amount
    FROM sales AS s
    JOIN products AS p ON s.products_id = p.products_id
    GROUP BY 1
    ORDER BY 2 DESC
    LIMIT 5
)

SELECT * FROM (
    SELECT s.user_id,
           s.order_date,
           p.product_name,
           ROW_NUMBER() OVER (
               PARTITION BY s.user_id
               ORDER BY s.order_date ASC
           ) AS rnk
    FROM sales AS s
    JOIN products AS p ON s.products_id = p.products_id
    WHERE s.user_id IN (SELECT user_id FROM cte_table)
) b
WHERE rnk = 1;
```

---

### Q7. Which products are most likely to be the first pick for new customers?

```sql
WITH cte_table AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY user_id
               ORDER BY order_date ASC
           ) AS rnk
    FROM sales
)

SELECT products_id,
       COUNT(products_id) AS repeated_first_order
FROM cte_table
WHERE rnk <= 1
GROUP BY 1
ORDER BY 2 DESC;
```

---

### Q8. What is the most purchased item on the menu overall, and how many times was it bought?

```sql
SELECT s.products_id, p.product_name, COUNT(s.products_id) AS total_no_of_sales
FROM sales AS s
JOIN products AS p ON s.products_id = p.products_id
GROUP BY 1, 2
ORDER BY 2 DESC;
```

---

### Q9. How many times was the most purchased item bought by each individual customer?

```sql
WITH cte_table AS (
    SELECT products_id,
           COUNT(products_id) AS total_count
    FROM sales
    GROUP BY 1
    ORDER BY 2 DESC
    LIMIT 1
)

SELECT user_id,
       products_id,
       COUNT(products_id) AS total_no
FROM sales
WHERE products_id IN (SELECT products_id FROM cte_table)
GROUP BY 1, 2
ORDER BY 3 DESC;
```

---

### Q10. Which item was the most popular for each individual customer?

```sql
SELECT * FROM (
    SELECT user_id,
           products_id,
           COUNT(products_id),
           ROW_NUMBER() OVER (
               PARTITION BY user_id
               ORDER BY COUNT(products_id) DESC
           ) AS rnk
    FROM sales
    GROUP BY 1, 2
) t
WHERE rnk <= 1
ORDER BY 1;
```

---

### Q11. Which item was first purchased by a customer right after they became a Gold member?

```sql
SELECT * FROM (
    SELECT g.user_id,
           s.products_id,
           s.order_date,
           g.gold_signup_date,
           ROW_NUMBER() OVER (
               PARTITION BY g.user_id
               ORDER BY s.order_date ASC
           ) AS rnk
    FROM gold_users AS g
    JOIN sales AS s ON g.user_id = s.user_id
    WHERE g.gold_signup_date <= s.order_date
) t
WHERE rnk <= 1
ORDER BY 1;
```

---

### Q12. Which item was purchased right before a customer became a Gold member?

```sql
SELECT * FROM (
    SELECT g.user_id,
           s.products_id,
           s.order_date,
           g.gold_signup_date,
           ROW_NUMBER() OVER (
               PARTITION BY g.user_id
               ORDER BY s.order_date DESC
           ) AS rnk
    FROM gold_users AS g
    JOIN sales AS s ON g.user_id = s.user_id
    WHERE g.gold_signup_date > s.order_date
) t
WHERE rnk <= 1
ORDER BY 1;
```

---

### Q13. What is the total number of orders and amount spent by each customer before becoming a Gold member?

```sql
SELECT s.user_id,
       SUM(s.qty * p.price_i) AS amount_spend,
       COUNT(DISTINCT s.order_id) AS orders_purchased
FROM sales AS s
JOIN gold_users AS g ON s.user_id = g.user_id
JOIN products AS p ON p.products_id = s.products_id
WHERE s.order_date < g.gold_signup_date
GROUP BY 1
ORDER BY 2 DESC;
```

---

### Q14. How many high-ticket orders (quantity > 3 per order) were placed?

```sql
SELECT COUNT(*)
FROM sales
WHERE qty >= 3;
```

---

### Q15. Calculate Zomato Reward Points per customer and the product earning the most points

**Rule:** 10 Zomato points = ₹2 · Products P1–P6 & P11–P25 earn 5 pts/item · Products P7–P10 earn 10 pts/item

```sql
CREATE TABLE zomato_points AS
SELECT s.user_id, p.product_name, SUM(s.qty),
       CASE
           WHEN p.product_name IN ('P7','P8','P9','P10') THEN SUM(s.qty) * 10
           ELSE SUM(s.qty) * 5
       END AS zomato_points
FROM sales AS s
JOIN products AS p ON s.products_id = p.products_id
GROUP BY 1, 2
ORDER BY 2 DESC;

-- Total points collected by each user
SELECT user_id, SUM(zomato_points) AS total_points
FROM zomato_points
GROUP BY user_id
ORDER BY 2 DESC;

-- Product with the highest points rewarded
SELECT product_name,
       SUM(zomato_points) AS total_points,
       ROUND(SUM(zomato_points) / 5, 0) AS rewards_amount
FROM zomato_points
GROUP BY 1
ORDER BY 2 DESC, 3 DESC;
```

---

### Q16. What is the top-selling month for each year?

```sql
SELECT * FROM (
    SELECT s.year,
           s.month_name,
           SUM(s.qty * p.price_i) AS total_sell,
           ROW_NUMBER() OVER (
               PARTITION BY s.year
               ORDER BY SUM(s.qty * p.price_i) DESC
           ) AS rnk
    FROM sales AS s
    JOIN products AS p ON s.products_id = p.products_id
    GROUP BY 1, 2
) t
WHERE rnk = 1;
```

---

### Q17. How does each month's sales compare to the previous month?

```sql
SELECT s.year,
       s.month_name,
       s.month,
       SUM(s.qty * p.price_i) AS total_sell,
       LAG(SUM(s.qty * p.price_i)) OVER (
           PARTITION BY s.year
           ORDER BY s.month ASC
       ) AS previous_month_sell,
       SUM(s.qty * p.price_i) - LAG(SUM(s.qty * p.price_i)) OVER (
           PARTITION BY s.year
           ORDER BY s.month ASC
       ) AS difference
FROM sales AS s
JOIN products AS p ON s.products_id = p.products_id
GROUP BY 1, 2, 3;
```

---

## 🧠 Key SQL Concepts Demonstrated

- Joins (INNER JOIN across multi-table schema)
- Aggregate functions (`SUM`, `COUNT`)
- Common Table Expressions (CTEs)
- Window functions (`ROW_NUMBER`, `LAG`, `PARTITION BY`)
- Subqueries & correlated logic
- `CASE WHEN` conditional logic
- `UNION` for combined result sets
- Business-rule-driven custom calculations (rewards engine)

---

## 📂 Repository Structure

```
├── zomato_create_table.sql     # Schema creation scripts
├── sql_problem_query.sql       # All 17 business question solutions
└── README.md                   # Project documentation
```

---

## 🚀 How to Run

1. Create the database tables using `zomato_create_table.sql`
2. Load your sales/products/users/gold_users data
3. Run any query from `sql_problem_query.sql` to reproduce the analysis

---

## 📈 Skills Highlighted

`PostgreSQL` `Data Analysis` `Window Functions` `Business Intelligence` `Customer Segmentation` `Revenue Analytics`

---

⭐ If you found this project useful, consider giving it a star!
