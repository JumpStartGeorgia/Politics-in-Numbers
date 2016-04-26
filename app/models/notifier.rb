class Notifier
  class << self
    def _about_donorset_file_process(msg, email)
      NotificationMailer.about_donorset_file_process(Message.new({subject: "Donorset processing message", message: msg, to: email})).deliver
    end
    handle_asynchronously :_about_donorset_file_process, :priority => 0
  end

  def self.about_donorset_file_process(msg, user)
    Notifier._about_donorset_file_process(msg, (user.present? ? user.email : User.admin_email))
  end
end
