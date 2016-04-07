json.errors account_identifier.errors if account_identifier.errors.present?

# IDs
json.user_id account_identifier.user_id
json.id account_identifier.id

# Basic information
json.identified account_identifier.identified?
json.type account_identifier.type
json.identifier account_identifier.identifier
json.account_uid account_identifier.account_uid

# Sample data
json.sample_transaction_party_name account_identifier.sample_transaction_party_name
json.sample_transaction_description account_identifier.sample_transaction_description
json.sample_transaction_amount account_identifier.sample_transaction_amount
json.sample_transaction_datetime account_identifier.sample_transaction_datetime

# Timestamps
if time_format == 'integer'
  json.created_at account_identifier.created_at_as_i
  json.updated_at account_identifier.updated_at_as_i
else
  json.created_at account_identifier.created_at
  json.updated_at account_identifier.updated_at
end
