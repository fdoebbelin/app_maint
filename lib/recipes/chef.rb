require 'json'

Capistrano::Configuration.instance.load do
  namespace :chef do
    desc "Manages all system dependencies for this application"
    task :manages, roles: :web do
      run "mkdir -p /home/#{user}/chef/#{application}/log"
      chef_cookbook_path =
        capture( %q{ruby -e 'require "server_maint"; puts ServerMaint::get_cookbook_path'} ).chomp
      app_cookbook_path = "/home/#{user}/chef/#{application}/cookbooks"
      chef_config = [
        %Q(cookbook_path ["#{chef_cookbook_path}", File.expand_path("../cookbooks", __FILE__)]),
        %Q(json_attribs File.expand_path("../node.json", __FILE__))
      ].join( "\n" )
      put(
        chef_config,
        "/home/#{user}/chef/#{application}/solo.rb"
      )
      node_config = {
        "user" => "#{user}",
        "application" => "#{application}",
        "server_name" => "#{host_name}",
        "run_list" => ["recipe[main]"]
      }
      node_config.update( app_node_config ) if defined? app_node_config
      node_config.update( stage_node_config ) if defined? stage_node_config
      put node_config.to_json,  "/home/#{user}/chef/#{application}/node.json"
      upload(
        "#{cookbooks}",
        "/home/#{user}/chef/#{application}",
        {:recursive => true, :via => :scp}
      )
      run [
        "#{sudo} chef-solo",
        "-c /home/#{user}/chef/#{application}/solo.rb",
        "-L /home/#{user}/chef/#{application}/log/chef.log",
        "1>/dev/null"
      ].join( ' ' )
    end
    before "deploy:setup", "chef:manages"
  end
end

