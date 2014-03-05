class RemoveUploadedAtColumn < ActiveRecord::Migration
  def up
    change_table :printjobs do |t|
      t.change :gcode, :string      
      t.rename :gcode, :gcodefile
      t.remove :uploaded_at
    end
  end
  
  def down
    change_table :printjobs do |t|
      t.column :uploaded_at, :datetime      
      t.rename :gcodefile, :gcode
      t.change :gcode, :text
    end    
  end
end
