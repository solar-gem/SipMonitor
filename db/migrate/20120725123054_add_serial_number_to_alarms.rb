class AddSerialNumberToAlarms < ActiveRecord::Migration
  def change
    add_column :alarms, :serial_number, :string, :limit => 10
  end
end
