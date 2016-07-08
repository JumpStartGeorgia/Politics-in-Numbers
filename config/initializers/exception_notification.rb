if Rails.env.production? || Rails.env.staging?
  Rails.application.config.middleware
    .use ExceptionNotification::Rack,
         email: {
           email_prefix: "[Politics in Numbers App Error (#{Rails.env})] ",
           sender_address: [ENV['APPLICATION_ERROR_FROM_EMAIL']],
           exception_recipients: [ENV['APPLICATION_FEEDBACK_TO_EMAIL']]
         }
end
