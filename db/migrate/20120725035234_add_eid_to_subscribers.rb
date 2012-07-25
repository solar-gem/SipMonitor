class AddEidToSubscribers < ActiveRecord::Migration
  def change
    add_column :subscribers, :eid, :string, {:limit => 32}
  end
end
