class AddCodeToSubscribers < ActiveRecord::Migration
  def change
    add_column :subscribers, :code, :string
  end
end
