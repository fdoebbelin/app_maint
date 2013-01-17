Capistrano::Configuration.instance.load do
  namespace :fix_permissions do
    desc "Fix wrong permissions for apps directory"
    task :setup, roles: :web do
      run "#{sudo} chown -R #{user}:admin /home/#{user}/apps"
    end

    after "deploy:setup", "fix_permissions:setup"
  end
end
