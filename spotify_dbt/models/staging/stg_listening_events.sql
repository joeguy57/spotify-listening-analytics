with source as (
 select * from {{ source('bronze', 'listening_events') }}
),
cleaned as (
 select
 -- generate a surrogate key since raw data has no natural unique event id
 {{ dbt_utils.generate_surrogate_key(['user_id', 'track_id', 'ts']) }} as
event_id,
 user_id,
 track_id,
 cast(ts as timestamp) as played_at,
 date(cast(ts as timestamp)) as played_date,
 platform,
 ms_played,
 round(ms_played / 60000.0, 2) as minutes_played,
 -- normalize skip logic: different export formats encode this differently
 case
    when reason_end = 'fwdbtn' then true
    when reason_end = 'backbtn' then true
    when skipped = true then true
    when ms_played < 30000 then true -- fallback heuristic: <30s played counts as a skip
 else false
 end as is_skip,
 reason_start,
 reason_end,
 shuffle
 from source
 where track_id is not null
 and ts is not null
 and ms_played >= 0 -- defensive: negative play durations are invalid
)
select * from cleaned