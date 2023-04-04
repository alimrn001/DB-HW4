/*
SQL Client : MySQL Workbench 8.0 CE
ALL Tables are store in a schematic named 'newschema' and this name is used to access tables inside it !
*/


/*select questions*/

#1
/*select.q1*/
SELECT p.product_name, b.brand_name, c.category_name, p.price
FROM newschema.products p, newschema.categories c, newschema.brands b
WHERE p.brand_id = b.brand_id AND c.category_id = p.category_id
ORDER BY p.price DESC
LIMIT 11;

#2
/* select.q2*/
SELECT DISTINCT p1.product_name, b.brand_name, c.category_name, p1.price 
FROM newschema.products p1, newschema.brands b, newschema.categories c
WHERE 11 >= (
		SELECT COUNT(DISTINCT p2.product_id)
        FROM newschema.products p2
        WHERE p2.product_id != p1.product_id AND p2.price >= p1.price
		) 
        AND p1.category_id = c.category_id 
		AND p1.brand_id = b.brand_id
ORDER BY p1.price DESC;

#3
/*select.q3*/
/*assuming the 'price' field in order_items is for each product and discount has not affected it so final price would be as -> (price*quantity*(1-discount)) */
SELECT s.store_name, SUM(oi.price*oi.quantity*(1-oi.discount)) AS 'income'
FROM newschema.stores s, newschema.orders o, newschema.order_items oi
WHERE s.store_id = o.store_id AND oi.order_id = o.order_id AND o.order_status = 4
GROUP BY s.store_id;

#4
/*select.q4*/
/*same assumptions as q3*/
SELECT b.brand_name, SUM(oi.price*oi.quantity*(1-oi.discount)) AS 'income'
FROM newschema.products p, newschema.order_items oi, newschema.brands b, newschema.orders o
WHERE p.brand_id = b.brand_id AND oi.product_id = p.product_id AND o.order_id = oi.order_id AND o.order_status = 4 AND YEAR(o.order_date) = '2017'
GROUP BY b.brand_id;

#5
/*select.q5*/
SELECT s.store_id, s.store_name, COUNT(stf.staff_id) AS 'total staff'
FROM newschema.stores s
LEFT JOIN newschema.staffs stf ON s.store_id = stf.store_id
GROUP BY s.store_id;

#6
/*select.q6*/

SELECT p.product_name, finalproduct.maxamount
FROM (SELECT product1.product_id, product3.maxamount 
							FROM (
									SELECT st1.product_id, SUM(st1.quantity) AS amount1
									FROM newschema.stocks st1
									GROUP BY st1.product_id
								 ) product1 ,   
                                    
								 (
									SELECT MAX(product2.amount2) AS maxamount
									FROM (
											SELECT st2.product_id, SUM(st2.quantity) AS amount2
											FROM newschema.stocks st2
											GROUP BY st2.product_id
										) product2 
								  ) product3
                                            
							WHERE product1.amount1 = product3.maxamount
                            ) finalProduct,
                            newschema.products p
WHERE p.product_id = (finalProduct.product_id);


-- SELECT p.product_id, SUM(st.quantity) AS sum 
-- FROM newschema.stocks st, newschema.products p, newschema.stores s 
-- WHERE st.store_id = s.store_id AND st.product_id = p.product_id
-- GROUP BY p.product_id
-- ORDER BY sum DESC
-- LIMIT 1;

#7
/*select.q7*/
SELECT c2.first_name, c2.last_name
FROM 
	(
    select c1.customer_id
	FROM newschema.customers c1, newschema.orders o
	WHERE c1.customer_id = o.customer_id AND o.order_status = 3
    ) x,
	newschema.customers c2
WHERE c2.customer_id != x.customer_id AND LEFT(c2.first_name,1) = "F"
GROUP BY c2.customer_id;


#8 
/*select.q8*/
/*assuming an unselled item is one that is not in any order (and order item) regardless of the order status*/
SELECT p1.*
FROM newschema.products p1
WHERE p1.product_id NOT IN 
    (
		SELECT p2.product_id
		FROM newschema.products p2, newschema.orders o, newschema.order_items oi
		WHERE o.order_id = oi.order_id AND p2.product_id = oi.product_id
    );   


#9
/*select.q9*/
SELECT c.customer_id, COUNT(o.order_id) AS 'total orders'
FROM newschema.customers c, newschema.orders o
WHERE o.customer_id = c.customer_id
GROUP BY c.customer_id
HAVING COUNT(o.order_id) >= 2;


#10
/*select.q10*/
/*same assumptions as q3 for calculating income*/
/*similar to what we assumed in q3 we assume that products with 0 income do not have to be shown*/
SELECT p.product_name, SUM(oi.price*oi.quantity*(1-oi.discount)) AS 'income'
FROM newschema.order_items oi, newschema.products p, newschema.orders o
WHERE oi.order_id = o.order_id AND p.product_id = oi.product_id AND o.order_status = 4
GROUP BY p.product_id -- this one can also be grouped by product_name
ORDER BY income DESC 
LIMIT 10;


/*view questions*/

#1
/*view.q1*/
/*assuming we only show this for users that have ordered something (regardless of order status)*/
CREATE VIEW newschema.view_1 AS
SELECT c.customer_id, c.first_name, c.last_name, AVG(oi.price*oi.quantity*(1-oi.discount)) AS 'purchase_amount_avg'
FROM newschema.order_items oi, newschema.customers c, newschema.orders o
WHERE c.customer_id = o.customer_id AND o.order_id = oi.order_id
GROUP BY c.customer_id;

SELECT * FROM newschema.view_1
ORDER BY view_1.purchase_amount_avg DESC;


#2
/*view.q2*/
/*assuming '100' in question means number of sells for items*/
CREATE VIEW newschema.view_2 AS
SELECT p.product_id, p.product_name, SUM(oi.quantity) AS 'total_sold'
FROM newschema.order_items oi, newschema.products p, newschema.orders o
WHERE oi.order_id = o.order_id AND p.product_id = oi.product_id
GROUP BY p.product_id
HAVING SUM(oi.quantity) > 100;

SELECT * FROM newschema.view_2
ORDER BY view_2.total_sold DESC;


#3
/*view.q3*/
/*using 'NOT IN' instead of 'EXCEPT' since mysql does not support 'EXCEPT' */
CREATE VIEW newschema.view_3 AS
SELECT s.*
FROM newschema.stores s
WHERE NOT EXISTS 
	(
		SELECT c.category_id
		FROM newschema.categories c
        WHERE c.category_id NOT IN
        (
			SELECT p.category_id
            FROM newschema.products p, newschema.order_items oi, newschema.orders o
            WHERE o.order_id = oi.order_id AND p.product_id = oi.product_id AND s.store_id = o.store_id
        )
    );

SELECT * FROM newschema.view_3
GROUP BY view_3.store_id;


/*trigger questions*/

#1
/*trigger.q1*/
delimiter //
CREATE TRIGGER newschema.insert_trigger
BEFORE INSERT ON newschema.order_items
FOR EACH ROW BEGIN
	IF NEW.quantity > (
						SELECT DISTINCT st.quantity
                        FROM newschema.stocks st, newschema.products p, newschema.stores s, newschema.orders o
                        WHERE st.product_id = p.product_id 
							  AND st.store_id = s.store_id 
                              AND o.store_id = s.store_id
                              AND o.order_id = NEW.order_id 
                              AND NEW.product_id = st.product_id
					) THEN
		SIGNAL SQLSTATE '50001' SET MESSAGE_TEXT = 'Invalid: Requested quantity is more than available quantity in stock';
	END IF;
END;//
delimiter ;
-- DROP TRIGGER newschema.insert_trigger;
INSERT INTO newschema.order_items VALUES(1, 1, 20, 30, 599.99, 0.2) -- store 1 has total 26 from product 20


#2
/*trigger.q2*/
-- assuming we wont set order to 2 again if its already set 
delimiter //
CREATE TRIGGER newschema.update_trigger BEFORE UPDATE ON newschema.orders
       FOR EACH ROW
       BEGIN
           IF NEW.order_status = 2 THEN  
				SET NEW.shipped_date = NOW();
           END IF;
       END;//
delimiter ;
-- DROP TRIGGER newschema.update_trigger;
UPDATE newschema.orders 
SET order_status = 2
WHERE order_id = 1; 

SELECT o.*
FROM newschema.orders o
WHERE o.order_id = 1 -- shipped date changed to 2023-04-03


#3
/*trigger.q3*/
delimiter //
CREATE TRIGGER newschema.delete_trigger BEFORE DELETE ON newschema.customers
       FOR EACH ROW
       BEGIN
			IF (EXISTS (
							SELECT DISTINCT o.order_id
                            FROM newschema.orders o, newschema.customers c 
                            WHERE o.customer_id = c.customer_id AND (o.order_status = 1 OR o.order_status = 2) AND OLD.customer_id = c.customer_id
						) 
				) THEN
				SIGNAL SQLSTATE '50001' SET MESSAGE_TEXT = 'Invalid: Cannot delete customer with Pending or Processing orders' ;
           END IF;
       END;//
delimiter ;

-- DROP TRIGGER newschema.delete_trigger;

DELETE FROM newschema.customers 
WHERE customer_id = 55; -- customer with id = 55 has an order with status = 1 

DELETE FROM newschema.customers 
WHERE customer_id = 74; -- customer with id = 74 has an order with status = 2 

