# Overrides default devise mailer
class DeviseMailer < Devise::Mailer
  default from: ENV['APPLICATION_FEEDBACK_FROM_EMAIL'],
          reply_to: ENV['APPLICATION_FEEDBACK_FROM_EMAIL']
  layout 'mailer'

  # gives access to all helpers defined within `application_helper`.
  helper :application

  # Optional. eg. `confirmation_url`
  include Devise::Controllers::UrlHelpers
end
