# Mailer defaults for whole app
class ApplicationMailer < ActionMailer::Base
  default from: ENV['APPLICATION_FEEDBACK_FROM_EMAIL'],
          reply_to: ENV['APPLICATION_FEEDBACK_FROM_EMAIL']
  layout 'mailer'
end
