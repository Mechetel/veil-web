class AddUsernameToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :username, :string
    add_index  :users, :username, unique: true, where: "username IS NOT NULL"
  end
end
