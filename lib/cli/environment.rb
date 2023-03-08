# frozen_string_literal: true

module HathiTrust
  module CLI
    module Environment
      JRUBY_BIN_PATH = "/htsolr/catalog/bin/jruby/bin"
      
      def setup
        ENV["JRUBY_OPTS"] = "--server -J-Xmx2048m -Xcompile.invokedynamic=true"
        # Avoid spamming PATH with repeated calls
        unless ENV["PATH"].split(":").any? JRUBY_BIN_PATH
          ENV["PATH"] = ENV["PATH"].split(":").unshift(JRUBY_BIN_PATH).join(":")
        end
        ENV.delete "JAVA_HOME"
      end
    end
  end
end
