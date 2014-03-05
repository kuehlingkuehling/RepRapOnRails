class CreateFilaments < ActiveRecord::Migration
  def change
    create_table :filaments do |t|
      t.text :name
      t.integer :extrusion_temp

      t.timestamps
    end
  end
end
