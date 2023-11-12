# Week 3

## Q: In addition to your query, please submit a short description of what you determined from the query profile and how you structured your query to plan for a higher volume of events once the website traffic increases.

The main optimization introduced in the query is to extract three columns from the main table in a CTE (data_perp) where all subsequent CTEs draw the data from.
This allows to minimize the table scans to a maximum of one per query and allows for efficient use of the chached results.

The main optimization which could improve the performance of this report is to make it a partitioned table, partitioned by day. From the query profile (as well as the table definitoin of `website_activity`) we can see that the data is stored in one partition. 
This is for sure the most important source of inefficiency, as the granularity of our report is at the daily level and values from past dates do not change, but the fact that the data is not partitioned forces frequent full table scans to recompute the report's metrics.