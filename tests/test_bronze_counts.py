"""
Basic sanity tests for Bronze layer row counts.
Run manually after each Bronze ingestion to catch silent data loss.
These are NOT dbt tests — dbt tests come in Phase 2 once data is in dbt's 
control.
"""
import pytest
# Update these after running Step 6 above — these are your expected baselines
EXPECTED_MIN_EVENTS_ROWS = 1000
EXPECTED_MIN_TRACKS_ROWS = 1000
def test_events_row_count_above_threshold(events_row_count):
 assert events_row_count >= EXPECTED_MIN_EVENTS_ROWS, (
 f"Listening events row count ({events_row_count}) is below expected "
 f"minimum ({EXPECTED_MIN_EVENTS_ROWS}). Possible data loss during ingestion."
 )
def test_tracks_row_count_above_threshold(tracks_row_count):
 assert tracks_row_count >= EXPECTED_MIN_TRACKS_ROWS, (
 f"Tracks row count ({tracks_row_count}) is below expected "
 f"minimum ({EXPECTED_MIN_TRACKS_ROWS}). Possible data loss during ingestion."
 )