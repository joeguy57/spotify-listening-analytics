with events as (
 select * from {{ ref('fct_listening_events') }}
),
per_user as (
 select
 user_id,
 count(*) as total_plays,
 sum(case when is_skip then 1 else 0 end) as total_skips,
 sum(minutes_played) as total_minutes_played,
 count(distinct genre) as distinct_genres_played,
 count(distinct played_date) as active_days,
 count(distinct track_id) as distinct_tracks_played,
 min(played_date) as first_play_date,
 max(played_date) as last_play_date
 from events
 group by user_id
),
final as (
 select
 user_id,
 total_plays,
 total_skips,
 round(total_skips * 1.0 / nullif(total_plays, 0), 3) as skip_rate,
 round(1 - (total_skips * 1.0 / nullif(total_plays, 0)), 3) as 
completion_rate,
 total_minutes_played,
 round(total_minutes_played * 1.0 / nullif(active_days, 0), 2) as 
avg_minutes_per_active_day,
 distinct_genres_played,
 distinct_tracks_played,
 active_days,
 first_play_date,
 last_play_date,
 datediff(last_play_date, first_play_date) + 1 as tenure_days,
 -- simple engagement tier — a real product team metric, not just an academic exercise
 case
 when total_plays >= 200 and skip_rate <= 0.3 then 'highly_engaged'
 when total_plays >= 50 then 'moderately_engaged'
 else 'low_engagement'
 end as engagement_tier
 from per_user
)
select * from final