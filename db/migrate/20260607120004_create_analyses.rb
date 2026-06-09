class CreateAnalyses < ActiveRecord::Migration[8.1]
  def change
    create_table :analyses do |t|
      t.integer :status, null: false, default: 0
      t.string  :core_job_id
      t.jsonb   :params,  null: false, default: {}  # { analyzer_key }
      t.jsonb   :result,  null: false, default: {}  # { prob_stego, prob_cover, label, logits }
      t.text    :error_message
      t.references :input_image, null: false, foreign_key: { to_table: :images }
      t.datetime :enqueued_at
      t.datetime :finished_at

      t.timestamps
    end

    add_index :analyses, :core_job_id
    add_index :analyses, :created_at
  end
end
