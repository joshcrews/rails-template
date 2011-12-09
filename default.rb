@template_root = File.expand_path(File.join(File.dirname(__FILE__)))
@file_templates = File.join(@template_root, 'file_templates')

def copy_file(file_path, destination_path)
  file destination_path, File.read(File.join(@file_templates, file_path))
end

create_file ".rvmrc", "rvm gemset use 1.9.2@#{app_name}"

gem "airbrake"
gem "devise"

gem("rspec-rails", :group => "test")
gem("cucumber-rails", :group => "test")
gem("launchy", :group => "test")
gem("capybara", :group => "test")
gem("database_cleaner", :group => "test")
gem('spork', '~> 0.9.0.rc', :group => "test")
gem("mocha", :group => "test")

gem("factory_girl", :group => "test")
gem("email_spec", :group => "test")

gem("pg", :group => "heroku")

gem("sqlite3", :group => ["test", "development"])
gem("pry", :group => ["test", "development"])

gem("letter_opener", :group => "development")

copy_file "mocha.rb", "features/support/mocha.rb"
copy_file "web_steps.rb", "features/step_definitions/web_steps.rb"
copy_file "paths.rb", "features/support/paths.rb"
copy_file "web_steps.rb", "features/support/selectors.rb"
copy_file "sample.jpg", "features/support/assets/sample.jpg"
copy_file "bootstrap.sass", "app/assets/stylesheets/bootstrap.sass"

run 'bundle install --without heroku'

rake "db:create", :env => 'development'
rake "db:create", :env => 'test'

inject_into_file 'config/application.rb', :after => "config.filter_parameters += [:password]" do
  <<-eos
    
    # Customize generators
    config.generators do |g|
      g.orm             :active_record
      g.test_framework  false
      g.stylesheets     false
      g.javascripts     false
    end
  eos
end

inject_into_file 'config/environments/production.rb', :after => "config.active_support.deprecation = :notify" do
  <<-eos
    
    ActionMailer::Base.smtp_settings = {
      :address        => 'smtp.sendgrid.net',
      :port           => '587',
      :authentication => :plain,
      :user_name      => ENV['SENDGRID_USERNAME'],
      :password       => ENV['SENDGRID_PASSWORD'],
      :domain         => 'heroku.com'
    }
    ActionMailer::Base.delivery_method = :smtp
  eos
end

generate "devise:install"
generate "devise User"
generate "devise:views"

rake "db:migrate"

inject_into_file 'config/initializers/devise.rb', :after => "Devise.setup do |config|" do
  <<-eos
    
    config.sign_out_via = :get
  eos
end

generate 'cucumber:install --spork'
generate "email_spec:steps"

inject_into_file 'features/support/env.rb', :after => "require 'cucumber/rails'" do
  <<-eos
    
    # Prevent Devise from loading the User model super early with it's route hacks for Rails 3.1 rc4
    # see also: https://github.com/timcharper/spork/wiki/Spork.trap_method-Jujutsu
    Spork.trap_method(Rails::Application, :reload_routes!)
    Spork.trap_method(Rails::Application::RoutesReloader, :reload!)
    
  eos
end

inject_into_file 'features/support/env.rb', :after => "require 'cucumber/rails'" do
  <<-eos
    
    require 'email_spec' # add this line if you use spork
    require 'email_spec/cucumber'
    
  eos
end


inject_into_file 'config/environments/development.rb', :after => "config.assets.debug = true" do
  <<-eos
    
    config.action_mailer.default_url_options = { :host => 'localhost:3000' }
    config.action_mailer.delivery_method = :letter_opener
    
  eos
end

# rails console uses pry
inject_into_file 'config/environments/development.rb', :after => "config.assets.debug = true" do
  <<-eos
    
    silence_warnings do
      begin
        require 'pry'
        IRB = Pry
      rescue LoadError
      end
    end
    
  eos
end

generate "controller Welcome index"
route "root :to => 'welcome#index'"

remove_file 'public/images/rails.png'
remove_file 'public/index.html'

run 'cp config/database.yml config/database.example'
run "echo 'config/database.yml' >> .gitignore"

commit to git
git :init
git :add => "."
git :commit => "-a -m 'create initial application'"
