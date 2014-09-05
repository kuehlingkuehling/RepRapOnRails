class CreatePreheatingProfiles < ActiveRecord::Migration
  def change
    create_table :preheating_profiles do |t|
      t.string :name
      t.integer :chamber_temp
      t.integer :bed_temp

      t.timestamps
    end
  end
end
