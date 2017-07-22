require 'capistrano/rails/assets'
namespace :load do
  task :defaults do
    set :precompile_env,   fetch(:rails_env) || 'production'
    set :assets_dir,       "public/assets"
    set :rsync_cmd,        "rsync -av --delete"

    after "bundler:install", "deploy:assets:prepare"
    after "deploy:assets:prepare", "deploy:assets:precompile"
    after "deploy:assets:prepare", "deploy:assets:cleanup"
  end
end

namespace :deploy do
  # Clear existing task so we can replace it rather than "add" to it.
  Rake::Task["deploy:compile_assets"].clear
  Rake::Task["deploy:assets:precompile"].clear

  namespace :assets do

    desc "Remove all local precompiled assets"
    task :cleanup do
      run_locally do
        with rails_env: fetch(:precompile_env) do
          execute "rm -rf", fetch(:assets_dir)
        end
      end
    end

    desc "Actually precompile the assets locally"
    task :prepare do
      run_locally do
        with rails_env: fetch(:precompile_env) do
          execute "rake assets:clean"
          execute "rake assets:precompile"
        end
      end
    end

    desc "Performs rsync to app servers"
    task :precompile do
      on roles(fetch(:assets_roles)) do
        run_locally do 
          execute "#{fetch(:rsync_cmd)} ./#{fetch(:assets_dir)}/ #{fetch(:user)}@#{fetch(:ipaddress)}:#{release_path}/#{fetch(:assets_dir)}/"
        end
      end
    end
  end
end
