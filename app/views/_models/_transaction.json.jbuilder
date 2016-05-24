json.errors transaction.errors if transaction.errors.present?

# Type: normal, synced, virtual or not_on_record
json.type transaction.type || 'normal'

# IDs
json.account_uid transaction.account_uid
json.uid transaction.uid

# Ignored in statistics?
json.ignore_in_statistics transaction.ignore_in_statistics

# Basic information
json.datetime transaction.datetime
json.amount transaction.amount
json.description transaction.description
json.category_code transaction.category_code
json.tags transaction.tags
json.note transaction.note

# Geographical location
json.latitude transaction.latitude
json.longitude transaction.longitude

# Party related information
json.image_url transaction.image_url
json.party_type transaction.party_type
json.party_code transaction.party_code
json.party_name transaction.party_name

# Virtual or virtual-related transaction information
json.separated transaction.separated?
json.virtual transaction.virtual?
if transaction.virtual?
  json.separate_transaction_uid transaction.separate_transaction_uid
end

# Not-on-record transaction information
unless transaction.virtual? # virtual transactions will not be considered to be
                            # on-record or not, so skip this block
  json.on_record transaction.on_record
  unless transaction.on_record
    json.not_on_record_copy transaction.not_on_record_copy?
  end
end

# Synced transaction information
json.synced transaction.synced?

# Other marks
json.manually_edited transaction.manually_edited?

# Timestamps
if time_format == 'integer'
  json.created_at transaction.created_at_as_i
  json.updated_at transaction.updated_at_as_i
  json.deleted_at transaction.deleted_at_as_i if transaction.deleted_at
else
  json.created_at transaction.created_at
  json.updated_at transaction.updated_at
  json.deleted_at transaction.deleted_at if transaction.deleted_at
end
