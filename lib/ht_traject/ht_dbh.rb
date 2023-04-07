# frozen_string_literal: true

require "sequel"

module HathiTrust
  module DBH
    module_function

    def connect
      @db ||= Sequel.connect(connection_string, login_timeout: 2, pool_timeout: 10, max_connections: 6)
    end

    def db_host
      ENV["MYSQL_HOST"]
    end

    def db_db
      ENV["MYSQL_DATABASE"]
    end

    def db_user
      ENV["MYSQL_USER"]
    end

    def db_password
      ENV["MYSQL_PASSWORD"]
    end

    def connection_string
      "jdbc:mysql://#{db_host}/#{db_db}?user=#{db_user}&password=#{db_password}&useTimezone=true&serverTimezone=UTC"
    end
  end
end
