class CreateAlarms < ActiveRecord::Migration
  def change
    create_table :alarms do |t|
      t.datetime :alarm_raised_time
      t.datetime :cleared_time
      t.text :data
      t.references :subscriber

      t.timestamps
    end
    add_index :alarms, :subscriber_id
  end
end
