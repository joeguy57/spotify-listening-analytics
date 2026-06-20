with events as (
 select * from {{ ref('stg_listening_events') }}
),
tracks as (
 select * from {{ ref('stg_tracks') }}
),
final as (
 select
 e.event_id,
 e.user_id,
 e.track_id,
 e.played_at,
 e.played_date,
 e.platform,
 e.minutes_played,
 e.is_skip,
 e.shuffle,
 t.genre,
 t.artist_name,
 t.popularity,
 t.energy
 from events e
 left join tracks t on e.track_id = t.track_id
)
select * from final