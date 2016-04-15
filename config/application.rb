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

    config.i18n.fallbacks = true

    config.i18n.default_locale = :ka

    config.i18n.available_locales = [:ka, :en, :ru]

    # Do not swallow errors in after_commit/after_rollback callbacks.
    #config.active_record.raise_in_transactional_callbacks = true

    config.generators do |g|
      g.orm :mongoid
    end
  end
end

# module ExceptionNotifier
#   class EditorNotifier < BaseNotifier
#     def initialize(options)
#       # do something with the options...
#     end

#     def call(exception, options={})
#       self.send(:include, ExceptionNotifier::BacktraceCleaner)

#       env = options[:env]
#       @env        = env
#       @exception  = exception
#       @options    = options.reverse_merge(env['exception_notifier.options'] || {}).reverse_merge(default_options)
#       @kontroller = env['action_controller.instance'] || MissingController.new
#       @request    = ActionDispatch::Request.new(env)
#       @backtrace  = exception.backtrace ? clean_backtrace(exception) : []
#       @sections   = @options[:sections]
#       @data       = (env['exception_notifier.exception_data'] || {}).merge(options[:data] || {})
#       @sections   = @sections + %w(data) unless @data.empty?
#       puts "# send the notification #{exception.inspect} >>><<< #{options.inspect}"
#       # options[:on] = true if !options.key?(:on)
#       # options[:timeout] = 5000 if !options.key?(:timeout)
#       # #
#       # if options[:on]
#       #   begin
#       #     title = "#{exception.class} in #{@kontroller.controller_name}##{@kontroller.action_name}"
#       #     output = ""

#       #     output += exception.message.to_s + "\n" if exception.message.to_s.present?
#       #     bs = @backtrace.select{|b| b.include?("app/") }.map{|b| b}
#       #     output += bs.join("\n")

#       #     pars = []
#       #     @request.parameters.each {|k, v|
#       #       pars.push("#{k}: #{v}") if !["controller", "action"].index(k).present?
#       #     }
#       #     output += "\n{ #{pars.join(', ')} }" if pars.present?
#           title = "Error"
#           output = "Blah"
#           options = { timeout: 4000, editor: "subl"}
#           os_notify(title, output, options)

#           # if bs.present?
#           #   options[:editor] = "subl" if !options.key?(:editor) || ["subl", "atom"].index(options[:editor]).nil?
#           #   open_file_in_editor(get_path(bs[0], options)) # tested with atom
#           # end

#         # rescue Exception => e
#         #   puts "ExceptionNotifierExtensions has some errors #{e.inspect}"
#         # end
#       #end
#     end
#     def get_path(path)
#       path.strip!
#       last = path.index(":in")
#       path = path[0, last]
#       first = 0

#       for i in (path.length - 1)..0
#         if s[i] == " "
#           first = i
#           break
#         end
#       end
#       path = path[first, path.length]

#       return Rails.root.to_path + "/" + path

#     end
#     def open_file_in_editor(path, options)
#       system "#{options[:editor]} #{path}"
#     end
#     def os_notify(title, msg, options)
#       Notifier.notify(
#         :image   => Rails.root.to_path + "/public/favicon.ico",
#         :title   => title.present? ? title : "Exception Notifier",
#         :message => msg,
#         :timeout => options[:timeout]
#       )
#     end
#     def notify(options)
#       command = [
#         "notify-send", "-i",
#         options[:image].to_s,
#         options[:title].to_s,
#         options[:message].to_s,
#         "-t",
#         options[:timeout].to_s
#       ]

#       Thread.new { system(*command) }.join
#     end
#   end
# end

module Mongoid
  # Slugs your Mongoid model.
  module Slug
    def build_slug
      if localized?
        begin
          orig_locale = I18n.locale
          all_locales.each do |target_locale|
            I18n.locale = target_locale
            puts "building locale ------------------------ #{target_locale}"
            apply_slug
          end
        ensure
          I18n.locale = orig_locale
        end
      else
        apply_slug
      end
      true
    end
    def apply_slug
      new_slug = find_unique_slug

      # skip slug generation and use Mongoid id
      # to find document instead
      return true if new_slug.size == 0
      puts "----------------------------------------slug #{_slugs.inspect}_#{new_slug.inspect}"
      # avoid duplicate slugs
      _slugs.delete(new_slug) if _slugs

      if !!history && _slugs.is_a?(Array)
        append_slug(new_slug)
      else
        self._slugs = [new_slug]
      end
    end
    def slug_builder
      puts "-----------slug builder_#{new_with_slugs?}_#{_slugs.class}_#{persisted_with_slug_changes?}_#{pre_slug_string}"
      cur_slug = nil
      if new_with_slugs? || persisted_with_slug_changes?
        # user defined slug
        cur_slug = _slugs.last
      end
      puts "#{cur_slug || pre_slug_string}___#{(cur_slug || pre_slug_string).to_url}"
      # generate slug if the slug is not user defined or does not exist
      cur_slug || pre_slug_string
    end
    class UniqueSlug

      def find_unique(attempt = nil)
        puts "----------------------------------------attempt #{attempt.inspect}_#{model} #{url_builder.source_location}"
        MUTEX_FOR_SLUG.synchronize do
          @_slug = if attempt
                     attempt.to_url
                   else
                     url_builder.call(model)
                   end
           puts "========================== #{@_slug}"
          # Regular expression that matches slug, slug-1, ... slug-n
          # If slug_name field was indexed, MongoDB will utilize that
          # index to match /^.../ pattern.
          pattern = /^#{Regexp.escape(@_slug)}(?:-(\d+))?$/

          where_hash = {}
          where_hash[:_slugs.all] = [pattern]
          where_hash[:_id.ne]     = model._id

          if (scope = slug_scope) && reflect_on_association(scope).nil?
            # scope is not an association, so it's scoped to a local field
            # (e.g. an association id in a denormalized db design)
            where_hash[scope] = model.try(:read_attribute, scope)
          end

          if by_model_type == true
            where_hash[:_type] = model.try(:read_attribute, :_type)
          end

          @state = SlugState.new @_slug, uniqueness_scope.unscoped.where(where_hash), pattern

          # do not allow a slug that can be interpreted as the current document id
          @state.include_slug unless model.class.look_like_slugs?([@_slug])

          # make sure that the slug is not equal to a reserved word
          @state.include_slug if reserved_words.any? { |word| word === @_slug }

          # only look for a new unique slug if the existing slugs contains the current slug
          # - e.g if the slug 'foo-2' is taken, but 'foo' is available, the user can use 'foo'.
          if @state.slug_included?
            highest = @state.highest_existing_counter
            @_slug += "-#{highest.succ}"
          end
          @_slug
        end
      end
    end
  end
end

