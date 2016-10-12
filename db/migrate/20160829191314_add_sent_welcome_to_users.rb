class AddSentWelcomeToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :sent_welcome, :bool, default: false

    # one time update
    User.subscribed.each{|user| user.update(sent_welcome: true)}
  end
end
