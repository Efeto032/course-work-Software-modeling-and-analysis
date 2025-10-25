CREATE DATABASE TemuDB;
GO

USE TemuDB;
GO

-- Users
CREATE TABLE dbo.[User] (
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(150) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(255) NOT NULL,
    Phone NVARCHAR(30) NULL,
    RegistrationDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- Seller
CREATE TABLE dbo.Seller (
    SellerID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(150) NOT NULL,
    Country NVARCHAR(100) NULL,
    RatingAvg DECIMAL(3,2) NULL
);
GO

-- Category
CREATE TABLE dbo.Category (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(400) NULL
);
GO

-- Product
CREATE TABLE dbo.Product (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(200) NOT NULL,
    Description NVARCHAR(1000) NULL,
    Price DECIMAL(10,2) NOT NULL CHECK (Price >= 0),
    StockQty INT NOT NULL DEFAULT 0 CHECK (StockQty >= 0),
    RatingAvg DECIMAL(3,2) NULL,
    SellerID INT NOT NULL,
    CategoryID INT NULL,
    CONSTRAINT FK_Product_Seller FOREIGN KEY (SellerID) REFERENCES dbo.Seller(SellerID),
    CONSTRAINT FK_Product_Category FOREIGN KEY (CategoryID) REFERENCES dbo.Category(CategoryID)
);
GO

-- Order
CREATE TABLE dbo.[Order] (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NOT NULL,
    OrderDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    OrderStatus NVARCHAR(50) NOT NULL DEFAULT 'Pending',
    TotalAmount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    CONSTRAINT FK_Order_User FOREIGN KEY (UserID) REFERENCES dbo.[User](UserID)
);
GO

-- OrderItem (junction table: Order <-> Product) - implements M:N
CREATE TABLE dbo.OrderItem (
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    PRIMARY KEY (OrderID, ProductID),
    CONSTRAINT FK_OrderItem_Order FOREIGN KEY (OrderID) REFERENCES dbo.[Order](OrderID) ON DELETE CASCADE,
    CONSTRAINT FK_OrderItem_Product FOREIGN KEY (ProductID) REFERENCES dbo.Product(ProductID)
);
GO

-- Payment
CREATE TABLE dbo.Payment (
    PaymentID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL UNIQUE, -- 1-1 with Order in this model
    PaymentType NVARCHAR(50) NOT NULL,
    PaymentStatus NVARCHAR(50) NOT NULL DEFAULT 'Pending',
    PaidAt DATETIME2 NULL,
    CONSTRAINT FK_Payment_Order FOREIGN KEY (OrderID) REFERENCES dbo.[Order](OrderID)
);
GO

-- Shipment
CREATE TABLE dbo.Shipment (
    ShipmentID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL UNIQUE, -- 1-1 with Order
    TrackingNumber NVARCHAR(200) NULL,
    ShipmentStatus NVARCHAR(50) NOT NULL DEFAULT 'Preparing',
    ShippedAt DATETIME2 NULL,
    CONSTRAINT FK_Shipment_Order FOREIGN KEY (OrderID) REFERENCES dbo.[Order](OrderID)
);
GO

-- Cart
CREATE TABLE dbo.Cart (
    CartID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NOT NULL UNIQUE, -- 1-1 for this model (one active cart)
    CreatedDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Cart_User FOREIGN KEY (UserID) REFERENCES dbo.[User](UserID)
);
GO

-- CartItem (optional) - to store items placed in cart
CREATE TABLE dbo.CartItem (
    CartItemID INT IDENTITY(1,1) PRIMARY KEY,
    CartID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    CONSTRAINT FK_CartItem_Cart FOREIGN KEY (CartID) REFERENCES dbo.Cart(CartID) ON DELETE CASCADE,
    CONSTRAINT FK_CartItem_Product FOREIGN KEY (ProductID) REFERENCES dbo.Product(ProductID)
);
GO

-- Review
CREATE TABLE dbo.Review (
    ReviewID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NOT NULL,
    ProductID INT NOT NULL,
    Rating INT NOT NULL CHECK (Rating >= 1 AND Rating <= 5),
    Comment NVARCHAR(2000) NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Review_User FOREIGN KEY (UserID) REFERENCES dbo.[User](UserID),
    CONSTRAINT FK_Review_Product FOREIGN KEY (ProductID) REFERENCES dbo.Product(ProductID)
);
GO

-- Indexes for performance (simple)
CREATE INDEX IX_Product_Category ON dbo.Product(CategoryID);
CREATE INDEX IX_Order_User ON dbo.[Order](UserID);
CREATE INDEX IX_OrderItem_Product ON dbo.OrderItem(ProductID);
CREATE INDEX IX_Review_Product ON dbo.Review(ProductID);
GO

-- Users
INSERT INTO dbo.[User] (FirstName, LastName, Email, PasswordHash, Phone)
VALUES
('Ivan','Petrov','ivan.petrov@example.com','hash1','+359882111111'),
('Maria','Dimitrova','maria.dim@example.com','hash2','+359882222222'),
('Georgi','Ivanov','georgi.ivanov@example.com','hash3',NULL),
('Elena','Koleva','elena.k@example.com','hash4',NULL),
('Dimitar','Nikolov','dimi.n@example.com','hash5','+359888333333');
GO

-- Sellers
INSERT INTO dbo.Seller (Name, Country, RatingAvg)
VALUES
('GlobalGoods Ltd.','China',4.50),
('FastDeals Inc.','USA',4.10),
('QualityMart','Germany',4.70);
GO

-- Categories
INSERT INTO dbo.Category (Name, Description)
VALUES
('Electronics','Phones, accessories, gadgets'),
('Home & Kitchen','Household and kitchen items'),
('Fashion','Clothing and accessories'),
('Sports','Sporting goods and outdoor gear');
GO

-- Products
INSERT INTO dbo.Product (Name, Description, Price, StockQty, SellerID, CategoryID)
VALUES
('Wireless Earbuds','Bluetooth earbuds with charging case',29.99,150,1,1),
('Stainless Steel Water Bottle','1L insulated bottle',15.50,300,3,2),
('Men''s Running Shoes','Comfortable running shoes',59.99,80,2,4),
('LED Desk Lamp','Adjustable LED lamp with USB charging',22.00,120,1,2),
('Women''s T-shirt','Cotton t-shirt',12.99,500,2,3);
GO

-- Orders + OrderItems + Payments + Shipments (seed)
-- Order 1 by Ivan (UserID = 1)
INSERT INTO dbo.[Order] (UserID, OrderStatus) VALUES (1, 'Completed');
DECLARE @order1 INT = SCOPE_IDENTITY();
INSERT INTO dbo.OrderItem (OrderID, ProductID, UnitPrice, Quantity) VALUES (@order1, 1, 29.99, 1);
INSERT INTO dbo.Payment (OrderID, PaymentType, PaymentStatus, PaidAt) VALUES (@order1, 'CreditCard', 'Completed', SYSUTCDATETIME());
INSERT INTO dbo.Shipment (OrderID, TrackingNumber, ShipmentStatus, ShippedAt) VALUES (@order1, 'TRK123456', 'Shipped', SYSUTCDATETIME());

-- Order 2 by Maria (UserID = 2)
INSERT INTO dbo.[Order] (UserID, OrderStatus) VALUES (2, 'Completed');
DECLARE @order2 INT = SCOPE_IDENTITY();
INSERT INTO dbo.OrderItem (OrderID, ProductID, UnitPrice, Quantity) VALUES (@order2, 2, 15.50, 2);
INSERT INTO dbo.Payment (OrderID, PaymentType, PaymentStatus, PaidAt) VALUES (@order2, 'PayPal', 'Completed', SYSUTCDATETIME());
INSERT INTO dbo.Shipment (OrderID, TrackingNumber, ShipmentStatus, ShippedAt) VALUES (@order2, 'TRK222333', 'Delivered', SYSUTCDATETIME());

-- Order 3 by Georgi (UserID = 3) - pending
INSERT INTO dbo.[Order] (UserID, OrderStatus) VALUES (3, 'Pending');
DECLARE @order3 INT = SCOPE_IDENTITY();
INSERT INTO dbo.OrderItem (OrderID, ProductID, UnitPrice, Quantity) VALUES (@order3, 3, 59.99, 1);
INSERT INTO dbo.Payment (OrderID, PaymentType, PaymentStatus) VALUES (@order3, 'CreditCard', 'Pending');

-- Order 4 by Elena (UserID = 4) - completed
INSERT INTO dbo.[Order] (UserID, OrderStatus) VALUES (4, 'Completed');
DECLARE @order4 INT = SCOPE_IDENTITY();
INSERT INTO dbo.OrderItem (OrderID, ProductID, UnitPrice, Quantity) VALUES (@order4, 4, 22.00, 1);
INSERT INTO dbo.Payment (OrderID, PaymentType, PaymentStatus, PaidAt) VALUES (@order4, 'Card', 'Completed', SYSUTCDATETIME());
INSERT INTO dbo.Shipment (OrderID, TrackingNumber, ShipmentStatus, ShippedAt) VALUES (@order4, 'TRK444555', 'Delivered', SYSUTCDATETIME());

-- Order 5 by Dimitar (UserID = 5) - completed
INSERT INTO dbo.[Order] (UserID, OrderStatus) VALUES (5, 'Completed');
DECLARE @order5 INT = SCOPE_IDENTITY();
INSERT INTO dbo.OrderItem (OrderID, ProductID, UnitPrice, Quantity) VALUES (@order5, 5, 12.99, 3);
INSERT INTO dbo.Payment (OrderID, PaymentType, PaymentStatus, PaidAt) VALUES (@order5, 'CreditCard', 'Completed', SYSUTCDATETIME());
INSERT INTO dbo.Shipment (OrderID, TrackingNumber, ShipmentStatus, ShippedAt) VALUES (@order5, 'TRK555666', 'Delivered', SYSUTCDATETIME());

GO

-- Reviews (some valid because users purchased those products)
INSERT INTO dbo.Review (UserID, ProductID, Rating, Comment) VALUES (1,1,5,'Great sound for price');
INSERT INTO dbo.Review (UserID, ProductID, Rating, Comment) VALUES (2,2,4,'Keeps my water cold all day');
INSERT INTO dbo.Review (UserID, ProductID, Rating, Comment) VALUES (4,4,5,'Very bright and adjustable');
-- Try to insert a review for a product not purchased by user 3 (this will be blocked by trigger later if attempted)
GO

-- Update product RatingAvg (simple recalculation)
UPDATE p
SET RatingAvg = sub.avgR
FROM dbo.Product p
JOIN (
    SELECT ProductID, AVG(CAST(Rating AS DECIMAL(3,2))) AS avgR
    FROM dbo.Review
    GROUP BY ProductID
) sub ON p.ProductID = sub.ProductID;
GO

-- 4) Create scalar functions
-- fn_GetAverageRating(@ProductID) returns decimal(3,2) or NULL
IF OBJECT_ID('dbo.fn_GetAverageRating','FN') IS NOT NULL DROP FUNCTION dbo.fn_GetAverageRating;
GO
CREATE FUNCTION dbo.fn_GetAverageRating(@ProductID INT)
RETURNS DECIMAL(3,2)
AS
BEGIN
    DECLARE @avg DECIMAL(9,4);
    SELECT @avg = AVG(CAST(Rating AS DECIMAL(9,4)))
    FROM dbo.Review
    WHERE ProductID = @ProductID;

    IF @avg IS NULL RETURN NULL;
    RETURN CAST(ROUND(@avg,2) AS DECIMAL(3,2));
END;
GO

-- fn_GetUserFullName(@UserID) returns NVARCHAR(200)
IF OBJECT_ID('dbo.fn_GetUserFullName','FN') IS NOT NULL DROP FUNCTION dbo.fn_GetUserFullName;
GO
CREATE FUNCTION dbo.fn_GetUserFullName(@UserID INT)
RETURNS NVARCHAR(200)
AS
BEGIN
    DECLARE @full NVARCHAR(200) = (
        SELECT TOP 1 CONCAT(FirstName, ' ', LastName)
        FROM dbo.[User]
        WHERE UserID = @UserID
    );
    RETURN ISNULL(@full,'');
END;
GO

-- 5) Stored Procedures
-- sp_GetUserOrders(@UserID) => returns orders + items
IF OBJECT_ID('dbo.sp_GetUserOrders','P') IS NOT NULL DROP PROCEDURE dbo.sp_GetUserOrders;
GO
CREATE PROCEDURE dbo.sp_GetUserOrders
    @UserID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT o.OrderID, o.OrderDate, o.OrderStatus, o.TotalAmount,
           oi.ProductID, p.Name AS ProductName, oi.UnitPrice, oi.Quantity
    FROM dbo.[Order] o
    LEFT JOIN dbo.OrderItem oi ON o.OrderID = oi.OrderID
    LEFT JOIN dbo.Product p ON oi.ProductID = p.ProductID
    WHERE o.UserID = @UserID
    ORDER BY o.OrderDate DESC, o.OrderID;
END;
GO

-- sp_AddOrder: simplified single-product order creator (transactional)
-- Parameters: @UserID, @ProductID, @Quantity, @PaymentType
IF OBJECT_ID('dbo.sp_AddOrder','P') IS NOT NULL DROP PROCEDURE dbo.sp_AddOrder;
GO
CREATE PROCEDURE dbo.sp_AddOrder
    @UserID INT,
    @ProductID INT,
    @Quantity INT,
    @PaymentType NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @price DECIMAL(10,2);
        SELECT @price = Price FROM dbo.Product WHERE ProductID = @ProductID;

        IF @price IS NULL
        BEGIN
            RAISERROR('Product not found',16,1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Check stock
        IF EXISTS (SELECT 1 FROM dbo.Product WHERE ProductID = @ProductID AND StockQty < @Quantity)
        BEGIN
            RAISERROR('Not enough stock for ProductID %d',16,1,@ProductID);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Create Order
        INSERT INTO dbo.[Order] (UserID, OrderStatus) VALUES (@UserID, 'Completed');
        DECLARE @NewOrderID INT = SCOPE_IDENTITY();

        -- Insert OrderItem
        INSERT INTO dbo.OrderItem (OrderID, ProductID, UnitPrice, Quantity)
        VALUES (@NewOrderID, @ProductID, @price, @Quantity);

        -- Create Payment
        INSERT INTO dbo.Payment (OrderID, PaymentType, PaymentStatus, PaidAt)
        VALUES (@NewOrderID, @PaymentType, 'Completed', SYSUTCDATETIME());

        -- Create Shipment (initial)
        INSERT INTO dbo.Shipment (OrderID, TrackingNumber, ShipmentStatus)
        VALUES (@NewOrderID, NULL, 'Preparing');

        -- Update stock
        UPDATE dbo.Product
        SET StockQty = StockQty - @Quantity
        WHERE ProductID = @ProductID;

        -- Recalculate and update Order.TotalAmount
        UPDATE dbo.[Order]
        SET TotalAmount = (
            SELECT SUM(UnitPrice * Quantity) FROM dbo.OrderItem WHERE OrderID = @NewOrderID
        )
        WHERE OrderID = @NewOrderID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('sp_AddOrder failed: %s',16,1,@ErrMsg);
    END CATCH
END;
GO

-- 6) Triggers
-- Trigger 1: After insert on OrderItem -> update Product.StockQty and Order.TotalAmount
IF OBJECT_ID('dbo.TR_OrderItem_AfterInsert','TR') IS NOT NULL DROP TRIGGER dbo.TR_OrderItem_AfterInsert;
GO
CREATE TRIGGER dbo.TR_OrderItem_AfterInsert
ON dbo.OrderItem
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Reduce stock for inserted items; if insufficient stock, rollback
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN dbo.Product p ON i.ProductID = p.ProductID
        WHERE p.StockQty < i.Quantity
    )
    BEGIN
        RAISERROR('Insufficient stock detected during OrderItem insert. Transaction rolled back.',16,1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Deduct stock
    UPDATE p
    SET p.StockQty = p.StockQty - i.Quantity
    FROM dbo.Product p
    JOIN inserted i ON p.ProductID = i.ProductID;

    -- Recalculate order total for affected orders
    UPDATE o
    SET o.TotalAmount = sub.SumAmt
    FROM dbo.[Order] o
    JOIN (
        SELECT oi.OrderID, SUM(oi.UnitPrice * oi.Quantity) AS SumAmt
        FROM dbo.OrderItem oi
        WHERE oi.OrderID IN (SELECT DISTINCT OrderID FROM inserted)
        GROUP BY oi.OrderID
    ) sub ON o.OrderID = sub.OrderID;
END;
GO

-- Trigger 2: Before/After insert on Review -> ensure user purchased product previously
-- We'll use AFTER INSERT but will rollback if validation fails.
IF OBJECT_ID('dbo.TR_Review_ValidatePurchase','TR') IS NOT NULL DROP TRIGGER dbo.TR_Review_ValidatePurchase;
GO
CREATE TRIGGER dbo.TR_Review_ValidatePurchase
ON dbo.Review
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.OrderItem oi
            JOIN dbo.[Order] o ON oi.OrderID = o.OrderID
            WHERE oi.ProductID = i.ProductID
              AND o.UserID = i.UserID
              AND o.OrderStatus IN ('Completed','Delivered','Shipped')
        )
    )
    BEGIN
        -- If any inserted review is for a product not purchased by the same user, rollback
        RAISERROR('Cannot add review: user has not purchased this product (or order not completed).',16,1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

-- 7) Example usage: call stored procs & functions (test)
-- Get orders for user 1:
PRINT '=== Example: sp_GetUserOrders for UserID = 1 ===';
EXEC dbo.sp_GetUserOrders @UserID = 1;
GO

-- Add a new order by using sp_AddOrder (example)
PRINT '=== Example: sp_AddOrder (User 1 buys Product 2 quantity 1) ===';
EXEC dbo.sp_AddOrder @UserID = 1, @ProductID = 2, @Quantity = 1, @PaymentType = 'CreditCard';
GO

-- Test fn_GetAverageRating
PRINT 'Average rating for ProductID = 1:';
SELECT dbo.fn_GetAverageRating(1) AS AvgRating;
GO

-- Test fn_GetUserFullName
PRINT 'Full name for UserID = 2:';
SELECT dbo.fn_GetUserFullName(2) AS FullName;
GO

-- Try to insert a fraudulent review (user 3 did NOT buy product 1) - should be blocked by trigger
BEGIN TRY
    INSERT INTO dbo.Review (UserID, ProductID, Rating, Comment) VALUES (3, 1, 4, 'I like it');
END TRY
BEGIN CATCH
    PRINT 'Expected error on invalid review insertion:';
    PRINT ERROR_MESSAGE();
END CATCH;
GO

-- Final: show counts
SELECT 
    (SELECT COUNT(*) FROM dbo.[User]) AS UsersCount,
    (SELECT COUNT(*) FROM dbo.Product) AS ProductsCount,
    (SELECT COUNT(*) FROM dbo.[Order]) AS OrdersCount,
    (SELECT COUNT(*) FROM dbo.OrderItem) AS OrderItemsCount,
    (SELECT COUNT(*) FROM dbo.Review) AS ReviewCount;
GO

CREATE VIEW V_SalesByCategory AS
SELECT c.Name AS CategoryName, SUM(oi.Quantity * p.Price) AS TotalSales
FROM OrderItem oi
JOIN Product p ON oi.ProductID = p.ProductID
JOIN Category c ON p.CategoryID = c.CategoryID
GROUP BY c.Name;
GO

CREATE VIEW V_OrdersBySellerCountry AS
SELECT s.Country, COUNT(DISTINCT oi.OrderID) AS OrdersCount
FROM OrderItem oi
JOIN Product p ON oi.ProductID = p.ProductID
JOIN Seller s ON p.SellerID = s.SellerID
GROUP BY s.Country;
Go

CREATE VIEW V_AvgRatingByProduct AS
SELECT p.Name AS ProductName, AVG(r.Rating) AS AvgRating, COUNT(r.ReviewID) AS ReviewCount
FROM Review r
JOIN Product p ON r.ProductID = p.ProductID
GROUP BY p.Name;
Go

CREATE VIEW V_PaymentTypeDistribution AS
SELECT PaymentType, COUNT(*) AS PaymentCount
FROM Payment
GROUP BY PaymentType;
Go

SELECT * FROM V_SalesByCategory
SELECT * FROM V_OrdersBySellerCountry
SELECT * FROM V_AvgRatingByProduct
SELECT * FROM V_PaymentTypeDistribution

-- End of TemuDB 
PRINT 'TemuDB creation and seeding completed.';
GO

CREATE DATABASE TemuDW;
GO
USE TemuDW;
GO

-- DimUser 
CREATE TABLE DimUser (
    UserID INT PRIMARY KEY,
    FullName AS (FirstName + ' ' + LastName) PERSISTED,
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    Email NVARCHAR(150),
    Phone NVARCHAR(30),
    RegistrationDate DATE
);
GO

-- DimSeller 
CREATE TABLE DimSeller (
    SellerID INT PRIMARY KEY,
    Name NVARCHAR(150),
    Country NVARCHAR(100),
    RatingAvg DECIMAL(3,2)
);
GO

-- DimCategory 
CREATE TABLE DimCategory (
    CategoryID INT PRIMARY KEY,
    Name NVARCHAR(100),
    Description NVARCHAR(400)
);
GO

-- DimProduct
CREATE TABLE DimProduct (
    ProductID INT PRIMARY KEY,
    Name NVARCHAR(200),
    Description NVARCHAR(1000),
    Price DECIMAL(10,2),
    StockQty INT,
    RatingAvg DECIMAL(3,2),
    CategoryID INT,
    SellerID INT,
    FOREIGN KEY (CategoryID) REFERENCES dbo.DimCategory(CategoryID),
    FOREIGN KEY (SellerID) REFERENCES dbo.DimSeller(SellerID)
);
GO

-- DimDate
CREATE TABLE DimDate (
    DateID INT PRIMARY KEY,
    FullDate DATE,
    Year INT,
    Month INT,
    MonthName NVARCHAR(15),
    Quarter INT,
    Day INT,
    WeekdayName NVARCHAR(15)
);
GO

-- DimPaymentType
CREATE TABLE DimPaymentType (
    PaymentTypeID INT IDENTITY(1,1) PRIMARY KEY,
    PaymentTypeName NVARCHAR(50)
);
GO

-- DimPaymentStatus
CREATE TABLE DimPaymentStatus (
    PaymentStatusID INT IDENTITY(1,1) PRIMARY KEY,
    PaymentStatusName NVARCHAR(50)
);
GO

-- DimShipmentStatus
CREATE TABLE DimShipmentStatus (
    ShipmentStatusID INT IDENTITY(1,1) PRIMARY KEY,
    ShipmentStatusName NVARCHAR(50)
);
GO

-- FactSales
CREATE TABLE FactSales (
    SalesID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT,
    ProductID INT,
    UserID INT,
    SellerID INT,
    CategoryID INT,
    DateID INT,
    Quantity INT,
    UnitPrice DECIMAL(10,2),
    TotalAmount AS (Quantity * UnitPrice) PERSISTED,
    FOREIGN KEY (ProductID) REFERENCES DimProduct(ProductID),
    FOREIGN KEY (UserID) REFERENCES DimUser(UserID),
    FOREIGN KEY (SellerID) REFERENCES DimSeller(SellerID),
    FOREIGN KEY (CategoryID) REFERENCES DimCategory(CategoryID),
    FOREIGN KEY (DateID) REFERENCES DimDate(DateID)
);
GO

-- FactPayment
CREATE TABLE FactPayment (
    PaymentFactID INT IDENTITY(1,1) PRIMARY KEY,
    PaymentID INT,
    OrderID INT,
    PaymentTypeID INT,
    PaymentStatusID INT,
    DateID INT,
    PaidAmount DECIMAL(12,2),
    FOREIGN KEY (PaymentTypeID) REFERENCES DimPaymentType(PaymentTypeID),
    FOREIGN KEY (PaymentStatusID) REFERENCES DimPaymentStatus(PaymentStatusID),
    FOREIGN KEY (DateID) REFERENCES DimDate(DateID)
);
GO

-- FactShipment
CREATE TABLE FactShipment (
    ShipmentFactID INT IDENTITY(1,1) PRIMARY KEY,
    ShipmentID INT,
    OrderID INT,
    ShipmentStatusID INT,
    DateID INT,
    DeliveryDays INT,
    FOREIGN KEY (ShipmentStatusID) REFERENCES DimShipmentStatus(ShipmentStatusID),
    FOREIGN KEY (DateID) REFERENCES DimDate(DateID)
);
GO

-- End of TemuDW
PRINT 'TemuDW creation completed.';
GO

