Capistrano::Configuration.instance.load do
  namespace :unicorn do
    desc "Setup Unicorn initializer and app configuration"
    task :setup, roles: :app do
      if exists? :unicorn_workers
        run "mkdir -p #{shared_path}/config"
        template "unicorn.rb.erb", "#{shared_path}/config/unicorn.rb"
        template "unicorn_init.erb", "/tmp/unicorn_init"
        run "chmod +x /tmp/unicorn_init"
        run "#{sudo} mv /tmp/unicorn_init /etc/init.d/unicorn_#{application}"
        run "#{sudo} update-rc.d -f unicorn_#{application} defaults 1>/dev/null"
      else
        puts "There's nothing to do."
      end
    end
    after "deploy:setup", "unicorn:setup"

    %w[start stop restart].each do |command|
      desc "#{command} unicorn"
      task command, roles: :app do
        if exists? :unicorn_workers
          run "service unicorn_#{application} #{command}"
        else
          puts "There's nothing to do."
        end
      end
      after "deploy:#{command}", "unicorn:#{command}"
    end
  end
end
