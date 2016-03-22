if Rails.env.production? || Rails.env.staging?
  Rails.application.config.action_mailer.delivery_method = :smtp

  Rails.application.config.action_mailer.smtp_settings = {
    address: 'smtp.gmail.com',
    port: 587,
    domain: 'jumpstart.ge',
    user_name: ENV['APPLICATION_FEEDBACK_FROM_EMAIL'],
    password: ENV['APPLICATION_FEEDBACK_FROM_PWD'],
    authentication: :plain,
    enable_starttls_auto: true
  }
end
