with source as (
 select * from {{ source('bronze', 'tracks') }}
),
deduplicated as (
 select *,
 row_number() over (
 partition by track_id
 order by popularity desc
 ) as row_num
 from source
 where track_id is not null
),
cleaned as (
 select
 track_id,
 trim(track_name) as track_name,
 trim(artists) as artist_name,
 trim(album_name) as album_name,
 coalesce(popularity, 0) as popularity,
 duration_ms,
 round(duration_ms / 60000.0, 2) as duration_minutes,
 explicit,
 danceability,
 energy,
 tempo,
 valence,
 lower(trim(track_genre)) as genre
 from deduplicated
 where row_num = 1 -- keep only the highest-popularity version of each duplicate track
)
select * from cleaned