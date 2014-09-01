class CreatePreheatingProfile < ActiveRecord::Migration
  def change
    create_table :preheating_profile do |t|
      t.string :name
      t.integer :chamber_temp
      t.integer :bed_temp

      t.timestamps
    end
  end
end
