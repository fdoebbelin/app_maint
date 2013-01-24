def template(from, to)
  erb = File.read(File.expand_path("../templates/#{from}", __FILE__))
  put ERB.new(erb).result(binding), to
end

Capistrano::Configuration.instance.load do
  namespace :base do
    desc "Prepare system for deployment"
    task :setup do
      init_deploy_user
      install_packages
      install_ruby
      pam_ssh_agent_auth
    end

    desc "Init environment for deployment user"
    task :init_deploy_user do
      set :deploy_user, "#{user}"
      with_user "#{sudo_user}" do
        if capture( "#{sudo} cat /etc/passwd | grep #{deploy_user} | wc -l" ).to_i == 0
          if capture( "cat /etc/group | grep '^admin:' | wc -l" ).to_i == 0
            run "#{sudo} addgroup admin"
          end
          run "#{sudo} useradd #{deploy_user} -m -s /bin/bash -g admin"
          upload "#{Dir.home}/.ssh/id_rsa.pub", "/tmp/id_rsa.pub"
          run "#{sudo} mkdir -p /home/#{deploy_user}/.ssh"
          run "echo \"cat /tmp/id_rsa.pub >> /home/#{deploy_user}/.ssh/authorized_keys\" | sudo -s"
          run "rm /tmp/id_rsa.pub"
          run "#{sudo} chown -R #{deploy_user}:admin /home/#{deploy_user}"
        end
      end
    end

    desc "Installs the necessary OS packages"
    task :install_packages do
      with_user "#{sudo_user}" do
        run "#{sudo} apt-get -y update 1>/dev/null"
        run "#{sudo} apt-get -y install python-software-properties 1>/dev/null"
        run "#{sudo} apt-get -y install curl git-core 1>/dev/null"
        run "#{sudo} apt-get -y install build-essential zlib1g-dev libssl-dev libreadline6-dev libyaml-dev 1>/dev/null"
        run "#{sudo} apt-get -y install libpam0g-dev checkinstall 1>/dev/null"
      end
    end

    desc "Installs up-to-date ruby version from sources"
    task :install_ruby do
      version = (defined? :ruby_version) ? ruby_version : '1.9.3'
      patch = (defined? :ruby_patch) ? ruby_patch : 'p362'
      with_user "#{sudo_user}" do
        if capture( "LANGUAGE=e dpkg --list ruby-#{version}#{patch} 2>&1 | grep 'No packages found' | wc -l" ).to_i == 1
          run [
            "wget ftp://ftp.ruby-lang.org/pub/ruby/1.9/ruby-#{version}-#{patch}.tar.gz --quiet",
            "tar -xzf ruby-#{version}-#{patch}.tar.gz",
            "cd ruby-#{version}-#{patch}/",
            "./configure --prefix=/usr/local 1>/dev/null",
            "make 1>/dev/null 2>&1"
          ].join( '&&' )
          run [
            "cd ruby-#{version}-#{patch}/",
            "#{sudo} checkinstall --default --pkgname=ruby-#{version}#{patch} --pkgversion=#{version}#{patch} --nodoc 1>/dev/null 2>&1"
          ].join( '&&' )
          run "#{sudo} gem install bundler --no-ri --no-rdoc"
          run "#{sudo} gem install chef ruby-shadow right_aws --no-ri --no-rdoc"
          run "#{sudo} gem install server_maint --no-ri --no-rdoc"
        end
      end
    end

    desc "Make shared keys and sudo work together"
    task :pam_ssh_agent_auth do
      version = (defined? :pam_ssh_agent_auth_version) ? pam_ssh_agent_auth : '0.9.4'
      with_user "#{sudo_user}" do
        if capture( "LANGUAGE=e dpkg --list pam-ssh-agent-auth-#{version} 2>&1 | grep 'No packages found' | wc -l" ).to_i == 1
          run [
            "wget http://downloads.sourceforge.net/project/pamsshagentauth/pam_ssh_agent_auth/v#{version}/pam_ssh_agent_auth-#{version}.tar.bz2 --quiet",
            "tar -xjf pam_ssh_agent_auth-#{version}.tar.bz2",
            "cd pam_ssh_agent_auth-#{version}",
            "./configure --libexecdir=/lib/security --with-mantype=man 1>/dev/null",
            "make 1>/dev/null 2>&1"
          ].join( '&&' )
          run [
            "cd pam_ssh_agent_auth-#{version}",
            "#{sudo} checkinstall --default --pkgname=pam_ssh_agent_auth-#{version} --nodoc 1>/dev/null 2>&1"
          ].join( '&&' )
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
    end

    before "deploy:setup", "base:setup"
  end
end

