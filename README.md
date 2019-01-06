1.Install Rails (On Your Linux as Well as Server) : https://gorails.com/setup/ubuntu/16.04

2.Include in your gemfile
  gem 'capistrano',         require: false
  gem 'capistrano-rvm',     require: false
  gem 'capistrano-rails',   require: false
  gem 'capistrano-bundler', require: false
  gem 'capistrano3-puma',   require: false
3.Bundle

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
	