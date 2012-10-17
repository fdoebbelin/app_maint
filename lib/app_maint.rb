require 'capistrano'
require 'capistrano/cli'

Dir.glob(File.join(File.dirname(__FILE__), '/recipes/*.rb')).sort.each { |recipe| load recipe }

def with_user(new_user, &block)
  old_user = user
  set :user, new_user
  close_sessions
  yield
  set :user, old_user
  close_sessions
end
 
def close_sessions
  sessions.values.each { |session| session.close }
  sessions.clear
end
