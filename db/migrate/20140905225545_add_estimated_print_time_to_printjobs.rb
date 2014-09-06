class AddEstimatedPrintTimeToPrintjobs < ActiveRecord::Migration
  def change
    add_column :printjobs, :estimated_print_time, :float
  end
end
