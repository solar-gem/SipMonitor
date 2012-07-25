class AddAreaToSubscribers < ActiveRecord::Migration
  def change
    add_column :subscribers, :area, :string, :length => 5
  end
end
