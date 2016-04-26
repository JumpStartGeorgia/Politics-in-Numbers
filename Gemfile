source 'https://rubygems.org'

#####################################################################
##################### Starter Template Gems #########################

# The framework! :)
gem 'rails', '4.2.2'

# Connection to Mongodb database
gem "mongoid", "~> 4.0.0"

# Mongoid URL slug or permalink generator
gem 'mongoid-slug', '~> 5.0.0'

# Integrate Paperclip into Mongoid.
gem "mongoid-paperclip", :require => "mongoid_paperclip"

# Delayed::Job (or DJ) encapsulates the common pattern of asynchronously executing longer tasks in the background.
gem 'delayed_job_mongoid'

# SCSS parsing in asset pipeline
gem 'sass-rails', '~> 5.0'

# CSS and JS compression for production
gem 'uglifier', '>= 1.3.0'

# Makes jQuery available in rails JS
gem 'jquery-rails', '~> 4.0.3'

# Uses caching to improve performance for internal page changes
#gem 'turbolinks', '~> 2.5.3'

# JSON creation
gem 'jbuilder', '~> 2.0'

# Stores project secrets in environment variables
gem 'dotenv-rails', '~> 2.0.0'

# Makes compatibility easier for jQuery and turbolinks
#gem 'jquery-turbolinks', '~> 2.1.0'

# Makes jQuery UI (like jQuery datepicker) available
gem 'jquery-ui-rails', '~> 5.0.3'

# Simplifies form creation
gem 'formtastic', '~> 3.1.3'

# JavaScript interpreter
gem 'therubyracer', '~> 0.12.1'

# Needed for twitter-bootstrap-rails gem
gem 'less-rails', '~> 2.7.0'

# Bootstrap JS and various bootstrap-related generators/helpers
gem 'twitter-bootstrap-rails', '~> 3.2.2'

# Use formtastic to generate bootstrap-styled forms
gem 'formtastic-bootstrap', '~> 3.1.0'

# Authentication
gem 'devise', '~> 3.4.1'

# Authorization
gem 'cancancan', '~> 1.10.1'

# So that our SCSS can use bootstrap variables
gem 'bootstrap-sass', '~> 3.3.5'

# Useful icons
gem 'font-awesome-sass', '~> 4.4.0'

# Ruby server
gem 'puma', '~> 2.11.1'

# sends updates to google analytics when turbolinks changes page
#gem 'google-analytics-turbolinks', '~> 0.0.4'

# Sends email when exception or error is thrown
gem 'exception_notification', '~> 4.1', '>= 4.1.1'

# Select2 is a jQuery based replacement for select boxes.
gem 'select2-rails', '~> 4.0', '>= 4.0.1.1'

# Work with xlsx files
gem "rubyXL"

# jQuery DataTables plugin - provides all the basic DataTables files, and a few of the extras.
gem 'jquery-datatables-rails', '~> 3.3.0'

group :development do
  # Silences assets-related logging
  gem 'quiet_assets', '~> 1.0.3'

  # Recommends SQL query performance optimizations
  gem 'bullet', '~> 4.14.5'

  # Static code analyzer that finds potential security issues
  gem 'brakeman', '~> 3.0.5', require: false

  # Finds unused and missing translations
  gem 'i18n-tasks', '~> 0.8.3'

  # Server-related tasks (such as deploy)
  gem 'mina', '~> 0.3.3', require: false

  # Mina for multiple servers
  gem 'mina-multistage', '~> 1.0.1', require: false

  # Prints arrays, hashes, etc. beautifully
  gem 'awesome_print', '~> 1.6', '>= 1.6.1'

  # Export and import locale files to work with translators
  gem 'locales_export_import', '~> 0.4.2'

end

group :test do
  # Specification testing
  gem 'rspec-rails', '~> 3.1.0'

  # Adds syntax to check that a collection has a certain number of something
  # Ex: expect(new_user).to have(1).error_on(:role)
  gem 'rspec-collection_matchers', '~> 1.1.2'

  # Provides a collection of RSpec-compatible matchers that help to test Mongoid documents.
  gem 'mongoid-rspec', '~> 2.1.0'

  # Easy data creation in tests
  gem 'factory_girl_rails', '~> 4.5.0'

  # Testing API for Rack apps
  gem 'rack-test', '0.6.2'

  # Feature testing
  gem 'capybara', '~> 2.4.4'

  # Can launch browser in case of feature spec errors
  gem 'launchy', '~> 2.4.3'

  # Web driver for feature tests
  gem 'selenium-webdriver', '~> 2.44.0'

  # Tasks screenshots when capybara feature test fails
  gem 'capybara-screenshot', '~> 1.0.4'

  # Cleans database during tests
  gem 'database_cleaner', '~> 1.3.0'

  # Fast web driver with JavaScript support for feature tests
  gem 'poltergeist', '~> 1.7'

  # Feature testing for emails
  gem 'capybara-email', '~> 2.4'
end

group :development, :test do
  # Debugging: write 'binding.pry' in Ruby code to debug in terminal
  gem 'pry-byebug', '~> 3.1.0'

  # Adds a console to application errors in browser
  gem 'web-console', '~> 2.0'

  # Rails app preloader; runs app in background to speed up dev environment
  gem 'spring', '~> 1.3.5'

  # Ruby code style
  gem 'rubocop', '~> 0.35.0'

  # Add ability to show exception info using os notification system and open file with error in your editor on specific line.
   gem 'exception_notification_extension', :git => 'git@github.com:JumpStartGeorgia/exception_notification_extension.git'
end

#####################################################################
########################## Project Gems #############################
