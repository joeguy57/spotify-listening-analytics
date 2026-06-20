with events as (
 select * from {{ ref('fct_listening_events') }}
),
-- split each user's history into two halves to compare recent vs. earlier behavior
user_date_bounds as (
 select
 user_id,
 min(played_date) as first_date,
 max(played_date) as last_date
 from events
 group by user_id
),
midpoint as (
 select
 user_id,
 first_date,
 last_date,
 date_add(first_date, CAST(datediff(last_date, first_date) / 2 AS INT)) as 
midpoint_date
 from user_date_bounds
),
first_half as (
 select
 e.user_id,
 count(*) as plays_first_half,
 sum(case when e.is_skip then 1 else 0 end) as skips_first_half
 from events e
 join midpoint m on e.user_id = m.user_id
 where e.played_date <= m.midpoint_date
 group by e.user_id
),
second_half as (
 select
 e.user_id,
 count(*) as plays_second_half,
 sum(case when e.is_skip then 1 else 0 end) as skips_second_half
 from events e
 join midpoint m on e.user_id = m.user_id
 where e.played_date > m.midpoint_date
 group by e.user_id
),
combined as (
 select
 m.user_id,
 coalesce(f.plays_first_half, 0) as plays_first_half,
 coalesce(s.plays_second_half, 0) as plays_second_half,
 round(coalesce(f.skips_first_half, 0) * 1.0 / nullif(f.plays_first_half,
0), 3) as skip_rate_first_half,
 round(coalesce(s.skips_second_half, 0) * 1.0 / 
nullif(s.plays_second_half, 0), 3) as skip_rate_second_half
 from midpoint m
 left join first_half f on m.user_id = f.user_id
 left join second_half s on m.user_id = s.user_id
),
final as (
 select
 user_id,
 plays_first_half,
 plays_second_half,
 skip_rate_first_half,
 skip_rate_second_half,
 round(
 (plays_second_half - plays_first_half) * 1.0 / 
nullif(plays_first_half, 0), 3
 ) as play_volume_change_pct,
 round(
 skip_rate_second_half - skip_rate_first_half, 3
 ) as skip_rate_change,
 -- churn risk heuristic: listening dropped AND skip rate rose
 case
 when plays_second_half < plays_first_half * 0.5
 and skip_rate_second_half > skip_rate_first_half
 then 'high_risk'
 when plays_second_half < plays_first_half * 0.8
 then 'moderate_risk'
 else 'stable'
 end as churn_risk_tier
 from combined
)
select * from final