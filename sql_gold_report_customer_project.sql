/* 
===========================================================================================
Customer Report 

Purpose: 
	- This report brings together important information about customers and how they behave.

============================================================================================
	Hghlights: 
	1. Gather essential fields such as names,ages, and transaction details.
	2. Segments customers into categories (VIP,Regular,New) and age groups.
	3. Aggregates customer-level metrics:
		- total orders
		- total sales 
		- total quantity purchased 
		- total products 
		- lifespan (in months) 
	4. Calculates valuable KPI's:
		- recency (months since last order) 
		- average order value 
		- average monthly spend 
=============================================================================================
Skills Demonstrated:
- Advanced SQL techniques like CTEs (WITH statements), joins, aggregations, and CASE statements.
- Calculated dates and times for customer age, lifespan, and recency.
- Computed key business metrics such as average order value and average monthly spend.
- Created customer segments to classify customers as VIP, Regular, or New.
- Built reusable views that other analysts can use for reporting and analysis.
========================================================================================
Business Impact:
- Provides insights into customer behavior and sales performance.
- Helps marketing and sales teams find high-value customers and retention opportunities.
- Supports reports and visualizations by age group and customer segment.
- Enables data-driven decisions for promotions, loyalty programs, and product strategy.
========================================================================================
Future Enhancements:
- Add customer location to analyze trends by region.
- Include product category to understand customer preferences.
- Add cohort analysis to track customer behavior over time.
- Include predictive metrics like customer lifetime value or risk of churn.
- Improve performance for large datasets using indexing or partitioning.
========================================================================================
Collaboration & Analysis:
- Designed the view for use by analysts, data scientists, and business teams.
- Wrote clear and organized SQL so team members can easily use or update it.
- Focused on KPIs and segments that matter most for business decisions.
========================================================================================
*/

create view gold.report_customers as 
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

/*==============================================================================
Other analysts can pull from this report in gold.report_customers, such as to 
analyze customer data by age group. They can count customers, sum total sales, 
visualize trends, and generate insights about which age groups contribute most
to overall sales, all without querying the raw table directly.
==============================================================================*/

select 
age_group,
count(customer_key) as total_customers ,
sum(total_sales) as total_sales 
from gold.report_customers 
group by age_group
