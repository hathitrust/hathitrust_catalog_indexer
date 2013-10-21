require 'jdbc-helper'
require 'ht_secure_data'
require "mysql-connector-java-5.1.17-bin.jar"

module HathiTrust
  class DBH
    extend HathiTrust::SecureData
    
    def initialize
      JDBCHelper::Connection.new(
                          :driver=>'com.mysql.jdbc.Driver',
                          :url=>'jdbc:mysql://' + self.db_machine + '/' + self.db_db,
                          :user => self.db_user,
                          :password => self.db_password
                        )
    end
  end
end
      
