class CreateImages < ActiveRecord::Migration[8.1]
  def change
    create_table :images do |t|
      t.integer :kind,    null: false, default: 0  # 0 cover, 1 stego
      t.integer :origin,  null: false, default: 0  # 0 uploaded, 1 encoded
      t.bigint  :source_embedding_id               # set when produced by an Embedding
      t.jsonb   :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :images, :source_embedding_id
    add_index :images, :created_at
  end
end
