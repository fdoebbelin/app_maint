Capistrano::Configuration.instance.load do
  namespace :base do
    task :info do
      run "hostname"
    end

    desc "Install everything onto the server"
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
    after "deploy:install", "base:install"
  end
end
