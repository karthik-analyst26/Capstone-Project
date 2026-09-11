-- ============================================================
-- PROJECT: Analyzing E-Learning Platform Purchases using MySQL
-- ============================================================
-- This script:
--   1. Creates the database and three tables (learners, courses, purchases)
--   2. Inserts sample data
--   3. Runs data exploration queries (INNER / LEFT / RIGHT JOIN)
--   4. Runs analytical queries (Q1 - Q5)
-- ============================================================


-- ============================================================
-- STEP 1: CREATE DATABASE
-- ============================================================

-- Create a new database for this project (skip if it already exists)
CREATE DATABASE IF NOT EXISTS elearning_platform;

-- Select the database so all following commands run inside it
USE elearning_platform;


-- ============================================================
-- STEP 2: CREATE TABLES
-- ============================================================

-- Drop tables first (useful if you need to re-run the script from scratch)
-- Order matters: drop child tables (with foreign keys) before parent tables
DROP TABLE IF EXISTS purchases;
DROP TABLE IF EXISTS courses;
DROP TABLE IF EXISTS learners;

-- Table 1: learners
-- Stores basic profile info for each learner on the platform
CREATE TABLE learners (
    learner_id  INT AUTO_INCREMENT PRIMARY KEY,   -- unique ID for each learner
    full_name   VARCHAR(100) NOT NULL,            -- learner's full name
    country     VARCHAR(50)  NOT NULL             -- learner's country
);

-- Table 2: courses
-- Stores the catalog of courses available for purchase
CREATE TABLE courses (
    course_id    INT AUTO_INCREMENT PRIMARY KEY,  -- unique ID for each course
    course_name  VARCHAR(150) NOT NULL,           -- name of the course
    category     VARCHAR(50)  NOT NULL,           -- course category (e.g., Programming)
    unit_price   DECIMAL(8,2) NOT NULL            -- price per unit of the course
);

-- Table 3: purchases
-- Records every purchase transaction, linking a learner to a course
CREATE TABLE purchases (
    purchase_id    INT AUTO_INCREMENT PRIMARY KEY,          -- unique ID for each purchase
    learner_id     INT NOT NULL,                            -- FK -> learners.learner_id
    course_id      INT NOT NULL,                            -- FK -> courses.course_id
    quantity       INT NOT NULL DEFAULT 1,                  -- number of units/seats purchased
    purchase_date  DATE NOT NULL,                           -- date of purchase
    CONSTRAINT fk_purchases_learner
        FOREIGN KEY (learner_id) REFERENCES learners(learner_id)
        ON DELETE CASCADE,                                  -- remove purchases if learner is deleted
    CONSTRAINT fk_purchases_course
        FOREIGN KEY (course_id) REFERENCES courses(course_id)
        ON DELETE CASCADE                                   -- remove purchases if course is deleted
);


-- ============================================================
-- STEP 3: INSERT SAMPLE DATA
-- ============================================================

-- Insert 5 learners from different countries
INSERT INTO learners (full_name, country) VALUES
('Alice Johnson', 'USA'),          -- learner_id = 1
('Ravi Kumar',    'India'),        -- learner_id = 2
('Maria Garcia',  'Spain'),        -- learner_id = 3
('John Smith',    'UK'),           -- learner_id = 4
('Aiko Tanaka',   'Japan');        -- learner_id = 5

-- Insert 5 courses spread across 5 different categories
-- Note: "Advanced Excel Techniques" is intentionally left with NO purchases,
-- so it can be used later to demonstrate Q5 (courses never purchased)
INSERT INTO courses (course_name, category, unit_price) VALUES
('Python for Beginners',        'Programming',   49.99),  -- course_id = 1
('Data Analysis with SQL',      'Data Science',  59.99),  -- course_id = 2
('UI/UX Design Basics',         'Design',        39.99),  -- course_id = 3
('Digital Marketing 101',       'Marketing',     29.99),  -- course_id = 4
('Advanced Excel Techniques',   'Business',      34.99);  -- course_id = 5 (never purchased)

-- Insert 8 purchase records referencing the learners and courses above
INSERT INTO purchases (learner_id, course_id, quantity, purchase_date) VALUES
(1, 1, 2, '2024-01-05'),  -- Alice buys Python for Beginners x2
(1, 3, 1, '2024-01-10'),  -- Alice buys UI/UX Design Basics x1
(2, 2, 1, '2024-01-15'),  -- Ravi buys Data Analysis with SQL x1
(2, 1, 1, '2024-02-01'),  -- Ravi buys Python for Beginners x1
(3, 4, 3, '2024-02-05'),  -- Maria buys Digital Marketing 101 x3
(4, 2, 2, '2024-02-10'),  -- John buys Data Analysis with SQL x2
(4, 4, 1, '2024-02-15'),  -- John buys Digital Marketing 101 x1
(5, 3, 2, '2024-03-01');  -- Aiko buys UI/UX Design Basics x2


-- ============================================================
-- STEP 4: DATA EXPLORATION USING JOINS
-- ============================================================

-- ------------------------------------------------------------
-- Query A: INNER JOIN
-- Combine learners + purchases + courses to show full purchase
-- details only for records that have matching rows in all 3 tables.
-- ------------------------------------------------------------
SELECT
    l.full_name                                AS learner_name,
    l.country                                  AS country,
    c.course_name                              AS course_name,
    c.category                                 AS category,
    p.quantity                                 AS quantity,
    FORMAT(p.quantity * c.unit_price, 2)       AS total_amount,   -- currency formatted to 2 decimals
    p.purchase_date                            AS purchase_date
FROM learners l
INNER JOIN purchases p ON l.learner_id = p.learner_id
INNER JOIN courses c   ON p.course_id  = c.course_id
ORDER BY (p.quantity * c.unit_price) DESC;   -- highest total_amount first

-- ------------------------------------------------------------
-- Query B: LEFT JOIN
-- Show ALL learners, and their purchases if any exist.
-- Learners with no purchases would still appear, with NULLs
-- in the course/purchase columns.
-- ------------------------------------------------------------
SELECT
    l.full_name                                AS learner_name,
    l.country                                  AS country,
    c.course_name                              AS course_name,
    c.category                                 AS category,
    p.quantity                                 AS quantity,
    FORMAT(p.quantity * c.unit_price, 2)       AS total_amount,
    p.purchase_date                            AS purchase_date
FROM learners l
LEFT JOIN purchases p ON l.learner_id = p.learner_id
LEFT JOIN courses c   ON p.course_id  = c.course_id
ORDER BY total_amount DESC;

-- ------------------------------------------------------------
-- Query C: RIGHT JOIN
-- Show ALL courses (even ones never purchased), together with
-- any purchase/learner details that exist for them.
-- Using purchases RIGHT JOIN courses ensures every course appears,
-- even "Advanced Excel Techniques" which has zero purchases.
-- ------------------------------------------------------------
SELECT
    c.course_name                                          AS course_name,
    c.category                                             AS category,
    l.full_name                                            AS learner_name,
    l.country                                              AS country,
    p.quantity                                             AS quantity,
    FORMAT(p.quantity * c.unit_price, 2)                   AS total_amount,
    p.purchase_date                                        AS purchase_date
FROM purchases p
RIGHT JOIN courses c  ON p.course_id  = c.course_id
LEFT JOIN learners l  ON p.learner_id = l.learner_id
ORDER BY total_amount DESC;


-- ============================================================
-- STEP 5: ANALYTICAL QUERIES
-- ============================================================

-- ------------------------------------------------------------
-- Q1. Each learner's total spending (quantity x unit_price)
--     along with their country.
-- ------------------------------------------------------------
SELECT
    l.full_name                                AS learner_name,
    l.country                                  AS country,
    FORMAT(SUM(p.quantity * c.unit_price), 2)  AS total_spent
FROM learners l
JOIN purchases p ON l.learner_id = p.learner_id
JOIN courses c   ON p.course_id  = c.course_id
GROUP BY l.learner_id, l.full_name, l.country
ORDER BY SUM(p.quantity * c.unit_price) DESC;   -- highest spender first

-- ------------------------------------------------------------
-- Q2. Top 3 most purchased courses based on total quantity sold.
-- ------------------------------------------------------------
SELECT
    c.course_name                  AS course_name,
    c.category                     AS category,
    SUM(p.quantity)                AS total_quantity_sold
FROM courses c
JOIN purchases p ON c.course_id = p.course_id
GROUP BY c.course_id, c.course_name, c.category
ORDER BY total_quantity_sold DESC, c.course_name ASC   -- tie-break alphabetically
LIMIT 3;

-- ------------------------------------------------------------
-- Q3. Each course category's total revenue and the number of
--     unique learners who purchased from that category.
-- ------------------------------------------------------------
SELECT
    c.category                                     AS category,
    FORMAT(SUM(p.quantity * c.unit_price), 2)      AS total_revenue,
    COUNT(DISTINCT p.learner_id)                   AS unique_learners
FROM courses c
JOIN purchases p ON c.course_id = p.course_id
GROUP BY c.category
ORDER BY SUM(p.quantity * c.unit_price) DESC;   -- highest revenue category first

-- ------------------------------------------------------------
-- Q4. List all learners who have purchased courses from more
--     than one category.
-- ------------------------------------------------------------
SELECT
    l.full_name                        AS learner_name,
    l.country                          AS country,
    COUNT(DISTINCT c.category)         AS distinct_categories_purchased
FROM learners l
JOIN purchases p ON l.learner_id = p.learner_id
JOIN courses c   ON p.course_id  = c.course_id
GROUP BY l.learner_id, l.full_name, l.country
HAVING COUNT(DISTINCT c.category) > 1
ORDER BY distinct_categories_purchased DESC;

-- ------------------------------------------------------------
-- Q5. Identify courses that have not been purchased at all.
-- ------------------------------------------------------------
SELECT
    c.course_id     AS course_id,
    c.course_name   AS course_name,
    c.category      AS category
FROM courses c
LEFT JOIN purchases p ON c.course_id = p.course_id
WHERE p.purchase_id IS NULL;   -- no matching purchase row means never purchased

-- ============================================================
-- END OF SCRIPT
-- ============================================================
