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

ActiveRecord::Schema.define(:version => 20120727034946) do

  create_table "alarms", :force => true do |t|
    t.datetime "alarm_raised_time"
    t.datetime "cleared_time"
    t.text     "data"
    t.integer  "subscriber_id"
    t.datetime "created_at",                                        :null => false
    t.datetime "updated_at",                                        :null => false
    t.string   "serial_number",     :limit => 10
    t.boolean  "status",                          :default => true
  end

  add_index "alarms", ["subscriber_id"], :name => "index_alarms_on_subscriber_id"

  create_table "scaners", :force => true do |t|
    t.boolean  "status"
    t.datetime "last_time"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "subscribers", :force => true do |t|
    t.string   "number",     :limit => 10
    t.string   "name"
    t.string   "address"
    t.boolean  "control"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "eid",        :limit => 32
    t.string   "area",       :limit => 5
  end

  create_table "users", :force => true do |t|
    t.string   "email"
    t.string   "password_digest"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

end
