json.user_id synchronizer.user_id
json.account_uid synchronizer.account_uid
json.uid synchronizer.uid
json.type synchronizer.type
json.enabled synchronizer.enabled
json.schedule synchronizer.schedule
json.name synchronizer.name
json.status synchronizer.status

if time_format == 'integer'
  json.last_collected_at (synchronizer.last_collected_at && synchronizer.last_collected_at.to_i * 1000)
  json.last_parsed_at (synchronizer.last_parsed_at && synchronizer.last_parsed_at.to_i * 1000)
  json.last_synced_at (synchronizer.last_synced_at && synchronizer.last_synced_at.to_i * 1000)
  json.last_errored_at (synchronizer.last_errored_at && synchronizer.last_errored_at.to_i * 1000)
  json.created_at synchronizer.created_at_as_i
  json.updated_at synchronizer.updated_at_as_i
else
  json.last_collected_at synchronizer.last_collected_at
  json.last_parsed_at synchronizer.last_parsed_at
  json.last_synced_at synchronizer.last_synced_at
  json.last_errored_at synchronizer.last_errored_at
  json.created_at synchronizer.created_at
  json.updated_at synchronizer.updated_at
end

json.errors synchronizer.errors if synchronizer.errors.present?
