require 'yaml'
require 'erb'
require 'active_record'
require 'fresh_connection'

case ENV['DB_ADAPTER']
when 'mysql2'
  puts "[mysql2]"
  system("mysql -uroot < test/config/mysql_schema.sql")
when 'postgresql'
  puts "postgresql"
  system("psql fresh_connection_test_master < test/config/psql_test_master.sql > /dev/null 2>&1")
  system("psql fresh_connection_test_replica1 < test/config/psql_test_replica1.sql > /dev/null 2>&1")
  system("psql fresh_connection_test_replica2 < test/config/psql_test_replica2.sql > /dev/null 2>&1")
end

module ActiveRecord
  class Base
    self.configurations = YAML.load(ERB.new(File.read(File.join(__dir__, "database_#{ENV['DB_ADAPTER']}.yml"))).result)
    establish_connection(configurations["test"])
    establish_fresh_connection :replica1
  end
end

class Parent < ActiveRecord::Base
  self.abstract_class = true
end

class Replica2 < ActiveRecord::Base
  self.abstract_class = true
  establish_fresh_connection :replica2
end

class User < ActiveRecord::Base
  has_one :address
  has_many :tels
end

class Address < ActiveRecord::Base
  belongs_to :user
end

class Tel < Replica2
  belongs_to :user
end

require "support/extend_minitest"
require "support/active_record_logger"
