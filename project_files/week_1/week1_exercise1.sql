-- EXERCISE 1:
--------------
-- approach:
--     1. cleanup customer, suppliers and cities tables. enrich suppliers table with geolocation data from cities table
--     2. join customers to cities to produce a list of eligible customers. filter out those not having a location
--     3. cross join customers and suppliers, rank the results by distance for each customer and chose the closest supplier.

with customers as (
    -- cleanup customer table
    select customer_id,
        first_name,
        last_name,
        lower(trim(email)) as email,
        lower(trim(customer_city)) as customer_city,
        lower(trim(customer_state)) customer_state
    from customer_data a
        left join customer_address b using (customer_id)
),

cities as (
    -- remove duplicates from cities
    select lower(trim(city_name)) city_name,
        lower(trim(state_abbr)) as city_state,
        geo_location,
        row_number() over(
            partition by lower(trim(city_name)),
            lower(trim(state_abbr))
            order by city_id
        ) rownum
    from resources.us_cities qualify rownum = 1
),

suppliers as (
    -- cleanup suppliers table
    select supplier_id,
        supplier_name,
        lower(trim(supplier_city)) supplier_city,
        lower(trim(supplier_state)),
        supplier_state,
        geo_location
    from suppliers.supplier_info a
        left join cities b on lower(trim(a.supplier_city)) = b.city_name
        and lower(trim(supplier_state)) = city_state
),

eligible_customers as (
    -- customers with a valid adress
    select customer_id,
        first_name,
        last_name,
        email,
        customer_city,
        customer_state,
        geo_location
    from customers a
        left join cities b on a.customer_city = b.city_name
        and a.customer_state = b.city_state
    where geo_location is not null
),

customer_to_supplier as (
    -- cross join to calculate the distance between customers and each supplier
    select *,
        round(st_distance(a.geo_location, b.geo_location) / 1000, 1) AS distance_km,
        rank() over(
            partition by customer_id
            order by distance_km asc
        ) as store_rank
    from eligible_customers a
        join suppliers b qualify store_rank = 1
)


select customer_id,
    first_name as customer_first_name,
    last_name as customer_last_name,
    email customer_email,
    supplier_id,
    supplier_name,
    distance_km as shipping_distance_km
from customer_to_supplier