# Databricks notebook source
display(dbutils.fs.ls("/Volumes/spotify_analytics/bronze/raw_files"))

df_preview = spark.read.option("header", "true").option("inferSchema", "true") \
 .csv("/Volumes/spotify_analytics/bronze/raw_files/spotify_history.csv")
df_preview.printSchema()
display(df_preview.limit(10))
print(f"Row count: {df_preview.count():,}")

# COMMAND ----------

from pyspark.sql.types import StructType, StructField, StringType, LongType, TimestampType, BooleanType
listening_schema = StructType([
 StructField("ts", StringType(), True),
 StructField("platform", StringType(), True),
 StructField("ms_played", LongType(), True),
 StructField("track_name", StringType(), True),
 StructField("artist_name", StringType(), True),
 StructField("album_name", StringType(), True),
 StructField("track_id", StringType(), True),
 StructField("user_id", StringType(), True),
 StructField("reason_start", StringType(), True),
 StructField("reason_end", StringType(), True),
 StructField("shuffle", BooleanType(), True),
 StructField("skipped", BooleanType(), True),
])

df_events_raw = spark.read \
 .option("header", "true") \
 .schema(listening_schema) \
 .csv("/Volumes/spotify_analytics/bronze/raw_files/spotify_history.csv")
print(f"Rows: {df_events_raw.count():,}")
df_events_raw.printSchema()


# COMMAND ----------

from pyspark.sql import functions as F
# Only run this if your dataset has no user_id column
if "user_id" not in df_events_raw.columns:
 df_events_raw = df_events_raw.withColumn(
 "user_id",
 (F.abs(F.hash(F.col("ts"))) % 250).cast("string") # simulate 250 users
 )
 print("Synthetic user_id generated — document this in README as simulated multi-user data")


# COMMAND ----------

df_events_raw.write \
 .format("delta") \
 .mode("overwrite") \
 .option("overwriteSchema", "true") \
 .saveAsTable("spotify_analytics.bronze.listening_events")


# COMMAND ----------

spark.sql("SELECT COUNT(*) AS row_count FROM spotify_analytics.bronze.listening_events").show()
spark.sql("DESCRIBE TABLE spotify_analytics.bronze.listening_events").show(truncate=False)


# COMMAND ----------

df_tracks_preview = spark.read.option("header", "true").option("inferSchema","true").csv("/Volumes/spotify_analytics/bronze/raw_files/dataset.csv")
df_tracks_preview.printSchema()
display(df_tracks_preview.limit(10))
print(f"Row count: {df_tracks_preview.count():,}")

# COMMAND ----------

from pyspark.sql.types import DoubleType, IntegerType
tracks_schema = StructType([
 StructField("track_id", StringType(), True),
 StructField("track_name", StringType(), True),
 StructField("artists", StringType(), True),
 StructField("album_name", StringType(), True),
 StructField("popularity", IntegerType(), True),
 StructField("duration_ms", LongType(), True),
 StructField("explicit", BooleanType(), True),
 StructField("danceability", DoubleType(), True),
 StructField("energy", DoubleType(), True),
 StructField("tempo", DoubleType(), True),
 StructField("valence", DoubleType(), True),
 StructField("track_genre", StringType(), True),
])
df_tracks_raw = spark.read \
 .option("header", "true") \
 .schema(tracks_schema) \
 .csv("/Volumes/spotify_analytics/bronze/raw_files/dataset.csv")
df_tracks_raw.write \
 .format("delta") \
 .mode("overwrite") \
 .option("overwriteSchema", "true") \
 .saveAsTable("spotify_analytics.bronze.tracks")


# COMMAND ----------

# Listening events sanity checks
events_df = spark.table("spotify_analytics.bronze.listening_events")
print("=== LISTENING EVENTS ===")
print(f"Total rows: {events_df.count():,}")
print(f"Distinct users: {events_df.select('user_id').distinct().count():,}")
print(f"Distinct tracks: {events_df.select('track_id').distinct().count():,}")
print(f"Null track_id rows: {events_df.filter(F.col('track_id').isNull()).count():,}")
print(f"Null ts rows: {events_df.filter(F.col('ts').isNull()).count():,}")
print("\n=== TRACKS ===")
tracks_df = spark.table("spotify_analytics.bronze.tracks")
print(f"Total rows: {tracks_df.count():,}")
print(f"Distinct track_id: {tracks_df.select('track_id').distinct().count():,}")
print(f"Duplicate track_id count: {tracks_df.count() - tracks_df.select('track_id').distinct().count():,}")