/* 
===========================================================================================
Customer Behavior Analysis Project

Purpose:

	-Understand customer age groups, buying habits, and segment differences
	-Find problems with keeping customers and ways to make more money
	-Help marketing teams make better decisions based on data

============================================================================================
Business Questions Addressed:

	-Which customer segments drive our business?
	-How engaged are our customers?
	-Which age groups are most valuable?
	-How does each customer segment perform relative to the overall average?
	
============================================================================================
Key Findings:

	-66% of customers are 50+, only 1% are 30-39 (risk of losing customers as they age)
	-79% are "New" customers who don't buy much ($757 average value)
	-VIP customers (9%) make almost the same money as New customers (79%)
	-63% of customers buy once and never come back
	-One-time buyers are a big opportunity to improve
	
============================================================================================
Dataset Overview:

	- Total Customers: 18,482
	- Total Revenue: ~$29.5M
	- Data Period: 2014 (Historical Analysis)
	- Source: gold.report_customers view
	
============================================================================================
SQL Skills Used:

	-GROUP BY to count and sum data
	-Grouping customers into segments
	-Window functions to compare to averages
	-CASE statements to create categories
	-Calculating important business numbers (customer value, order value, engagement)
	-Turning data into clear business insights
	
========================================================================================
Business Value:

	-Found that 40%+ of customers leave after first purchase
	-Showed VIP customers are worth 8x more than New customers
	-Found risk in having mostly older customers
	-Gave clear steps to keep customers longer
	-Identified which age groups and segments to focus on
	
========================================================================================
What We Should Do:

	-Create programs to turn New customers into Regular and VIP customers
	-Find out why people aged 30-39 aren't buying and fix it
	-Follow up with customers after first purchase to keep them coming back
	-Offer rewards for customers who buy multiple times
	-Market to younger people to keep business healthy long-term
	
============================================================================================*/

--CREATE VIEW gold.report_customers as 

with base_query as 
/*-------------------------------------------------------
	1) Base Query: Retrieve core columns from tables
-------------------------------------------------------*/ 
(
select 
	s.order_number,
	s.product_key,
	s.order_date,
	s.sales_amount,
	s.quantity,
	c.customer_key,
	c.customer_number,
	concat(c.first_name,' ',c.last_name) as customer_name,
	datediff(year,c.birthdate,getdate()) as age
from gold.fact_sales as s
left join gold.dim_customers as c
on s.customer_key = c.customer_key
where order_date is not null
) 

, customer_aggregation as 
/*------------------------------------------------------------------------
2) Customer Aggregations: Summarizes key metrics at the customer level
------------------------------------------------------------------------*/
(
select 
	customer_key,
	customer_number,
	customer_name,
	age,
	count(distinct order_number) as total_orders,
	sum(sales_amount) as total_sales,
	sum(quantity) as total_units_sold,
	count(distinct product_key) as total_products,
	max(order_date) as last_order,
	datediff(month,min(order_date),max(order_date)) as lifespan
from base_query 
group by 
	customer_key,
	customer_number,
	customer_name,
	age
)

select 
	customer_key,
	customer_number,
	customer_name,
	age,
case 
	when age < 20 then 'Under 20' 
	when age between 20 and 29 then '20-29' 
	when age between 30 and 39 then '30-39'
	when age between 40 and 49 then '40-49'
	else '50 and above'
	end as age_group ,
case 
	when total_sales > 5000 and lifespan >= 12 then 'VIP' 
	when total_sales <= 5000 and lifespan >= 12 then 'Regular' 
	else 'New'
end as customer_segment ,
	last_order,
	datediff(month,last_order,getdate()) as recency_order,
	total_orders,
	total_sales,
	total_units_sold,
	total_products,
	lifespan ,
-- compute average order value (AVO)
case 
	when total_orders = 0 then 0 
	else total_sales/total_orders 
	end as avg_order_value,
-- compute average monthly spend
case 
	when lifespan = 0 then total_sales 
	else total_sales/lifespan 
	end as avg_monthly_spend  
from customer_aggregation


/*====================================================================================================================*/
/*====================================================================================================================*/
/*                                        ANALYSIS QUERIES                                                            */
/*====================================================================================================================*/
/*====================================================================================================================*/


/*====================================================================================================================*/

-- Business Question #2: Which customer segments drive our business?

/*Customer Engagement Analysis
Most customers (79% or 14,629) are "New," spending only $757 each for $11.1M total. VIP customers are 
just 9% (1,653) but spend $6,509 each, generating nearly the same revenue at $10.8M—one VIP worth over
8 New customers. Regular customers are 12% (2,200) at $3,410 each, contributing $7.5M. We're not converting
New customers into repeat buyers. Since VIPs are significantly more valuable, we need strategies to move customers
from New to VIP status to increase revenue.*/

SELECT 
    customer_segment,
    COUNT(customer_key) AS total_customers,
    SUM(total_sales) AS total_revenue,
    AVG(total_sales) AS avg_revenue_per_customer
FROM gold.report_customers
GROUP BY customer_segment
ORDER BY total_revenue DESC;

/*====================================================================================================================*/

-- Business Question #3: How engaged are our customers?

/* Customer Engagement Level Analysis
Most customers (63% or 11,617) buy once and never return, generating $6.7M. Occasional buyers with 2-5 orders (37% or 6,821) 
contribute the most at $22.5M, proving repeat customers are more valuable. Only 44 customers (0.2%) are frequent buyers with
5+ orders, bringing in $135K. We lose over 40% after the first purchase and almost nobody becomes frequent. We need to create
incentives like loyalty rewards or follow-up offers to drive repeat purchases. */

SELECT 
    CASE 
        WHEN total_orders = 1 THEN 'Single Purchase'
        WHEN total_orders BETWEEN 2 AND 5 THEN 'Occasional (2-5 orders)'
        WHEN total_orders > 5 THEN 'Frequent (5+ orders)'
    END AS engagement_level,
    COUNT(customer_key) AS customer_count,
    SUM(total_sales) AS total_revenue
FROM gold.report_customers
GROUP BY 
    CASE 
        WHEN total_orders = 1 THEN 'Single Purchase'
        WHEN total_orders BETWEEN 2 AND 5 THEN 'Occasional (2-5 orders)'
        WHEN total_orders > 5 THEN 'Frequent (5+ orders)'
    END
ORDER BY total_revenue DESC;

/*====================================================================================================================*/

-- Business Question #4: Which age groups are most valuable?

/* Age Group Performance Analysis
The 50+ group dominates with 12,183 customers (66%) generating $19.5M at $1,601 per customer. 
The 40-49 group has 6,103 customers (33%) bringing in $9.6M with similar spending patterns. 
The 30-39 group has only 196 customers (1%) generating $280K with lower spending at $1,428 per 
customer. Older groups drive revenue through volume and consistent spending, while younger customers
spend less, possibly explaining our difficulty attracting them. */

SELECT 
    age_group,
    COUNT(customer_key) AS total_customers,
    SUM(total_sales) AS total_revenue,
    AVG(total_sales) AS avg_customer_value,
    AVG(avg_order_value) AS avg_order_value
FROM gold.report_customers
GROUP BY age_group
ORDER BY total_revenue DESC;

/*====================================================================================================================*/

-- Business Question #5: How does each customer segment perform relative to the overall average?

/*Segment Performance vs Company Benchmarks
VIP customers (1,653) outperform significantly at $6,509 each with 2 orders averaging $2,633, both 
well above average. Regular customers (2,200) perform near average at $3,410 per customer. New 
customers (14,629) underperform at only $757 per customer with 1 order averaging $601—both far below average.
VIPs deliver exceptional value while New customers drag down performance. Converting New customers to VIP status
is critical for improving overall metrics. */

SELECT 
    customer_segment,
    COUNT(customer_key) AS customer_count,
    ROUND(AVG(total_sales), 2) AS avg_customer_value,
    ROUND(AVG(total_sales) - AVG(AVG(total_sales)) OVER(), 2) AS value_vs_average,
    ROUND(AVG(total_orders), 2) AS avg_orders,
    ROUND(AVG(total_orders) - AVG(AVG(total_orders)) OVER(), 2) AS orders_vs_average,
    ROUND(AVG(avg_order_value), 2) AS avg_order_value,
    ROUND(AVG(avg_order_value) - AVG(AVG(avg_order_value)) OVER(), 2) AS aov_vs_average
FROM gold.report_customers
GROUP BY customer_segment
ORDER BY avg_customer_value DESC;
