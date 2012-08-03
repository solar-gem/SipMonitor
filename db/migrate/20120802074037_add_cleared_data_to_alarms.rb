class AddClearedDataToAlarms < ActiveRecord::Migration
  def change
    add_column :alarms, :cleared_data, :text
  end
end
