# Convenience Script for testing in IRB
#
# To run in local IRB and preload some namespaces run the following command from project root.
# bin/build_install.sh && irb -Ilib -rsetup.rb

require 'consul/client'
include Consul::Client
include Consul::Extensions
