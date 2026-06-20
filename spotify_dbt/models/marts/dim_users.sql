with events as (
 select * from {{ ref('stg_listening_events') }}
),
user_first_last as (
 select
 user_id,
 min(played_date) as first_listen_date,
 max(played_date) as last_listen_date,
 count(distinct played_date) as active_days,
 count(*) as lifetime_play_count
 from events
 group by user_id
),
final as (
 select
 user_id,
 first_listen_date,
 last_listen_date,
 active_days,
 lifetime_play_count,
 datediff(last_listen_date, first_listen_date) + 1 as tenure_days
 from user_first_last
)
select * from final