# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120802074037) do

  create_table "alarms", :force => true do |t|
    t.string   "serial_number",     :limit => 10,                   :null => false
    t.datetime "alarm_raised_time",                                 :null => false
    t.datetime "cleared_time"
    t.text     "data"
    t.integer  "subscriber_id",                                     :null => false
    t.boolean  "status",                          :default => true
    t.datetime "created_at",                                        :null => false
    t.datetime "updated_at",                                        :null => false
    t.text     "cleared_data"
  end

  add_index "alarms", ["subscriber_id"], :name => "index_alarms_on_subscriber_id"

  create_table "scaners", :force => true do |t|
    t.boolean  "status"
    t.datetime "last_time"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "subscribers", :force => true do |t|
    t.string   "area",        :limit => 5,                     :null => false
    t.string   "number",      :limit => 7,                     :null => false
    t.string   "full_number", :limit => 10,                    :null => false
    t.string   "eid",         :limit => 32
    t.string   "name"
    t.string   "address"
    t.boolean  "control",                   :default => false
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
  end

  add_index "subscribers", ["full_number"], :name => "index_subscribers_on_full_number", :unique => true

  create_table "users", :force => true do |t|
    t.string   "email"
    t.string   "password_digest"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

end
