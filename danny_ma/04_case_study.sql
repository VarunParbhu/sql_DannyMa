USE data_bank;

SELECT *
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';

-- TABLES
--- regions
SELECT * FROM regions
--- customer_nodes
SELECT * FROM customer_nodes
--- customer_transactions
SELECT * FROM customer_transactions

-- A. Customer Nodes Exploration

-- How many unique nodes are there on the Data Bank system?
SELECT COUNT (DISTINCT node_id) AS 'Unique Nodes'
FROM customer_nodes;

-- What is the number of nodes per region?
SELECT region_name, COUNT(node_id) AS 'Number of Nodes' FROM customer_nodes
JOIN regions ON regions.region_id = customer_nodes.region_id
GROUP BY region_name;

SELECT c.region_id,
        region_name, 
        count(node_id) as total_nodes
FROM customer_nodes c 
JOIN regions r ON c.region_id = r.region_id
GROUP BY c.region_id,region_name
ORDER BY c.region_id

-- How many customers are allocated to each region?
SELECT region_name, COUNT(DISTINCT customer_id) AS 'Number of Customers' FROM customer_nodes
JOIN regions ON customer_nodes.region_id = regions.region_id
GROUP BY region_name;

-- How many days on average are customers reallocated to a different node?
SELECT AVG(DATEDIFF(day,start_date,end_date)) AS 'DayAtNode' FROM customer_nodes
WHERE end_date!='9999-12-31';

-- What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
WITH CTE AS (
    SELECT region_id,
        DATEDIFF(day, start_date, end_date) AS allocation_days
    FROM customer_nodes
    WHERE end_date != '9999-12-31'
)
SELECT DISTINCT region_id,
    PERCENTILE_CONT(0.5) WITHIN GROUP (
        ORDER BY allocation_days
    ) OVER (PARTITION BY region_id) AS 'median',
    PERCENTILE_CONT(0.8) WITHIN GROUP (
        ORDER BY allocation_days
    ) OVER (PARTITION BY region_id) AS '80th_percentile',
    PERCENTILE_CONT(0.95) WITHIN GROUP (
        ORDER BY allocation_days
    ) OVER (PARTITION BY region_id) AS '95th_percentile'
FROM CTE;

-- B. Customer Transactions

-- What is the unique count and total amount for each transaction type?
-- What is the average total historical deposit counts and amounts for all customers?
-- For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
-- What is the closing balance for each customer at the end of the month?
-- What is the percentage of customers who increase their closing balance by more than 5%?
-- C. Data Allocation Challenge

-- To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:

-- Option 1: data is allocated based off the amount of money at the end of the previous month
-- Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
-- Option 3: data is updated real-time
-- For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:

-- running customer balance column that includes the impact each transaction
-- customer balance at the end of each month
-- minimum, average and maximum values of the running balance for each customer
-- Using all of the data available - how much data would have been required for each option on a monthly basis?

-- D. Extra Challenge

-- Data Bank wants to try another option which is a bit more difficult to implement - they want to calculate data growth using an interest calculation, just like in a traditional savings account you might have with a bank.

-- If the annual interest rate is set at 6% and the Data Bank team wants to reward its customers by increasing their data allocation based off the interest calculated on a daily basis at the end of each day, how much data would be required for this option on a monthly basis?

-- Special notes:

-- Data Bank wants an initial calculation which does not allow for compounding interest, however they may also be interested in a daily compounding interest calculation so you can try to perform this calculation if you have the stamina!
-- Extension Request

-- The Data Bank team wants you to use the outputs generated from the above sections to create a quick Powerpoint presentation which will be used as marketing materials for both external investors who might want to buy Data Bank shares and new prospective customers who might want to bank with Data Bank.

-- Using the outputs generated from the customer node questions, generate a few headline insights which Data Bank might use to market it’s world-leading security features to potential investors and customers.

-- With the transaction analysis - prepare a 1 page presentation slide which contains all the relevant information about the various options for the data provisioning so the Data Bank management team can make an informed decision.

-- Conclusion

-- This case study aims to mimic traditional banking style transactions data but with a twist - hopefully it can give you some insight into the types of datasets you might encounter in a customer banking scenario.