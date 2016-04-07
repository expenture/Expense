json.errors synchronizer.errors if synchronizer.errors.present?

# IDs
json.user_id synchronizer.user_id
json.uid synchronizer.uid

# Type information
json.type synchronizer.type
json.email_endpoint synchronizer.email_endpoint if synchronizer.email_endpoint

# Basic information
json.name synchronizer.name

# Performing schedule
json.enabled synchronizer.enabled
json.schedule synchronizer.schedule

# Performing status
json.status synchronizer.status
if time_format == 'integer'
  json.last_scheduled_at (synchronizer.last_scheduled_at && synchronizer.last_scheduled_at.to_i * 1000)
  json.last_collected_at (synchronizer.last_collected_at && synchronizer.last_collected_at.to_i * 1000)
  json.last_parsed_at (synchronizer.last_parsed_at && synchronizer.last_parsed_at.to_i * 1000)
  json.last_synced_at (synchronizer.last_synced_at && synchronizer.last_synced_at.to_i * 1000)
  json.last_errored_at (synchronizer.last_errored_at && synchronizer.last_errored_at.to_i * 1000)
else
  json.last_scheduled_at synchronizer.last_scheduled_at
  json.last_collected_at synchronizer.last_collected_at
  json.last_parsed_at synchronizer.last_parsed_at
  json.last_synced_at synchronizer.last_synced_at
  json.last_errored_at synchronizer.last_errored_at
end

# Timestamps
if time_format == 'integer'
  json.created_at synchronizer.created_at_as_i
  json.updated_at synchronizer.updated_at_as_i
else
  json.created_at synchronizer.created_at
  json.updated_at synchronizer.updated_at
end
