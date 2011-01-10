remove_file "README"
remove_file "public/index.html"
remove_file "public/favicon.ico"
remove_file "public/robots.txt"
remove_file "public/images/rails.png"

file 'README.markdown', ''

empty_directory_with_gitkeep 'public/images'
empty_directory_with_gitkeep 'app/javascript'

remove_file 'Gemfile'
file 'Gemfile', <<-RUBY.gsub(/^ {2}/, '')
  source 'http://rubygems.org'

  gem 'bundler', '~> 1.0'

  gem 'rails', :git => 'https://github.com/rails/rails.git', :branch => '3-0-stable'
  gem 'arel', :git => 'https://github.com/rails/arel.git', :branch => '2-0-stable'
  gem 'meta_where', :git => 'https://github.com/ernie/meta_where.git', :branch => 'arel-2.0'

  gem 'awesome_print', :require => 'ap'
  gem 'default_value_for'
  gem 'escape_utils'
  gem 'jammit', :git => 'https://github.com/documentcloud/jammit.git'
  gem 'nokogiri'
  gem 'pg'
  gem 'rack-sprockets', :require => 'rack/sprockets'
  gem 'rails3-generators'
  gem 'responders'
  gem 'show_for', :git => 'https://github.com/plataformatec/show_for.git'
  gem 'simple_form', :git => 'https://github.com/plataformatec/simple_form.git'
  gem 'uuid'
  gem 'workflow'

  # See http://blog.davidchelimsky.net/2010/07/11/rspec-rails-2-generators-and-rake-tasks/
  group :development, :test do
    gem 'capistrano', :require => false
    gem 'database_cleaner'
    gem 'factory_girl_rails'
    gem 'launchy'
    gem 'livereload', :require => false
    gem 'ruby-debug19', :require => false
    gem 'rspec-rails'
    gem 'shoulda'
  end
RUBY

gsub_file 'config/application.rb', /:password/, ':password, :password_confirmation'
gsub_file 'config/application.rb', /# config.autoload_paths/, 'config.autoload_paths'

inject_into_file 'config/application.rb', :before => "  end\nend" do
  <<-RUBY

    # Turn off timestamped migrations
    config.active_record.timestamped_migrations = false
  RUBY
end

inject_into_file 'config/application.rb', :before => "  end\nend" do
  <<-RUBY

    # Rotate log files (50 files max at 1MB each)
    config.logger = Logger.new(config.paths.log.first, 50, 1048576)
  RUBY
end

run 'bundle install'

generate 'responders:install'
generate 'rspec:install'
generate 'show_for:install'
generate 'simple_form:install'


append_file 'config/boot.rb' do
  <<-RUBY
  begin
    require File.expand_path('../local', __FILE__)
  rescue LoadError
    puts 'Copy config/local.sample.rb to config/local.rb and change it to suit your needs'
    exit
  end
  RUBY
end

require 'active_support/secure_random'

file 'config/local.sample.rb', localrb_template = <<-RUBY.gsub(/^ {2}/, '')
  # Application-specific global configuration settings.
  # These get loaded by config/boot.rb and
  # can be accessed via AppConfig[:param]

  AppConfig = {
    :default_sender => 'martin@schuerrer.org',
    :host => 'localhost:3000',
    :cookie_token => # `rake secret`
  }
RUBY
file 'config/local.rb', localrb_template
gsub_file 'config/local.rb', '# `rake secret`', "'#{ActiveSupport::SecureRandom.hex(64)}'"
gsub_file 'config/initializers/secret_token.rb', /'.+'/, 'AppConfig[:cookie_token]'

file 'config/assets.yml', <<-CODE.gsub(/^ {2}/, '')
  embed_assets: off

  stylesheets:
    all:
      - public/stylesheets/**/*.css
CODE

remove_file '.gitignore'
file '.gitignore', <<-CODE.gsub(/^ {2}/, '')
  .DS_Store
  .bundle
  .rvmrc
  config/database.yml
  config/local.rb
  db/*.sqlite3
  log/*.log
  tmp/**/*
  public/assets
  public/system
  rerun.txt
  session.vim
  TODO
  .idea
  *.iml
CODE

template "config/databases/#{@options[:database]}.yml", "config/database.sample.yml"

git :init
git :add => "."
git :commit => "-am 'Initial commit.'"

