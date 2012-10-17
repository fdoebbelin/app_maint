Capistrano::Configuration.instance.load do
  namespace :git do
    desc "Setup git configuration for this application"
    task :setup, roles: :web do
      run "mkdir -p /home/deployer/repos/#{application}.git"
      run "cd /home/deployer/repos/#{application}.git && git --bare init"
      run_locally "git remote add #{remote} ssh://#{user}@#{host_name}/home/deployer/repos/#{application}.git"
    end
    after "deploy:setup", "git:setup"
  end
end
