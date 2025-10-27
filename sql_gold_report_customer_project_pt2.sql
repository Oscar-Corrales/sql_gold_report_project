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