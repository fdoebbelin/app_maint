require 'capistrano'
require 'capistrano/cli'

Dir.glob(File.join(File.dirname(__FILE__), '/recipes/*.rb')).sort.each { |recipe| load recipe }
