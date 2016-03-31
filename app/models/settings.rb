# == Schema Information
#
# Table name: settings
#
# *id*::         <tt>integer, not null, primary key</tt>
# *var*::        <tt>string, not null</tt>
# *value*::      <tt>text</tt>
# *thing_id*::   <tt>integer</tt>
# *thing_type*:: <tt>string(30)</tt>
# *created_at*:: <tt>datetime</tt>
# *updated_at*:: <tt>datetime</tt>
#
# Indexes
#
#  index_settings_on_thing_type_and_thing_id_and_var  (thing_type,thing_id,var) UNIQUE
#--
# == Schema Information End
#++

# RailsSettings Model
class Settings < RailsSettings::CachedSettings
end
