# == Schema Information
#
# Table name: oauth_applications
#
# *id*::           <tt>integer, not null, primary key</tt>
# *name*::         <tt>string, not null</tt>
# *uid*::          <tt>string, not null</tt>
# *secret*::       <tt>string, not null</tt>
# *redirect_uri*:: <tt>text, not null</tt>
# *scopes*::       <tt>string, default(""), not null</tt>
# *created_at*::   <tt>datetime</tt>
# *updated_at*::   <tt>datetime</tt>
# *owner_id*::     <tt>integer</tt>
# *owner_type*::   <tt>string</tt>
#
# Indexes
#
#  index_oauth_applications_on_owner_id_and_owner_type  (owner_id,owner_type)
#  index_oauth_applications_on_uid                      (uid) UNIQUE
#--
# == Schema Information End
#++

class OAuthApplication < Doorkeeper::Application
  belongs_to :user, foreign_key: :owner_id, optional: true
  has_many :oauth_access_grant, foreign_key: :application_id
  has_many :oauth_access_token, foreign_key: :application_id
end
