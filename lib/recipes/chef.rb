require 'json'

Capistrano::Configuration.instance.load do
  namespace :chef do
    desc "Manages all system dependencies for this application"
    task :manages, roles: :web do
      run "mkdir -p /home/#{user}/apps/#{application}/shared"
      chef_cookbook_path = 
        capture( %q{ruby -e 'require "server_maint"; puts ServerMaint::get_cookbook_path'} ).chomp
      app_cookbook_path = "/home/#{user}/apps/#{application}/shared/cookbooks"
      chef_config = [
        %Q(cookbook_path ["#{chef_cookbook_path}", File.expand_path("../cookbooks", __FILE__)]),
        %Q(json_attribs File.expand_path("../node.json", __FILE__))
      ].join( "\n" )
      put(
        chef_config,
        "/home/#{user}/apps/#{application}/shared/solo.rb"
      )
      node_config = { "run_list" => ["recipe[main]"] }.to_json
      put node_config,  "/home/#{user}/apps/#{application}/shared/node.json"
      upload(
        "#{cookbooks}",
        "/home/#{user}/apps/#{application}/shared/cookbooks",
        {:recursive => true, :via => :scp}
      )
      run [
        "chef-solo",
        "-c /home/#{user}/apps/#{application}/shared/solo.rb",
        "-L /home/#{user}/apps/#{application}/shared/log/chef.log",
        "1>/dev/null"
      ].join( ' ' )
    end
    before "deploy:setup", "chef:manages"
  end
end

