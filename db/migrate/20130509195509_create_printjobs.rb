class CreatePrintjobs < ActiveRecord::Migration
  def change
    create_table :printjobs do |t|
      t.string :name
      t.text :gcode
      t.string :note
      t.datetime :uploaded_at

      t.timestamps
    end
  end
end
