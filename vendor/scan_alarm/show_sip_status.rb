#!/usr/bin/env ruby
# coding: utf-8

WORK_DIR = File.expand_path(File.dirname(__FILE__)) # Рабочая директория программы
$:.unshift File.join(WORK_DIR)

require 'rubygems'
require 'getoptlong' # Разбор параметров командной строки
require 'connection_to_commutation_system_telnet' # Библиотека работы со станциями
require 'active_record'
require 'time' # Разбор строки для извленения даты
require 'colored' # Цветной вывод на экран


# Подключение к БД
ActiveRecord::Base.establish_connection(
  adapter:  'mysql',
  encoding: 'utf8',
  database: 'sip_monitor',
  username: 'root',
  password: 'sersin',
  host:     'localhost')

  # Таблица аварий
  class Alarms < ActiveRecord::Base
    belongs_to :subscriber
  end

  # Таблица абонентов
  class Subscribers < ActiveRecord::Base
    has_many :alarm
  end
  # Состояние сканера аварий
  class Scaners < ActiveRecord::Base
  end

@version = "0.0.1"





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












  def request_status

      numbers = Subscribers.where(control:true)
      numbers.each do |number|
        # Команда запроса состояния регистации sip терминала на станции
        cmd_str = "DSP EPST: IEF=DOMAIN1, QUERYBY=METHOD1, TRMTYPE=TRM0, EID=\"#{number.eid}\";"
        @ats.cmd(cmd_str)
        if @ats.answer[:successful]
          if @ats.answer[:data].include? "UnRegistered"
            puts "Equipment ID=#{number.eid} не зарегистрирован".red
            # Если абонент не зарегистрирован, а активных аварий в БД нет, то создаём новую аварию
            if Alarms.where(subscriber_id: number.id, status: true).count == 0
              begin # Запись в БД
                new_record = Alarms.new(alarm_raised_time: Time.now,
                                        data: @ats.answer[:data],
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
            Alarms.where(subscriber_id: number.id, status: true).each{ |record| record.update_column(:status, false);record.update_column(:cleared_data, @ats.answer[:data])}

          end
        else
          puts "ERROR. Команда запроса регистрации абонета Equipment ID=#{number.eid} выполниласть не успешно!".red
        end
      end
      @ats.close
  end




  # Разбор параметров командной строки.
  @opts = GetoptLong.new(
    [ "--print", "-p", GetoptLong::NO_ARGUMENT ],
    [ "--version", "-v", GetoptLong::NO_ARGUMENT ]
  )
  @arg_print = false
  begin
    @opts.each do |opt, arg|
      case opt
      when "--print" then puts "Messages output to the console."; @arg_print = true
      when "--version" then puts @version; exit 0
      end
    end
  rescue GetoptLong::InvalidOption => e
    puts "ignored #{e.message}"
  end


  # Параметры подключения к станции
  @ats =  ConnectionTelnet_SoftX.new(
    :name => "Softx",
    :version => "Softx3000",
    :address => "",
    :host => "10.200.16.8",
    :username => "opts270",
    :password => "270270")

    print 'Подключение к станции ... '
    # Подключаемся к станции
    @ats.connect ? puts('успешно').green : puts('не успешно').red; exit
    # Авторизируемся на станции
    @ats.login ? puts('успешно').green : puts('не успешно').red; exit



