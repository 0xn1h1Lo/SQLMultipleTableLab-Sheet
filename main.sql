DROP TABLE IF EXISTS Item;
DROP TABLE IF EXISTS Employee;
DROP TABLE IF EXISTS Department;
DROP TABLE IF EXISTS Sale;
DROP TABLE IF EXISTS Supplier;
DROP TABLE IF EXISTS Delivery;

CREATE TABLE Item (
	  ItemName VARCHAR (30) NOT NULL,
  ItemType CHAR(1) NOT NULL,
  ItemColour VARCHAR(10),
  PRIMARY KEY (ItemName));

CREATE TABLE Employee (
  EmployeeNumber SMALLINT UNSIGNED NOT NULL ,
  EmployeeName VARCHAR(10) NOT NULL ,
  EmployeeSalary INTEGER UNSIGNED NOT NULL ,
  DepartmentName VARCHAR(10) NOT NULL REFERENCES Department,
  /* commented out because the big boss is NULL.
  Employee without attribut references the primary key (EmployeeNumber)
  BossNumber SMALLINT UNSIGNED NOT NULL REFERENCES Employee, */
  BossNumber SMALLINT UNSIGNED REFERENCES Employee,
  PRIMARY KEY (EmployeeNumber));

CREATE TABLE Department (
  DepartmentName VARCHAR(10) NOT NULL,
  DepartmentFloor SMALLINT UNSIGNED NOT NULL,
  DepartmentPhone SMALLINT UNSIGNED NOT NULL,
  EmployeeNumber SMALLINT UNSIGNED NOT NULL REFERENCES 
    Employee,
  PRIMARY KEY (DepartmentName));

CREATE TABLE Sale (
  SaleNumber INTEGER UNSIGNED NOT NULL,
  SaleQuantity SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  ItemName VARCHAR(30) NOT NULL REFERENCES Item,
  DepartmentName VARCHAR(10) NOT NULL REFERENCES Department,
  PRIMARY KEY (SaleNumber));

CREATE TABLE Supplier (
  SupplierNumber INTEGER UNSIGNED NOT NULL,
  SupplierName VARCHAR(30) NOT NULL,
  PRIMARY KEY (SupplierNumber));

CREATE TABLE Delivery (
  DeliveryNumber INTEGER UNSIGNED NOT NULL,
  DeliveryQuantity SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  ItemName VARCHAR(30) NOT NULL REFERENCES Item,
  DepartmentName VARCHAR(10) NOT NULL REFERENCES Department,
  SupplierNumber INTEGER UNSIGNED NOT NULL REFERENCES  
     Supplier,
  PRIMARY KEY (DeliveryNumber));

-- .mode to set data delimiter
.mode tabs

-- importing item table
.import item.txt Item
-- fixing \N values
UPDATE Item
SET ItemColour = NULL
WHERE ItemColour = '\N';

-- importing employee table
.import employee.txt Employee
-- fixing \N values
UPDATE Employee
SET BossNumber = NULL
WHERE BossNumber = '\N';

-- importing the other tables
.import delivery.txt Delivery
.import department.txt Department
.import sale.txt Sale
.import supplier.txt Supplier

-- nicer display after import
.mode table

-- check all is OK
.print "Item"
SELECT *
FROM Item;
.print "Employee"
SELECT *
FROM Employee;
.print "Delivery"
SELECT *
FROM Delivery;
.print "Department"
SELECT *
FROM Department;
.print "Sale"
SELECT *
FROM Sale;
.print "Supplier"
SELECT *
FROM Supplier;

.print "Lab queries"
-- Q1 Names of EEs in the marketing dpt
SELECT EmployeeName
FROM Employee
WHERE DepartmentName = 'Marketing';

/*
SELECT DISTINCT ItemName
From Sale, Department
WHERE Sale.DepartmentName = Department.DepartmentName
AND Department.DepartmentFloor = 2;
*/

-- Q2 Find items sold by the departments on the second floor
SELECT DISTINCT ItemName
FROM Sale NATURAL JOIN Department
WHERE Department.DepartmentFloor = 2;

/*
SELECT DISTINCT ItemName
-- behaves liks a CROSS JOIN with SQLite or just Sale, Department
FROM Sale JOIN Department
WHERE Department.DepartmentFloor = 2;
*/

-- Q3 Identify by floor the items available on floors other than the second floor
SELECT DISTINCT ItemName, Department.DepartmentFloor AS 'On Floor'
FROM Delivery NATURAL JOIN Department
WHERE DepartmentFloor <> 2
ORDER BY DepartmentFloor, ItemName;

-- Q4 average salary of the EEs in the Clothes dpt
SELECT AVG(EmployeeSalary)
FROM Employee
WHERE DepartmentName = 'Clothes';

-- Q5 average salary of the EEs in that dpt and report by DESC salary
-- here we MUST use double quotes and not string literal, that's a typo in the lab sheet
SELECT DepartmentName, AVG(EmployeeSalary) AS "Average Salary"
FROM Employee
GROUP BY DepartmentName
ORDER BY "Average Salary" DESC;

-- Q6 List items delivered by 1 supplier
SELECT ItemName
FROM Delivery
GROUP BY ItemName
	HAVING COUNT(DISTINCT SupplierNumber) = 1;

-- Q7 list suppliers that delivery > 10 items
SELECT Supplier.SupplierNumber, Supplier.SupplierName
FROM Supplier NATURAL JOIN Delivery
GROUP BY Supplier.SupplierNumber
HAVING COUNT(DISTINCT Delivery.ItemName) >= 10;

-- Q8 count number of direct EEs of each manager
SELECT EmployeeName, ReportsNumber
FROM
	(SELECT BossNumber, COUNT(*) AS ReportsNumber
	FROM Employee
	GROUP BY BossNumber) AS Manager
JOIN Employee ON Manager.BossNumber = Employee.EmployeeNumber;

/* Solution
SELECT Boss.EmployeeNumber,
Boss.EmployeeName, COUNT(*) AS
'Employees'
FROM Employee AS Worker, Employee AS Boss
WHERE Worker.BossNumber = Boss.EmployeeNumber
GROUP BY Boss.EmployeeNumber, Boss.EmployeeName;
*/

-- Q9 average salary of employees of dts
SELECT DepartmentName, AVG(DISTINCT EmployeeSalary)
FROM Item NATURAL JOIN Delivery NATURAL JOIN Employee
WHERE ItemType = 'E'
GROUP BY DepartmentName;

/* Solution
-- Employee and Department both have DepartmentName AND EmployeeNumber 
-- NATURAL JOIN would join on both if used... and the result would be empty
SELECT Department.DepartmentName,
AVG(EmployeeSalary) AS 'Average Salary'
FROM Employee, Department, Sale, Item
WHERE Employee.DepartmentName = Department.DepartmentName
	AND Department.DepartmentName = Sale.DepartmentName
	AND Sale.ItemName = Item.ItemName
	AND ItemType = 'E'
GROUP BY Department.DepartmentName;
*/

-- Q10
SELECT SUM(SaleQuantity)
FROM Sale NATURAL JOIN Department NATURAL JOIN Item
WHERE ItemType = 'E' AND DepartmentFloor = 2;

-- Q11
SELECT SupplierName, ItemName, AVG(DeliveryQuantity)
FROM Supplier NATURAL JOIN Delivery NATURAL JOIN Item
WHERE ItemType = 'N'
GROUP BY SupplierName, ItemName;

/* Solution
SELECT Delivery.SupplierNumber,
SupplierName, Delivery.ItemName,
AVG(Delivery.DeliveryQuantity) AS
'Average Quantity'
FROM ((Delivery NATURAL JOIN Supplier) NATURAL JOIN Item)
WHERE Item.ItemType = 'N'
GROUP BY Delivery.SupplierNumber,
SupplierName, Delivery.ItemName ORDER BY
Delivery.SupplierNumber, SupplierName,
'Average Quantity' DESC,
Delivery.ItemName;
*/

-- Nested Queries
-- Q1 Names of items sold in dpt on 2nd floor
SELECT DISTINCT ItemName
FROM Sale
WHERE DepartmentName IN
	(SELECT DepartmentName
	FROM Department
	WHERE DepartmentFloor = 2);

-- Q2 Find salary of Clare's manager

WITH Manager AS (
	SELECT BossNumber
	FROM Employee
	WHERE EmployeeName = 'Clare')
SELECT EmployeeSalary
FROM Employee
WHERE EmployeeNumber IN Manager;

/* Solution
SELECT EmployeeName, EmployeeSalary
FROM Employee
WHERE EmployeeNumber =
(SELECT BossNumber
FROM Employee
WHERE EmployeeName = 'Clare');
*/

-- Q3 Find name and salary of managers with more than 2 EEs
SELECT EmployeeName, EmployeeSalary
FROM Employee
WHERE EmployeeNumber IN
	(SELECT BossNumber
	FROM Employee
	GROUP BY BossNumber HAVING COUNT(DISTINCT EmployeeName) > 2);

-- Q4 List names of EEs with salary > all EEs in Marketing
SELECT EmployeeName, EmployeeSalary
FROM Employee
WHERE EmployeeSalary >
	(SELECT MAX(EmployeeSalary)
	FROM Employee
	WHERE DepartmentName = 'Marketing');

-- Q5 dpt which sells Stetsons with salary > 25k
SELECT DISTINCT DepartmentName
FROM Sale
WHERE ItemName = 'Stetsons' AND DepartmentName IN
	(SELECT DepartmentName
	FROM Employee
	GROUP BY DepartmentName HAVING
	SUM(EmployeeSalary) > 25000);

-- Q6 Suppliers to delivery compasses + other item
SELECT DISTINCT Delivery.SupplierNumber,
Supplier.SupplierName FROM (Supplier
NATURAL JOIN Delivery)
WHERE (ItemName <> 'Compass' AND SupplierNumber IN
	(SELECT
	SupplierNumber
	FROM Delivery
	WHERE ItemName = 'Compass'));

-- Q7 Find suppliers that delivery compass and > 3 other items
SELECT DISTINCT Delivery.SupplierNumber, Supplier.SupplierName
FROM (Supplier NATURAL JOIN Delivery)
WHERE SupplierNumber IN
	(SELECT SupplierNumber
	FROM Delivery
	WHERE ItemName = 'Compass')
GROUP BY Delivery.SupplierNumber, Supplier.SupplierName HAVING COUNT(DISTINCT ItemName) > 3;

-- Q8
-- SELECT ... WHERE ... iterates through each department in Delivery
SELECT DISTINCT DepartmentName
FROM Delivery AS Delivery1
WHERE NOT EXISTS
	(SELECT *
	FROM Delivery AS Delivery2
	-- finds deliveries to current dpt for items
	WHERE Delivery2.DepartmentName = Delivery1.DepartmentName
	-- that were NOT delivered to any other dpt
	AND ItemName NOT IN
		-- finds all items delivered to any department except the current one.
		(SELECT ItemName
		FROM Delivery AS Delivery3
		WHERE Delivery3.DepartmentName <> Delivery1.DepartmentName));
