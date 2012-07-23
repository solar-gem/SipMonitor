class CreateSubscribers < ActiveRecord::Migration
  def change
    create_table :subscribers do |t|
      t.string :number, :limit => 10, :null => false
      t.string :name
      t.string :address
      t.boolean :control, :default => 'false'

      t.timestamps
    end
  end
end
