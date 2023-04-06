require_relative '../ht_db_config'
require 'sequel'


module HathiTrust
  module DBH
    extend HathiTrust::SecureData
    DB = Sequel.connect("jdbc:mysql://#{db_machine}/#{db_db}?user=#{db_user}&password=#{db_password}&useTimezone=true&serverTimezone=UTC", login_timeout: 2, pool_timeout: 10, max_connections: 6)
  end
end
