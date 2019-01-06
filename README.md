1.Install Rails (On Your Linux as Well as Server) : https://gorails.com/setup/ubuntu/16.04

2.Include in your gemfile
	
	gem 'capistrano',         require: false
	gem 'capistrano-rvm',     require: false
	gem 'capistrano-rails',   require: false
	gem 'capistrano-bundler', require: false
	gem 'capistrano3-puma',   require: false

3.bundle

4.Capfile:

	require 'capistrano/setup'
	require 'capistrano/deploy'
	require "capistrano/scm/git"
	install_plugin Capistrano::SCM::Git
	require 'capistrano/rails'
	require 'capistrano/bundler'
	require 'capistrano/rvm'
	require 'capistrano/puma'
	install_plugin Capistrano::Puma
	Dir.glob("lib/capistrano/tasks/*.rake").each { |r| import r }

5.config/deploy/production.rb.rb

	server ENV['SERVER_IP'], user: 'root', roles: %w{app db web}

	set :repo_url,        ENV['REPO_URL']
	set :application,     'Nginx-Example'
	set :puma_threads,    [4, 16]
	set :puma_workers,    4

	# Don't change these unless you know what you're doing
	set :pty,             true
	set :use_sudo,        false
	set :stage,           :production
	set :deploy_via,      :remote_cache
	set :deploy_to,       "/home/example-app/#{fetch(:application)}"
	set :puma_bind,       "unix://#{shared_path}/tmp/sockets/#{fetch(:application)}-puma.sock"
	set :puma_state,      "#{shared_path}/tmp/pids/puma.state"
	set :puma_pid,        "#{shared_path}/tmp/pids/puma.pid"
	set :puma_access_log, "#{release_path}/log/puma.error.log"
	set :puma_error_log,  "#{release_path}/log/puma.access.log"
	set :puma_preload_app, true
	set :puma_worker_timeout, nil
	set :puma_init_active_record, false  # Change to true if using ActiveRecord

	## Defaults:
	# set :scm,           :git
	# set :branch,        :master
	# set :format,        :pretty
	# set :log_level,     :debug
	# set :keep_releases, 5

	## Linked Files & Directories (Default None):
	set :linked_files, %w{config/database.yml config/secrets.yml}
	set :linked_dirs,  %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

	namespace :puma do
	  desc 'Create Directories for Puma Pids and Socket'
	  task :make_dirs do
	    on roles(:app) do
	      execute "mkdir #{shared_path}/tmp/sockets -p"
	      execute "mkdir #{shared_path}/tmp/pids -p"
	    end
	  end

	  before :start, :make_dirs
	end

	namespace :deploy do
	  desc "Make sure local git is in sync with remote."
	  task :check_revision do
	    on roles(:app) do
	      unless `git rev-parse HEAD` == `git rev-parse origin/master`
	        puts "WARNING: HEAD is not the same as origin/master"
	        puts "Run `git push` to sync changes."
	        exit
	      end
	    end
	  end

	  desc 'Kill existing puma process'
	  task :kill_puma_process do
	  	on roles(:app) do
	  		execute 'sudo pkill -9 puma'
	  	end
	  end
	  desc 'Initial Deploy'
	  task :initial do
	    on roles(:app) do
	      before 'deploy:restart', 'puma:start'
	      invoke 'deploy'
	    end
	  end

	  desc 'Restart application'
	  task :restart do
	    on roles(:app), in: :sequence, wait: 5 do
	      invoke 'puma:restart'
	    end
	  end

	  before :starting,     :kill_puma_process
	  after  :finishing,    :compile_assets
	  after  :finishing,    :cleanup
	  after  :finishing,    :restart
	end

6.shared/puma.rb (on server)

	#!/usr/bin/env puma

	directory '/home/example-app/Nginx-Example/current'
	rackup "/home/example-app/Nginx-Example/current/config.ru"
	environment 'production'

	tag ''

	pidfile "/home/example-app/Nginx-Example/shared/tmp/pids/puma.pid"
	state_path "/home/example-app/Nginx-Example/shared/tmp/pids/puma.state"
	stdout_redirect '/home/example-app/Nginx-Example/current/log/puma.error.log', '/home/example-app/Nginx-Example/current/log/puma.access.log', true


	threads 4,16



	bind 'unix:///home/example-app/Nginx-Example/shared/tmp/sockets/puma.sock'

	workers 4





	preload_app!


	on_restart do
	  puts 'Refreshing Gemfile'
	  ENV["BUNDLE_GEMFILE"] = ""
	end

7./etc/nginx/sites-enabled/default(on server)

	upstream puma {
  	server unix:///home/example-app/Nginx-Example/shared/tmp/sockets/puma.sock;
	}

	server {
	  listen 80 default_server deferred;
	  # server_name example.com;

	  root /home/example-app/Nginx-Example/current/public;
	  #access_log /home/example-app/Nginx-Example/current/log/nginx.access.log;
	  #error_log //home/example-app/Nginx-Example/current/log/nginx.error.log info;

	  location ^~ /assets/ {
	    gzip_static on;
	    expires max;
	    add_header Cache-Control public;
	  }

	  try_files $uri/index.html $uri @puma;
	  location @puma {
	    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
	    proxy_set_header Host $http_host;
	    proxy_redirect off;

	    proxy_pass http://puma;
	  }

	  error_page 500 502 503 504 /500.html;
	  client_max_body_size 10M;
	  keepalive_timeout 10;
	}