USE shop;

-- 1 Showing top 2 the most expensive item
SELECT * FROM MsProduct 
ORDER BY Price DESC LIMIT 2;

-- 2 Showing the shop detail that already official with the last ID is Y, and sort it by the owner shop ascending
SELECT * FROM trShop 
WHERE RIGHT(IDShop,1) = 'Y' 
ORDER BY Owner ASC;

-- 3 Create a view to show transaction thet have been done with credit card
CREATE VIEW vw_CreditCardDoneTransaction
AS
SELECT * FROM trTransaction 
WHERE PaymentMethod = 'Credit Card' AND Done = 1;
SELECT * FROM vw_CreditCardDoneTransaction;

-- 4 Showing the shop official owner name by showing ID shop + owner last name
SELECT CONCAT(IDShop, ' ', SUBSTR(Owner, LOCATE(' ', Owner), LENGTH(Owner))) AS 'Owner Name' FROM trShop 
WHERE isOfficial = 1;

-- 5 Showing Id product, name, stock and price with 'Rp' infront of it. Also, the stock is more than 50
SELECT IDProduct, Name, Stock, CONCAT('Rp. ', Price) AS Price 
FROM MsProduct WHERE Stock > 50;

-- 6 Showing Id Shop, shop name with showing the shop is official or not, and owner shop with the price is more than 100000
SELECT DISTINCT a.IDShop, CONCAT(a.Name, CASE WHEN isOfficial = 1 THEN ' (Official)' ELSE ' (Non-Official)' END) AS Name, Owner
FROM trShop a
JOIN MsProduct b ON a.IDShop = b.IDShop
WHERE Price > 100000;

-- 7 Showing transaction id, product id, customer id, date with format (Ex: 10 June 2020), quantity, totalprice, and payment method with the transaction during september - november 
SELECT IDTransaction, IDProduct, IDCustomer, DATE_FORMAT(TransactionDate, '%d %M %Y') AS "Transaction Date", qty, totalprice, paymentmethod
FROM TrTransaction
WHERE MONTH(TransactionDate) IN (9, 11);

-- 8 Show payment method, payment count with debit card in official store
SELECT PaymentMethod, COUNT(IDTransaction) AS 'Payment Count'
FROM TrTransaction
JOIN MsProduct ON TrTransaction.IDProduct = MsProduct.IDProduct
JOIN TrShop ON MsProduct.IDShop = TrShop.IDShop
WHERE isOfficial = 1 AND PaymentMethod = 'Debit'
GROUP BY PaymentMethod;

-- 9 show customer id, name, phone, email where the name got 3 word
SELECT IDCustomer, Name, PhoneNumber, Email
FROM TrCustomer
WHERE Name LIKE '% % %';

-- 10 create store procedure where its can get input to search product with product name, ans show the shop name, id product, product name, stock and price
DELIMITER $$
CREATE PROCEDURE Search_Product(IN Input_param VARCHAR(255))
BEGIN
    SELECT b.Name as 'Shop Name', a.IDProduct as 'Product ID', a.Name as 'Product Name', a.Stock, a.Price
    FROM MsProduct a
    JOIN TrShop b ON a.idshop = b.IDShop
    WHERE a.Name = Input_param;
END $$
DELIMITER ;

CALL Search_Product('Tooth brush');

-- 11 Create store procedure where it can get input product name, and show the product name and average review of the product
DELIMITER $$
CREATE PROCEDURE GetAverageReviewByProductName(IN Input_param VARCHAR(255))
BEGIN
    SELECT b.Name as 'Product Name', AVG(a.Star) as 'Average Review Star'
    FROM TrReview a
    JOIN MsProduct b ON a.IDProduct = b.IDProduct
    WHERE b.Name = Input_param
    GROUP BY b.Name;
END $$
DELIMITER ;

CALL GetAverageReviewByProductName ('Fidget Box');

-- 12 Create stored procedure  where it can get input with shop name or owner name and show the shop detail
DELIMITER $$
CREATE PROCEDURE Search_Shop(IN Input_param VARCHAR(255))
BEGIN
    SELECT * FROM TrShop
    WHERE Name LIKE concat('%', Input_param, '%') OR 
    Owner LIKE concat('%', Input_param, '%');
END $$
DELIMITER ;

select * FROM trshop;
CALL Search_Shop ('Fred');

-- 13 create stored procedure to see the product id, shop id, shop name, price, and total of stock + total sold of the product
DELIMITER $$
CREATE PROCEDURE GetTotalStockAndSoldProduct()
BEGIN
    SELECT b.IDProduct, b.IDShop, b.Name, b.Price, (b.Stock + a.TotalQty) AS 'Total Stock + Sold'
    FROM (
        SELECT IDProduct, COALESCE(SUM(Qty), 0) AS TotalQty -- NULL
        FROM TrTransaction
        GROUP BY IDProduct
    ) a
    JOIN MsProduct b ON a.IDProduct = b.IDProduct;
END $$
DELIMITER ;

CALL GetTotalStockAndSoldProduct();

-- 14 Create stored procedure to get input for product name. Show the product name and number of the customer that keep the product in their cart
DELIMITER $$
CREATE PROCEDURE CountProductInCustomerCart(IN Name VARCHAR(255))
BEGIN
    SELECT b.Name, COALESCE(a.CountCustomer, 0) AS 'Count Customer'
    FROM (
        SELECT IDProduct, COUNT(IDCustomer) AS CountCustomer
        FROM TrCart
        GROUP BY IDProduct
    ) a
    RIGHT JOIN MsProduct b ON a.IDProduct = b.IDProduct
    WHERE b.Name = Name;
END $$
DELIMITER ;

CALL CountProductInCustomerCart('Door');

-- 15 Create a stored procedure to get input by customer name, that will used for give point to the customer by their total spend with this condition:
-- 1. the total spend < 100000 the point will be 0
-- 2. the total spend 100000 - 499999 the point will be 20
-- 3. the total spend 500000 - 999999 the point will be 50
-- 4. the total spend is more than 999999 the point will be 100
DELIMITER $$
CREATE PROCEDURE CalculateCustomerPoint(IN Customer_Name VARCHAR(255))
BEGIN
DECLARE Total_Spending BIGINT;

SET Total_Spending = (
SELECT SUM(TotalPrice) FROM TrTransaction a 
JOIN TrCustomer b ON a.IDCustomer = b.IDCustomer 
WHERE Name = Customer_Name GROUP BY a.IDCustomer
);

SELECT CASE
  WHEN Total_Spending < 100000 OR Total_Spending IS NULL THEN 0
  WHEN Total_Spending >= 100000 AND Total_Spending < 500000 THEN 20
  WHEN Total_Spending >= 500000 AND Total_Spending < 1000000 THEN 50 
  ELSE 100
END AS Point;
END$$
DELIMITER ;

SELECT * FROM trcustomer;
CALL CalculateCustomerPoint('Christiana Willis Cockle');




