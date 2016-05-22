json.errors account.errors if account.errors.present?

# Type: normal or syncing
json.type account.type || 'normal'

# IDs
json.user_id account.user_id
json.uid account.uid

# Basic information
json.kind account.kind
json.name account.name
json.currency account.currency
json.balance account.balance
json.default account.default?

# Syncing account information
json.syncing account.syncing?
json.synchronizer_uid account.synchronizer_uid

# Timestamps
if time_format == 'integer'
  json.created_at account.created_at_as_i
  json.updated_at account.updated_at_as_i
  json.deleted_at account.deleted_at_as_i if account.deleted_at
else
  json.created_at account.created_at
  json.updated_at account.updated_at
  json.deleted_at account.deleted_at if account.deleted_at
end
