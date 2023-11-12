-- CTE to calculate food preference count for each customer
with food_preference_count as (
    select
        customer_id,
        count(*) as food_pref_count
    from
        vk_data.customers.customer_survey
    where
        is_active = true
    group by
        1
)

-- CTE to get the geo_location for Chicago
, chicago_geo as (
    select
        geo_location
    from
        vk_data.resources.us_cities
    where
        city_name = 'CHICAGO'
        and state_abbr = 'IL'
)

-- CTE to get the geo_location for Gary
, gary_geo as (
    select
        geo_location
    from
        vk_data.resources.us_cities
    where
        city_name = 'GARY'
        and state_abbr = 'IN'
)

-- Main query
select
    c.first_name || ' ' || c.last_name as customer_name,
    ca.customer_city,
    ca.customer_state,
    s.food_pref_count,
    (st_distance(us.geo_location, chic.geo_location) / 1609)::int as chicago_distance_miles,
    (st_distance(us.geo_location, gary.geo_location) / 1609)::int as gary_distance_miles
from
    vk_data.customers.customer_address as ca
join
    vk_data.customers.customer_data c on ca.customer_id = c.customer_id
left join
    vk_data.resources.us_cities us on upper(trim(ca.customer_state)) = upper(trim(us.state_abbr))
        and trim(lower(ca.customer_city)) = trim(lower(us.city_name))
join
    food_preference_count s on c.customer_id = s.customer_id
cross join
    chicago_geo chic
cross join
    gary_geo gary
where
    -- Condition for customers in KY with specific cities in the name
    (
        (trim(lower(city_name)) ilike '%concord%'
            or trim(lower(city_name)) ilike '%georgetown%'
            or trim(lower(city_name)) ilike '%ashland%')
        and customer_state = 'KY'
    )
    or (
        -- Condition for customers in CA with specific cities in the name
        customer_state = 'CA'
        and (trim(lower(city_name)) ilike '%oakland%'
            or trim(lower(city_name)) ilike '%pleasant hill%')
    )
    or (
        -- Condition for customers in TX with specific cities in the name
        customer_state = 'TX'
        and (trim(lower(city_name)) ilike '%arlington%'
            or trim(lower(city_name)) ilike '%brownsville%')
    );