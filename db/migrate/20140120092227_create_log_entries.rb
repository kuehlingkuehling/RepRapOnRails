class CreateLogEntries < ActiveRecord::Migration
  def change
    create_table :log_entries do |t|
      t.integer :type
      t.text :line

      t.timestamps
    end
  end
end
