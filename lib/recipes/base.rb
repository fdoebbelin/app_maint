Capistrano::Configuration.instance.load do
  namespace :base do
    task :setup do
      init_deploy_user
      install
    end
    
    desc "Init environment for deployment user"
    task :init_deploy_user do
      set :deploy_user, "#{user}"
      set :user, "#{sudo_user}"
      unless capture( "cat /etc/passwd | grep #{deploy_user} | wc -l" ).to_i == 0
        run "#{sudo} deluser deployer"
        run "#{sudo} delgroup admin"
        run "#{sudo} rm -rf /home/deployer"
      end
      run "#{sudo} addgroup admin"
      run "#{sudo} useradd deployer -m -s /bin/bash -g admin"
      upload "#{Dir.home}/.ssh/id_rsa.pub", "/tmp/id_rsa.pub"
      run "#{sudo} mkdir -p /home/#{deploy_user}/.ssh"
      run "echo \"cat /tmp/id_rsa.pub >> /home/#{deploy_user}/.ssh/authorized_keys\" | sudo -s"
      run "rm /tmp/id_rsa.pub"
    end

    desc "Install minimum prerequisites for app_maint"
    task :install do
      if run "which ruby >/dev/null"
        run "#{sudo} apt-get -y update"
        run "#{sudo} apt-get -y install python-software-properties"
        run "#{sudo} apt-get -y install curl git-core"
        run "#{sudo} apt-get -y install build-essential zlib1g-dev libssl-dev libreadline6-dev libyaml-dev"
        run "wget ftp://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p194.tar.gz"
        run "tar -xvzf ruby-1.9.3-p194.tar.gz"
        run "cd ruby-1.9.3-p194/"
        run "./configure --prefix=/usr/local"
        run "make"
        run "#{sudo} make install"
        run "#{sudo} gem install bundler --no-ri --no-rdoc"
        run "#{sudo} gem install chef ruby-shadow --no-ri --no-rdoc"
      end
    end
    before "deploy:setup", "base:setup"
  end
end
