class FixLogEntryColumnName < ActiveRecord::Migration
  def up
    rename_column :log_entries, :type, :level
  end

  def down
    rename_column :log_entries, :level, :type
  end
end
