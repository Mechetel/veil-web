# Make deleting an Image safe at the DB level: cascade to the operations that use
# it as input, and nullify the back-reference from an embedding to its stego output.
# (Rails dependent: :destroy handles the app-level path + Active Storage cleanup.)
class AdjustImageForeignKeys < ActiveRecord::Migration[8.1]
  def up
    remove_foreign_key :embeddings, column: :input_image_id
    remove_foreign_key :embeddings, column: :output_image_id
    remove_foreign_key :decodings,  column: :input_image_id
    remove_foreign_key :analyses,   column: :input_image_id

    add_foreign_key :embeddings, :images, column: :input_image_id,  on_delete: :cascade
    add_foreign_key :embeddings, :images, column: :output_image_id, on_delete: :nullify
    add_foreign_key :decodings,  :images, column: :input_image_id,  on_delete: :cascade
    add_foreign_key :analyses,   :images, column: :input_image_id,  on_delete: :cascade
  end

  def down
    remove_foreign_key :embeddings, column: :input_image_id
    remove_foreign_key :embeddings, column: :output_image_id
    remove_foreign_key :decodings,  column: :input_image_id
    remove_foreign_key :analyses,   column: :input_image_id

    add_foreign_key :embeddings, :images, column: :input_image_id
    add_foreign_key :embeddings, :images, column: :output_image_id
    add_foreign_key :decodings,  :images, column: :input_image_id
    add_foreign_key :analyses,   :images, column: :input_image_id
  end
end
