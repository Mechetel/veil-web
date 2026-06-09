class AddUserToRecords < ActiveRecord::Migration[8.1]
  def change
    add_reference :images,     :user, null: false, foreign_key: true
    add_reference :embeddings, :user, null: false, foreign_key: true
    add_reference :decodings,  :user, null: false, foreign_key: true
    add_reference :analyses,   :user, null: false, foreign_key: true
  end
end
