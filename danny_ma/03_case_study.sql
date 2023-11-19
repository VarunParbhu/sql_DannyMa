USE foodie_fi;
-- A. Customer Journey

-- Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.
-- Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!

-- B. Data Analysis Questions

-- How many customers has Foodie-Fi ever had?
SELECT DISTINCT TOP(1) customer_id
FROM subscriptions
ORDER BY customer_id DESC;


-- What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT MONTH(start_date) AS Month,
    COUNT(MONTH(start_date)) AS NumofSubs
FROM subscriptions
WHERE plan_id = 0
GROUP BY MONTH(start_date)
ORDER BY MONTH(start_date);


-- What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT plan_name,
    COUNT(plan_name) AS NumOfCustomer
FROM subscriptions
    JOIN plans ON subscriptions.plan_id = plans.plan_id
WHERE YEAR(start_date) >= 2020
    AND YEAR(start_date) < 2021
GROUP BY plan_name;


-- What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT CAST (
        (
            (
                SELECT COUNT(plans.plan_name) as count
                FROM subscriptions
                    JOIN plans ON subscriptions.plan_id = plans.plan_id
                WHERE plans.plan_name = 'churn'
                GROUP BY plans.plan_name
            ) /(
                (
                    SELECT CAST (
                            (
                                (
                                    SELECT DISTINCT TOP(1) customer_id
                                    FROM subscriptions
                                    ORDER BY customer_id DESC
                                )
                            ) AS decimal(18, 4)
                        ) AS count2
                )
            )
        ) AS DECIMAL(18, 1)
    ) AS percentage;


-- How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
WITH CTE AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY start_date
        ) AS sequence
    FROM subscriptions
),
CTE2 AS (
    SELECT COUNT (customer_id) AS churnClient
    FROM CTE
    WHERE [sequence] = 2
        AND plan_id = 4
)
SELECT CAST(
        churnClient / (
            SELECT CAST (
                    (
                        (
                            SELECT DISTINCT TOP(1) customer_id
                            FROM subscriptions
                            ORDER BY customer_id DESC
                        )
                    ) AS decimal(18, 4)
                ) AS count2
        ) * 100 AS INTEGER
    ) AS '% Churn dir'
FROM CTE2;


-- What is the number and percentage of customer plans after their initial free trial?
WITH CTE AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY start_date
        ) AS sequence
    FROM subscriptions
),
CTE2 AS (
    SELECT plans.plan_name
    FROM CTE
        JOIN plans on CTE.plan_id = plans.plan_id
    WHERE [sequence] = 2
)
SELECT plan_name,
    (
        CAST(
            (
                COUNT(plan_name) /(
                    SELECT CAST (
                            (
                                (
                                    SELECT DISTINCT TOP(1) customer_id
                                    FROM subscriptions
                                    ORDER BY customer_id DESC
                                )
                            ) AS decimal(18, 4)
                        )
                )
            ) * 100 AS DECIMAL(18, 2)
        )
    ) AS '% afte trial '
FROM CTE2
GROUP BY plan_name
ORDER BY [% afte trial ] DESC;


-- What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

-- How many customers have upgraded to an annual plan in 2020?
-- How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
-- Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
-- How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

-- C. Challenge Payment Question

-- The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:
-- -- monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
-- -- upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
-- -- upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
-- -- once a customer churns they will no longer make payments

-- D. Outside The Box Questions

-- -- The following are open ended questions which might be asked during a technical interview for this case study - there are no right or wrong answers, but answers that make sense from both a technical and a business perspective make an amazing impression!

-- How would you calculate the rate of growth for Foodie-Fi?
-- What key metrics would you recommend Foodie-Fi management to track over time to assess performance of their overall business?
-- What are some key customer journeys or experiences that you would analyse further to improve customer retention?
-- If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription, what questions would you include in the survey?
-- What business levers could the Foodie-Fi team use to reduce the customer churn rate? How would you validate the effectiveness of your ideas?