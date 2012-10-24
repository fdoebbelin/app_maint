Capistrano::Configuration.instance.load do
  namespace :base do
    desc "Prepare system for deployment"
    task :setup do
      init_deploy_user
      install
      pam_ssh_agent_auth
    end
    
    desc "Init environment for deployment user"
    task :init_deploy_user do
      set :deploy_user, "#{user}"
      with_user "#{sudo_user}" do
        if capture( "#{sudo} cat /etc/passwd | grep #{deploy_user} | wc -l" ).to_i == 0
          run "#{sudo} addgroup admin"
          run "#{sudo} useradd deployer -m -s /bin/bash -g admin"
          upload "#{Dir.home}/.ssh/id_rsa.pub", "/tmp/id_rsa.pub"
          run "#{sudo} mkdir -p /home/#{deploy_user}/.ssh"
          run "echo \"cat /tmp/id_rsa.pub >> /home/#{deploy_user}/.ssh/authorized_keys\" | sudo -s"
          run "rm /tmp/id_rsa.pub"
        end
      end
    end

    desc "Install minimum prerequisites for app_maint"
    task :install do
      with_user "#{sudo_user}" do
        if capture( "which ruby  | wc -l" ).to_i == 0
          run "#{sudo} apt-get -y update"
          run "#{sudo} apt-get -y install python-software-properties"
          run "#{sudo} apt-get -y install curl git-core"
          run "#{sudo} apt-get -y install build-essential zlib1g-dev libssl-dev libreadline6-dev libyaml-dev"
          run "wget ftp://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p194.tar.gz"
          run "tar -xvzf ruby-1.9.3-p194.tar.gz"
          run "cd ruby-1.9.3-p194/ && ./configure --prefix=/usr/local && make && #{sudo} make install"
          run "#{sudo} gem install bundler --no-ri --no-rdoc"
          run "#{sudo} gem install chef ruby-shadow --no-ri --no-rdoc"
          run "#{sudo} gem install server_maint --no-ri --no-rdoc"
        end
      end
    end
    desc "Make shared keys and sudo work together"
    task :pam_ssh_agent_auth do
      with_user "#{sudo_user}" do
        run "#{sudo} apt-get -y install libpam0g-dev checkinstall"
        run "wget http://downloads.sourceforge.net/project/pamsshagentauth/pam_ssh_agent_auth/v0.9.4/pam_ssh_agent_auth-0.9.4.tar.bz2"
        run "tar -xjf pam_ssh_agent_auth-0.9.4.tar.bz2"
        run "cd pam_ssh_agent_auth-0.9.4 && ./configure --libexecdir=/lib/security --with-mantype=man && make && #{sudo} checkinstall --default"
        pam_config = [
          '#%PAM-1.0',
          'auth sufficient pam_ssh_agent_auth.so file=%h/.ssh/authorized_keys',
          '@include common-account',
          'session required pam_permit.so',
          'session required pam_limits.so'
        ].join( "\n" )
        put(
          pam_config,
          "/tmp/pam_config"
        )
        run "#{sudo} mv /tmp/pam_config /etc/pam.d/sudo"
      end
    end
    before "deploy:setup", "base:setup"
  end
end

