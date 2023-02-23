module HathiTrust
  module SecureData
    def db_machine
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
  end
end

if File.exist?(File.join(__dir__, "ht_secure_data.rb"))
  require_relative "./ht_secure_data"
end
