require 'tmpdir'
require 'simplecov'

SimpleCov.formatters = [SimpleCov::Formatter::HTMLFormatter]

SimpleCov.start do
  add_filter '/spec/'
#  minimum_coverage(99.61)
end

require 'consul/client'


