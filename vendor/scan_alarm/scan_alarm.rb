#!/usr/bin/env ruby
# coding: utf-8
puts "#{Time.now}  start time"

WORK_DIR = File.expand_path(File.dirname(__FILE__)) # Рабочая директория программы
$:.unshift File.join(WORK_DIR)

require 'rubygems'
require 'connection_to_commutation_system_telnet'
require 'active_record'
require 'time' # Разбор строки для извленения даты
# Подключение к БД
ActiveRecord::Base.establish_connection(:adapter => 'sqlite3',
  :database => '/home/sa/Ruby/SipMonitor/db/development.sqlite3',
  :pool => 5,
  :timeout => 5000,
  :encoding => 'utf8')

# Таблица аварий
class Alarms < ActiveRecord::Base
end
module Malicious_assistant
  # Поиск номера 
  def finding_number(text_alarm, eid_regexp = @options[:eid_regexp])
    eid_regexp.each do |_eid_regexp|
      return text_alarm[_eid_regexp][/\d+/] if text_alarm[_eid_regexp]
    end
    ""
  end

  # Поиск времени начала аварии
  def finding_alarm_raised_time(text_alarm)
    
    time_str_source = text_alarm[@options[:alarm_raised_time_regexp]] 
    time_str = time_str_source.sub(/Alarm raised time[=\s]/, '')
    
    # Время в аварийном сообщении
    Time.parse(time_str)
  end
  

  # Поиск времени в аварийном сообщении
  def finding_alarm_time(text_alarm)
    time_str = text_alarm[/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/] # Время в аварийном сообщении
    Time.parse(time_str)
  end
end
module Malicious_SoftX
  include Malicious_assistant

  # подключении дополнительных параметров
  def add_malicious_options
    @options[:timeout_restart] = 1800 # Рестарт telnet подключения к станции для предотвращения зависания
    @options[:alarm_sip_regexp] = [/Fault  Warning     Exchange  4251    Software/] # Аварийное сообщение регистрации sip абонента
    @options[:alarm_raised_time_regexp] = /Alarm raised time[=\s]+[- :+\d]+/ # Признак время потери связи с SIP терминалом
    @options[:сleared_time_regexp] = /Cleared time[=\s]+[- :+\d]+/ # Признак время восстановления связи с SIP терминалом
    @options[:eid_regexp] = [/EID=\d+/] # Признак номера абонента. Здесь не абонентский номер, а Equipment ID
    #@options[:time_malicious_regexp] = /\S{3}\.\d{2} '\d{2} \S{3}\.\d{2}:\d{2}/ # Признак времени хулиганского вызова по станционному времени
  end

  def connect_telnet_malicious

  end
end





# Отслеживание хулиганских вызовов
class Malicious
  def initialize(ats)
    @ats = ats
    @ats.add_malicious_options
  end

  # Отметка в БД о активности демона
  def ats_actives
    begin
      old_actives = Demons.where(:switching_system_id => @ats.options[:id], :server => SYSINFO.ipaddress_internal, :pid => Process.pid)

      if old_actives.length == 0
        Demons.new(:switching_system_id => @ats.options[:id],
          :server => SYSINFO.ipaddress_internal,
          :pid => Process.pid,
          :alarm_data => @tmp_data).save
      else
        Demons.update(old_actives[0].id, :alarm_data => @tmp_data)
      end
    rescue => err
      puts "#{@ats.options[:name]}  Ошибка обновления состояния подключения к станции => #{err.to_s}"
    end

  end

  # Взаимодействие с БД
  def interaction_db(called, caller, alarm_time, id, alarm_data)
    begin # Запись в БД
      tt = TrapMaliciousCalls.new(:called => called,
        :caller=>caller,
        :alarm_time=>alarm_time,
        :ip_host_trap=>SYSINFO.ipaddress_internal,
        :alarm_data=>alarm_data,
        :switching_system_id=>id)
      tt.save
    rescue ActiveRecord::RecordNotUnique
      "duplicate"
    rescue => err
      p err
      puts "*" * 40
      puts err
      false
    end
  end # begin

  # Вывод информации о хулиганском вызове пользователю
  def notification(called, caller, alarm_time, save_db)
    # Вывод данных о хулиганском вызове на терминал сервера
    puts "#{@ats.options[:host].ljust(16)} A => #{caller.ljust(10)}   B => #{called.ljust(10)} TIME => #{alarm_time} DB => #{save_db}"
    
  end
  
  # Отслеживание хулиганских вызовов
  def search
    
    # Сканирование аварийных сообщений на предмет злонамеренных вызовов
    begin
      puts  "#{@ats.options[:name]} connecting to station ..." 
      @ats.connect
   
      puts  "#{@ats.options[:name]}   connect => #{@ats.connect?}    login => absent  time => #{Time.now}" 
      
      @tmp_data = "Connect staton"
     ### ats_actives           # Фиксируем активность демона в БД




      loop do
        # Ожидание данных со станции. Для предотвращения зависания используем timeout
        timeout(@ats.options[:timeout_restart]){ @tmp_data = @ats.wait(@ats.options[:end_report_alarm])[:data] }

        # Если аварийное сообщение имеет признак хулиганского вызова, то его анализируем
        @ats.options[:alarm_sip_regexp].each do |alarm_malicious_regexp|

          if @tmp_data =~ alarm_malicious_regexp   
	    number = @ats.finding_number(@tmp_data)
            print " #{number} =>  "
            puts alarm_raised_time = @ats.finding_alarm_raised_time(@tmp_data)
            ###caller = @ats.finding_caller @tmp_data
            ###called = @ats.finding_called @tmp_data
            ###alarm_time = @ats.finding_alarm_time @tmp_data
            # Сохранение в базе данных
            ### rez_query = interaction_db(called, caller, alarm_time, @ats.options[:id], @tmp_data)
            # Вывод информации о хулиганском вызове пользователю
            ###notification(called, caller, alarm_time,rez_query)

          end # if
        end # do
        ###ats_actives   # Фиксируем активность демона в БД
      end # loop
    rescue TimeoutError
      puts "#{@ats.options[:name]} Restart time => #{Time.now}"
      @ats.close # При любой ошибке пробуем закрыть соединение со станцией
      puts "#{@ats.options[:name]} Closing time => #{Time.now}"
      retry
    rescue => err
      puts "#{@ats.options[:name]} #{err.to_s}  ERROR time => #{Time.now}"
      @ats.close # При любой ошибке пробуем закрыть соединение со станцией
      puts "#{@ats.options[:name]} Closing time => #{Time.now}"
      sleep 1
      retry
    end # begin
  end
end


# Добавление поддержки анализа аварий состояния регистрации sip абонентов
class ConnectionTelnet_SoftX_scan_alm < ConnectionTelnet_SoftX
  include Malicious_SoftX
end

# Подключемся к станции SoftX3000
ats =  ConnectionTelnet_SoftX_scan_alm.new(        
        :name => "Softx",
        :version => "Softx3000",
        :address => "",
        :host => "10.200.16.8",
        :username => "",
        :password => "",
        :port => 6001,
        :waittime => 0)



scanner = Malicious.new(ats)

scanner.search


