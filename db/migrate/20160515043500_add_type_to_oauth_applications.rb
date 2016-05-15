class AddTypeToOAuthApplications < ActiveRecord::Migration[5.0]
  def change
    add_column :oauth_applications, :type, :string
    add_column :oauth_applications, :contact_code, :string
  end
end
