require 'jdbc-helper'
require_relative '../ht_secure_data.rb'
require "mysql-connector-java-5.1.17-bin.jar"

module HathiTrust
  class DBH
    extend HathiTrust::SecureData
    
    def self.new
      JDBCHelper::Connection.new(
                          :driver=>'com.mysql.jdbc.Driver',
                          :url=>'jdbc:mysql://' + self.db_machine + '/' + self.db_db,
                          :user => self.db_user,
                          :password => self.db_password
                        )
    end
  end
end
      
