# frozen_string_literal: true

Dir[File.join(__dir__, "cictl", "*.rb")].sort.each { |file| require file }
require_relative "services"
