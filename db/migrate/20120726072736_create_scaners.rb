class CreateScaners < ActiveRecord::Migration
  def change
    create_table :scaners do |t|
      t.boolean :status
      t.datetime :last_time

      t.timestamps
    end
  end
end
