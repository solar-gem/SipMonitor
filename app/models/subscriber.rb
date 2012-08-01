# coding: utf-8
require 'connection_to_commutation_system_telnet'

# Сумма из кода города и номера телефона должна быть 10 цифр
class SumAreaNumberValidator < ActiveModel::Validator
  def validate(record)
    if record.area && record.number && ((record.area + record.number).length != 10)
      record.errors[:area_number] << "не соотвествует формату зонового номера. Код города и номер телефона в сумме должны быть 10 цифр."
    end
  end
end





class Subscriber < ActiveRecord::Base

  has_many :alarm
  attr_accessible :address, :control, :name, :number, :area, :eid, :full_number

  # Полный номер абонента. Для облегчения поиска когда пользователь в view/application производит поиск по номеру телефона.
  before_save do |subscriber|
   subscriber.full_number = subscriber.area + subscriber.number
  end


  validates :area, {length:  { :in => 3..5 }}
  validates :number, {length: { in: 5..7 }}
  validates_uniqueness_of :full_number

  # Сумма из кода города и номера телефона должна быть 10 цифр
  include ActiveModel::Validations
  validates_with(SumAreaNumberValidator)

  # Запрашиваем Equipment ID со станции
  def request_EID_from_station

    @ats =  ConnectionTelnet_SoftX.new(
      :name => "SoftX",
      :version => "SoftX3000",
      :host => "10.200.16.8",
      :username => "opts270",
      :password => "270270")

      puts @ats
      puts '2' * 50

      begin
        @ats.connect
      rescue
        errors.add(:connect, "Не удалось подключиться к станции для запроса Equipment ID!") 
        return nil
      end

      begin
        @ats.login
      rescue
        errors.add(:login, "Не удалось авторизироваться на станции для запроса Equipment ID!") 
        return nil
      end


      begin
        @ats.cmd("LST SBR: D=K'#{number}, LP=0;")
      rescue

        self.errors.add(:cmd, "Не удалось получить данные при запросе Equipment ID!") 
        puts '5' * 50
        return nil
      end

      if @ats.answer[:successful]
        # Проверка является ли абонент SIP
        unless @ats.answer[:data][/Port type  =  SIP subscriber/]
          self.errors.add(:cmd, "Номер #{number} не является SIP.")
          puts '#' * 50
          p self.errors
          return nil
        end

        # !!! Нужно добавить более полную проверку ошибок.
        # !!! Нужно искать не только EID абонента, но и LP по коду города. Есть проблема с несколькими LP в городе и они завязаны на не правильный Area код (код города)
        self.eid = @ats.answer[:data][/(?<=Equipment ID  =  )\d+/]

        puts '#' * 50
        p self.errors
        puts eid
      else
        self.errors.add(:cmd, "Номер #{number} не прописан.")
        puts '7' * 50
        p self.errors
        return nil
      end

  end



end




