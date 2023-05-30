# Q1 - The cost of each line:
SELECT orderNumber, priceEach * quantityOrdered AS Line_Cost
FROM orderdetails;
# ------------------------------------------------

# Q2 - The total revenue of the company:
SELECT SUM(priceEach * quantityOrdered) AS Revenue
FROM orderdetails;
# ------------------------------------------------

# Q3 - The company's total revenue in the first half of 2004:
SELECT SUM(priceEach * quantityOrdered) AS Total_Revenue
FROM orderdetails
JOIN orders USING (orderNumber)
WHERE orderDate BETWEEN "2004-01-01" AND "2004-06-30";

# Using NATURAL JOIN:
SELECT SUM(priceEach * quantityOrdered) AS Total_Revenue
FROM orderdetails
NATURAL JOIN orders
WHERE orderDate BETWEEN "2004-01-01" AND "2004-06-30";
# ------------------------------------------------

# Q4 - Company revenues by years:
SELECT year(orderDate) AS Year, SUM(priceEach * quantityOrdered) AS Year_Revenue
FROM orders
NATURAL JOIN orderdetails
GROUP BY year(orderDate);
# ------------------------------------------------

# Q5 - The five most expensive orders:
SELECT orderNumber, SUM(quantityOrdered * priceEach) AS Revenues
FROM orderdetails
GROUP BY orderNumber
ORDER BY revenues
LIMIT 5;
# ------------------------------------------------

# Q6 - The ten customers with the most purchases:
SELECT customerNumber, SUM(quantityOrdered) AS Number_Of_Purchases
FROM orders
NATURAL JOIN orderdetails
GROUP BY customerNumber
ORDER BY Number_Of_Purchases DESC
LIMIT 10;
# ------------------------------------------------

# Q7 - How many customers on average are associated with each employee:
SELECT AVG(Customers_Per_employee) AS AVG_Customers_Per_Employee
FROM (
	SELECT employees.employeeNumber, COUNT(customers.customerNumber) AS Customers_Per_Employee
    FROM employees
    LEFT JOIN customers ## In case there is an employee without customers. ##
    ON employees.employeeNumber = customers.salesRepEmployeeNumber
    GROUP BY employees.employeeNumber) AS subquery;
# ------------------------------------------------

# Q8 - The employees with more customers than average:
SELECT employeeNumber, Customers_Per_Employee
FROM (
	SELECT employees.employeeNumber, COUNT(customers.customerNumber) AS Customers_Per_Employee
	FROM employees
    LEFT JOIN customers ## In case there is an employee without customers. ##
	ON employees.employeeNumber = customers.salesRepEmployeeNumber
	GROUP BY employees.employeeNumber) AS subquery1
    
WHERE Customers_Per_Employee >
	(SELECT AVG(Customers_Per_employee)
    FROM (SELECT employees.employeeNumber, COUNT(customers.customerNumber) AS Customers_Per_Employee
		FROM employees
        LEFT JOIN customers ## In case there is an employee without customers. ##
		ON employees.employeeNumber = customers.salesRepEmployeeNumber
		GROUP BY employees.employeeNumber) AS subquery2)
        ORDER BY Customers_Per_Employee DESC;
# ------------------------------------------------

# Q9 - How many lines and how many items on average per order:
SELECT AVG(NumberOFLines) AS Avg_Lines, AVG(Total_Items) AS AVG_Items
FROM 
	(SELECT orderNumber, COUNT(orderNumber) AS NumberOFLines, SUM(quantityOrdered) AS Total_Items
	FROM orderdetails
	GROUP BY orderNumber) AS subquery;
# ------------------------------------------------

# Q10 - The list of all customers who ordered from each product line:
SELECT customerNumber, customerName, COUNT(DISTINCT(productLine)) AS Num_Of_Product_Lines
FROM customers
NATURAL JOIN orders
NATURAL JOIN orderdetails
NATURAL JOIN products
GROUP BY customerNumber
HAVING Num_Of_Product_Lines =
	(SELECT COUNT(productLine)
    FROM productlines);
# ------------------------------------------------

# Q11 - The list of items purchased by half of the customers:
SELECT productCode, productName, COUNT(DISTINCT(customerNumber)) AS Num_Of_customers
FROM customers
NATURAL JOIN orders
NATURAL JOIN orderdetails
NATURAL JOIN products
GROUP BY productCode
HAVING Num_Of_customers >=
	(SELECT COUNT(customerNumber)/2
    FROM customers);
# ------------------------------------------------

# Q12 - Total purchases for a product line:
SELECT productLine, SUM(quantityOrdered) AS Total_Purchases
FROM products
NATURAL JOIN orderdetails
GROUP BY productLine;
# ------------------------------------------------

# Q13 - The items that cost less than the average price and were not purchased in the 12th and 13th weeks:
SELECT DISTINCT productCode, productName, MSRP, orderDate
FROM products
NATURAL JOIN orderdetails
NATURAL JOIN orders
WHERE MSRP < (
	SELECT AVG(MSRP)
	FROM products)
    AND WEEKOFYEAR(orderDate) NOT IN (12, 13)
    ORDER BY productName;
# ------------------------------------------------

# Q14 - The items that cost more than the average price or were purchased in the 12th and 13th weeks:
SELECT DISTINCT productName, MSRP
FROM products
NATURAL JOIN orderdetails
NATURAL JOIN orders
WHERE MSRP > (
	SELECT AVG(MSRP)
	FROM products) OR WEEKOFYEAR(orderDate) IN (12, 13)
    ORDER BY productName;
# ------------------------------------------------

# ************************************************
# ************************************************
# Another option - VIEW:
CREATE VIEW Month_12_13 AS
SELECT orderDate
FROM products
NATURAL JOIN orderdetails
NATURAL JOIN orders
WHERE WEEKOFYEAR(orderDate) IN (12, 13);
### DROP VIEW Month_12_13;
# ************************************************
# ************************************************

# Q13 VIEW - The items that cost less than the average price and were not purchased in the 12th and 13th weeks:
SELECT DISTINCT products.productName, products.MSRP
FROM products
NATURAL JOIN orderdetails
NATURAL JOIN orders
JOIN Month_12_13
ON orders.orderDate != Month_12_13.orderDate # VIEW
WHERE products.MSRP < (
    SELECT AVG(MSRP)
    FROM products)
AND WEEKOFYEAR(orders.orderDate) != Month_12_13.orderDate
ORDER BY productName;

# Q14 VIEW - The items that cost more than the average price or were purchased in the 12th and 13th weeks:
SELECT DISTINCT products.productName, products.MSRP
FROM products
NATURAL JOIN orderdetails
NATURAL JOIN orders
JOIN Month_12_13 # VIEW
WHERE products.MSRP > (
    SELECT AVG(MSRP)
    FROM products)
OR WEEKOFYEAR(orders.orderDate) = Month_12_13.orderDate
ORDER BY productName;
# ------------------------------------------------

# Q15 VIEW - The items that cost more than the average price or were purchased in the 12th and 13th weeks (NOT BOTH):
SELECT DISTINCT products.productName, products.MSRP
FROM products
NATURAL JOIN orderdetails
NATURAL JOIN orders
JOIN Month_12_13 # VIEW
WHERE (products.MSRP > (SELECT AVG(MSRP) FROM products)
       XOR WEEKOFYEAR(orders.orderDate) = Month_12_13.orderDate)
       ORDER BY products.productName;
# ------------------------------------------------

# Q16 - The last date each item was purchased:
SELECT DISTINCT(productCode), MAX(orderDate) AS Last_Date_Purchased
FROM products
NATURAL JOIN orderdetails
NATURAL JOIN orders
GROUP BY (productCode);
# ------------------------------------------------

# Q17 - The most expensive order:
SELECT productCode, orderNumber, Most_Expensive_Cost
FROM (
    SELECT productCode, orderNumber, (quantityOrdered * priceEach) AS Most_Expensive_Cost,
        ROW_NUMBER() OVER (PARTITION BY productCode
        ORDER BY (quantityOrdered * priceEach) DESC) AS Number_Of_Row
    FROM orderdetails
    NATURAL JOIN products) AS subquery
WHERE Number_Of_Row = 1
ORDER BY productCode;
# ------------------------------------------------

# Q18 - The most expensive orders (INDEX 1, 3, 5, 7, 9):
SELECT productCode, orderNumber, Most_Expensive_Cost, Index_Column
FROM (
    SELECT productCode, orderNumber, Most_Expensive_Cost,
        ROW_NUMBER() OVER
        (ORDER BY Most_Expensive_Cost DESC, productCode, orderNumber) AS Index_Column
	FROM (
		SELECT productCode, orderNumber, (quantityOrdered * priceEach) AS Most_Expensive_Cost,
			ROW_NUMBER() OVER (PARTITION BY productCode
            ORDER BY (quantityOrdered * priceEach) DESC) AS Number_Of_Row
		FROM orderdetails
		NATURAL JOIN products) AS subquery
	WHERE Number_Of_Row = 1) AS indexed_data
WHERE Index_Column IN (1, 3, 5, 7, 9);
# ------------------------------------------------

# Q19 - The percentage of lines where a discount was given:
SELECT SUM(CASE WHEN priceEach < MSRP THEN 1 ELSE 0 END) / COUNT(productCode) AS Discount_Rate
FROM orderdetails
NATURAL JOIN products;
# ------------------------------------------------

# Q20 - Company revenues without discounts:
 SELECT SUM(MSRP * quantityOrdered) AS Original_Revenue
 FROM products
 NATURAL JOIN orderdetails;
 
SELECT Original_Revenue, Discounts_Revenue, (Original_Revenue - Discounts_Revenue) AS Losses
FROM (
    SELECT SUM(MSRP * quantityOrdered) AS Original_revenue, SUM(priceEach * quantityOrdered) AS Discounts_revenue
    FROM products
    NATURAL JOIN orderdetails) AS subquery;
# ------------------------------------------------

# Q21 - Next order date for each customer:
SELECT customerNumber, orderNumber, orderDate,
       LEAD(orderDate, 1) OVER (ORDER BY orderDate) AS Next_Order
FROM orders;
# ------------------------------------------------

# Q22 - Cumulative price for a certain customer (119):
SELECT DISTINCT(productName), productCode, MSRP, Cumulative_Price
FROM (
    SELECT productName, productCode, MSRP, 
           SUM(MSRP) OVER (ORDER BY MSRP ASC) AS Cumulative_Price
    FROM products
    NATURAL JOIN orderdetails
    NATURAL JOIN orders
    WHERE customerNumber = 119) AS dataTable
WHERE Cumulative_Price <= 300
ORDER BY Cumulative_Price;
# ------------------------------------------------

# Q23 - Cumulative price for all customers:
SELECT DISTINCT productName, productCode, customerNumber, MSRP, Cumulative_Price
FROM (
    SELECT productName, productCode, customerNumber, MSRP,
           SUM(MSRP) OVER (PARTITION BY customerNumber
           ORDER BY MSRP ASC) AS Cumulative_Price
    FROM products
    NATURAL JOIN orderdetails
    NATURAL JOIN orders) AS dataTable
WHERE Cumulative_Price <= 300
ORDER BY customerNumber, Cumulative_Price;

DROP VIEW Month_12_13;
