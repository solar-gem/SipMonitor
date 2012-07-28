class CreateAlarms < ActiveRecord::Migration
  def change
    create_table :alarms do |t|
      t.string :serial_number, :limit => 10, :null => false # Серийный номер аварии (номер по порядку)
      t.datetime :alarm_raised_time, :null => false        # Время начала аварии
      t.datetime :cleared_time                             # Время восстановления аварии
      t.text :data                                         # Текст аврийного сообщения
      t.references :subscriber, :null => false             # Ссылка на таблицу с номером абонента
      t.boolean :status, :default => true                  # Статус аварии, активна или история

      t.timestamps
    end
    add_index :alarms, :subscriber_id
  end
end
