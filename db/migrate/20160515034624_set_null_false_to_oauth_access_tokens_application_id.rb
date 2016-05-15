class SetNullFalseToOAuthAccessTokensApplicationId < ActiveRecord::Migration[5.0]
  def change
    change_column_null(:oauth_access_tokens, :application_id, false, 0)
  end
end
