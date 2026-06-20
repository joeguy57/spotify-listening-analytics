with stg as (
 select * from {{ ref('stg_tracks') }}
),
final as (
 select
 track_id,
 track_name,
 artist_name,
 album_name,
 genre,
 popularity,
 duration_minutes,
 danceability,
 energy,
 tempo,
 valence,
 -- bucket popularity for easier grouping in dashboards
 case
 when popularity >= 70 then 'high'
 when popularity >= 40 then 'medium'
 else 'low'
 end as popularity_tier,
 -- bucket mood using valence (Spotify's "musical positiveness" score)
 case
 when valence >= 0.6 then 'upbeat'
 when valence >= 0.3 then 'neutral'
 else 'somber'
 end as mood_tier
 from stg
)
select * from final