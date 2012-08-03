#!/usr/bin/env ruby
# coding: utf-8
puts "#{Time.now}  start time"

WORK_DIR = File.expand_path(File.dirname(__FILE__)) # Рабочая директория программы
$:.unshift File.join(WORK_DIR)

require 'rubygems'
require 'connection_to_commutation_system_telnet'
require 'active_record'
require 'time' # Разбор строки для извленения даты
require 'colored' # Цветной вывод на экран


# Подключение к БД
#ActiveRecord::Base.establish_connection(:adapter => 'sqlite3',
#  :database => '/home/sa/Ruby/SipMonitor/db/development.sqlite3',
#  :pool => 5,
#  :timeout => 5000,
#  :encoding => 'utf8')
ActiveRecord::Base.establish_connection(
 adapter: 'mysql',
  encoding: 'utf8',
  database: 'sip_monitor',
  username: 'root',
  password: 'sersin',
  host: 'localhost')

# Таблица аварий
class Alarms < ActiveRecord::Base
  belongs_to :subscriber
end


class Subscribers < ActiveRecord::Base
  has_many :alarm
end

class Scaners < ActiveRecord::Base
end


module Malicious_SoftX

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

  # Отметка в БД о активности 
  def scan_activ
    begin
      last_record = Scaners.last
      if last_record
        Scaners.update(last_record, last_time: Time.now)
      else
        Scaners.new(last_time: Time.now).save
      end
    rescue => err
      puts "Ошибка обновления состояния сканера => #{err.to_s}"
    end

  end

  # Взаимодействие с БД
  def interaction_db(data_alarm)
    begin # Запись в БД
      subscriber_id = Subscribers.select(:id).where(eid: data_alarm[:eid], control: true).last # Запрос в БД данный номер стоит под наблюдением.
      return "no control" unless subscriber_id

      # Все предыдущие записи об авариях для данного абонента делаем не актуальными. Поле status = false
      Alarms.where(subscriber_id: subscriber_id.id, status: true).each{ |record| record.update_column(:status, false);record.update_column(:cleared_data, data_alarm[:data])}

      # Если есть признак восстановления аварии, то в БД ищем данный номер аварии и дополняем поле cleared_time.
      if data_alarm[:cleared_time]
        alarm_id = Alarms.select(:id).where(serial_number: data_alarm[:serial_number])
        if alarm_id.length != 0
          Alarms.update(alarm_id.first.id, cleared_time: data_alarm[:cleared_time], cleared_data: data_alarm[:data])
          return true
        else
          return "no search original alarm"
        end
      else # Если нет признака восстановления аварии, то создаем новую запись в БД аварий.
        new_record = Alarms.new(alarm_raised_time: data_alarm[:alarm_raised_time],
                               data: data_alarm[:data],
                               subscriber_id: subscriber_id.id, # !!! Потенциальные ошибки
                               serial_number: data_alarm[:serial_number])
        new_record.save
      end




      #      tt = TrapMaliciousCalls.new(:called => called,
#        :caller=>caller,
#        :alarm_time=>alarm_time,
#        :ip_host_trap=>SYSINFO.ipaddress_internal,
#        :alarm_data=>alarm_data,
#        :switching_system_id=>id)
#      tt.save
    rescue ActiveRecord::RecordNotUnique
      "duplicate"
    rescue => err
      p err
      puts $@

      puts "*" * 40
      puts err
      false
    end
  end # begin

  # Вывод информации о хулиганском вызове пользователю
  def notification(data_alarm,  save_db = nil)
    # Вывод данных о хулиганском вызове на терминал сервера
    str_alarm =  "EID => #{data_alarm[:eid].ljust(10)}  Авария => #{data_alarm[:serial_number].ljust(7)} Время => #{data_alarm[:alarm_raised_time].strftime("%H:%M:%S")} DB => #{save_db.to_s.ljust(10)} "
    if data_alarm[:cleared_time]
      str_alarm << " Востановление => #{data_alarm[:cleared_time] - data_alarm[:alarm_raised_time]} сек." 
    end
    case save_db
      when true    
        puts str_alarm.green
      when false
        puts str_alarm.red
      when "no search original alarm"
        puts str_alarm.yellow
      when "no control"
         puts str_alarm
    else
      puts str.red.underline
    end
  end
  # Предварительный запрос состояний абонентов перед запуском сканера
  def request_status
    ats_cmd =  ConnectionTelnet_SoftX.new(
      :name => "Softx",
      :version => "Softx3000",
      :address => "",
      :host => "10.200.16.8",
      :username => "opts270",
      :password => "270270")

      ats_cmd.connect
      ats_cmd.login



      numbers = Subscribers.where(control:true)
      numbers.each do |number|
        cmd_str = "DSP EPST: IEF=DOMAIN1, QUERYBY=METHOD1, TRMTYPE=TRM0, EID=\"#{number.eid}\";"
        ats_cmd.cmd(cmd_str)
        if ats_cmd.answer[:successful]
          if ats_cmd.answer[:data].include? "UnRegistered"
            puts "Equipment ID=#{number.eid} не зарегистрирован".red
            # Если абонент не зарегистрирован, а активных аварий в БД нет, то создаём новую аварию
            if Alarms.where(subscriber_id: number.id, status: true).count == 0
              begin # Запись в БД
              new_record = Alarms.new(alarm_raised_time: Time.now,
                               data: ats_cmd.answer[:data],
                               subscriber_id: number.id, # !!! Потенциальные ошибки
                               serial_number: 'DSP EPST:')
              new_record.save
              rescue ActiveRecord::RecordNotUnique
		      "duplicate"
		    rescue => err
		      p err
		      puts $@

		      puts "*" * 40
		      puts err
		      false
		    end
			    end
          else
            puts "Equipment ID=#{number.eid} зарегистрирован".green
            # Все предыдущие записи об авариях для данного абонента делаем не актуальными. Поле status = false
            Alarms.where(subscriber_id: number.id, status: true).each{ |record| record.update_column(:status, false);record.update_column(:cleared_data, ats_cmd.answer[:data])}

          end
        else
          puts "ERROR. Команда запроса регистрации абонета Equipment ID=#{number.eid} выполниласть не успешно!".red
        end
      end
      ats_cmd.close
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
      puts 
      puts "Запрос исходного состояния всех абонентов стоящих под наблюдением"
      request_status # Запрос исходного состояния всех абонентов стоящих под наблюдением
      puts 


      loop do
        # Ожидание данных со станции. Для предотвращения зависания используем timeout
        timeout(@ats.options[:timeout_restart]){ @tmp_data = @ats.wait(@ats.options[:end_report_alarm])[:data] }
        scan_activ # Сообщение в БД о времени активности сканера
        # Если аварийное сообщение имеет признак хулиганского вызова, то его анализируем
        @ats.options[:alarm_sip_regexp].each do |alarm_malicious_regexp|

          if @tmp_data =~ alarm_malicious_regexp   
            #number = @ats.finding_number(@tmp_data)
            #alarm_raised_time = @ats.finding_alarm_raised_time(@tmp_data)
            #serial_number = @ats.finding_serial_number @tmp_data
            #сleared_time = nil
            ###caller = @ats.finding_caller @tmp_data
            ###called = @ats.finding_called @tmp_data
            ###alarm_time = @ats.finding_alarm_time @tmp_data
            # Сохранение в базе данных
            ### rez_query = interaction_db(called, caller, alarm_time, @ats.options[:id], @tmp_data)
            # Вывод информации о хулиганском вызове пользователю
            ####notification(called, caller, alarm_time,rez_query)
            result = @ats.analysis_fault_warning_4251 @tmp_data
            result_db = interaction_db result
            notification(result, result_db)
                                 
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
      puts $@
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

  # Анализ аварии "Fault Warning Exchange 4251" - потеря регистрации SIP терминала
  def ats.analysis_fault_warning_4251(text_alarm)
    time_alarm = Time.parse(text_alarm[/(?<=NNov-SoftX        ).+/])
    serial_number = text_alarm[/(?<=ALARM  )\d+/]
    sync_serial_number = text_alarm[/(?<=Sync serial No.  =  )\d+/]
    alarm_raised_time = Time.parse(text_alarm[/(?<=Alarm raised time  =  ).+/]).utc
    eid = text_alarm[/(?<=EID=)\d+/]
    alarm_cause = text_alarm[/(?<=Alarm cause  =  ).+\n*.*(?=\n      Repair actions)/]
    search_cleared_time_str = text_alarm[/(?<=Cleared time  =  ).+/]
    cleared_time = Time.parse(search_cleared_time_str).utc if search_cleared_time_str
    {data: text_alarm, time_alarm: time_alarm, serial_number: serial_number, 
     sync_serial_number: sync_serial_number,
     alarm_raised_time: alarm_raised_time, eid: eid, 
     alarm_cause: alarm_cause, cleared_time: cleared_time ||= nil}
  end


scanner = Malicious.new(ats)
scanner.search


