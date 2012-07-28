class CreateSubscribers < ActiveRecord::Migration
  def change
    create_table :subscribers do |t|
      t.string :area, :limit => 5, :null => false   # Код города
      t.string :number, :limit => 7, :null => false # Номер телефона
      t.string :eid, :limit => 32                   # EID, запрашиваем со станции
      t.string :name                                # Кому принадлежит 
      t.string :address                             # Адрес где расположен
      t.boolean :control, :default => 'false'       # Отметка о необходимости постановки под контроль

      t.timestamps
    end
  end
end
