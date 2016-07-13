require File.expand_path('../boot', __FILE__)

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
#require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
require 'sprockets/railtie'
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module StarterTemplate
  # Comment necessary for rubocop
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those
    # specified here. Application configuration should go into files
    # in config/initializers -- all .rb files in that directory
    # are automatically loaded.

    # Set Time.zone default to the specified zone and make Active
    # Record auto-convert to this zone. Run "rake -D time" for a
    # list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # Load all locale files (including those nested in folders)
    config.i18n.load_path += Dir[
      Rails.root.join('config', 'locales', '**', '*.{rb,yml}')
    ]
    # config.i18n.fallbacks = [:en, :ka, :ru]
    # config.i18n.fallbacks[:ka] = [:en, :ru]
    # config.i18n.fallbacks[:en] = [:ka, :ru]
    # config.i18n.fallbacks[:ru] = [:ka, :en]
    config.i18n.default_locale = :ka
    config.i18n.available_locales = [:ka, :en, :ru]
    config.i18n.fallbacks = {'en' => ['ka', 'ru'], 'ka' => ['en', 'ru'], 'ru' => ['ka', 'en']}


    # Do not swallow errors in after_commit/after_rollback callbacks.
    #config.active_record.raise_in_transactional_callbacks = true

    config.generators do |g|
      g.orm :mongoid
    end

    config.assets.precompile += %w( admin.js admin.css explore.js explore.css crypto.min.js vendor/highcharts.js vendor/highcharts-exporting.js vendor/highcharts-offline-exporting.js)

    config.active_job.queue_adapter = :delayed_job

    # Custom I18n fallbacks
    config.after_initialize do
      I18n.fallbacks = I18n::Locale::Fallbacks.new(en: :ka, ka: :en, ru: :ka)
    end
  end
end
