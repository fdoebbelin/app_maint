Capistrano::Configuration.instance.load do
  namespace :chef do
    desc "Manages all system dependencies for this application"
    task :manages, roles: :web do
      cookbooks = 'ruby -v'
      puts cookbooks
    end
    before "deploy:setup", "chef:manages"
  end
end

