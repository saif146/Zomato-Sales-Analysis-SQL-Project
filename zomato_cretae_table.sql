--create table USER

drop table if exists users;
create table users(

 user_id int PRIMARY key,
 signup_date date ,
 address VARCHAR(200)
 
);
select * from users;

drop table if exists products;
create table products(

 products_id int PRIMARY key,
 product_name varchar(30),
 price VARCHAR(20),
 price_i int
);
select * from products;



drop table if exists gold_users;
create table gold_users(

 user_id int,
 gold_signup_date date,
 FOREIGN KEY (user_id) REFERENCES  users(user_id)
 
);
select * from gold_users;


drop table if exists sales;
create table sales(

 order_id int PRIMARY key,
 user_id int,
 order_date date,
 products_id int,
 qty int,
 year varchar(20),
 month int,
 month_name varchar(20),
 FOREIGN KEY (user_id) REFERENCES  users(user_id),
 FOREIGN KEY (products_id) REFERENCES  products(products_id)
 
);
select * from sales;




