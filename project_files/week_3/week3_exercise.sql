-- query all needed data and extract values from json
with data_prep as (
    -- Extract relevant data from the website_activity table
    select
        date(event_timestamp) as event_date,
        session_id,
        event_timestamp,
        trim(parse_json(event_details):"event", '"') as event_type,
        trim(parse_json(event_details):"recipe_id", '"') as recipe_id
    from
        website_activity
),

session_level_statistics as (
    -- Calculate session-level statistics
    select
        event_date,
        session_id,
        datediff(
            'sec',
            min(event_timestamp),
            max(event_timestamp)
        ) as session_duration,
        -- when the count of view_recipe events is > 0
        -- then count searches / count view_recipe events
        -- else if there were no recipe events, return null
        CASE
            WHEN COUNT_IF(event_type = 'view_recipe') > 0 
            THEN COUNT_IF(event_type = 'search') / COUNT_IF(event_type = 'view_recipe')::FLOAT
            ELSE NULL
        END AS search_to_view_recipe_ratio
    from
        data_prep
    group by all
),

recipe_rank as (
    -- Rank recipes based on the number of views
    select
        event_date,
        recipe_id,
        count(recipe_id) as number_of_views
    from
        data_prep
    where
        recipe_id is not null
    group by all
    qualify row_number() over (
        partition by event_date
        order by number_of_views desc
            ) = 1
    order by
        event_date
),

result as (
    -- Combine session-level statistics and recipe rankings
    select
        a.event_date,
        count(session_id) as total_unique_sessions,
        round(avg(session_duration)) as avg_session_duration_sec,
        avg(search_to_view_recipe_ratio) as search_to_view_recipe_ratio,
        recipe_id as most_viewed_recipe
    from
        session_level_statistics a
        inner join recipe_rank b on a.event_date = b.event_date
    group by
        all
    order by
        event_date
)

select
    *
from
    result;