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

def preparation_ats
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
        puts 'Успешное подключение к станции'
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
end

def test_subsrciber
  cmd_str = "DSP EPST: IEF=DOMAIN1, QUERYBY=METHOD1, TRMTYPE=TRM0, EID=\"#{eid}\";"
  @ats.cmd(cmd_str)
  if @ats.answer[:successful]
    if @ats.answer[:data].include?("UnRegistered")
       result = {result: 'не зарегистрирован', data: @ats.answer[:data]}
     else
       result = {result: 'зарегистрирован', data: @ats.answer[:data]}
     end
  else
    result = {result: '???', data: @ats.answer[:data]}
    errors.add(:cmd, "Не удалось получить данные при запросе состояния регистрации абонета #{number}")
  end
  @ats.close
  result
end

  # Запрашиваем или проверяем Equipment ID со станции
  def operation_EID_from_station



     eid == '' ? request_EID_from_station : verification_EID_from_station

      @ats.close

  end

# Запрашиваем Equipment ID со станции
def request_EID_from_station
  # Запрашиваем со станции Local DnSet для дальнейшено поиска Equipment ID
      begin
        @ats.cmd("LST USER: SDN=K'#{number}, EDN=K'#{number}, PT=ALL,CONFIRM=Y;")
        ldnset = @ats.answer[:data][/\d+(?= +#{number} +#{number})/]
      rescue
        self.errors.add(:cmd, "Не удалось получить данные при запросе Local DnSet!")
        return nil
      end
      # Запрашиваем со станции Equipment ID
      begin
        @ats.cmd("LST SBR: D=K'#{number}, LP=#{ldnset};")
      rescue
        self.errors.add(:cmd, "Не удалось получить данные при запросе Equipment ID!")
        return nil
      end

      if @ats.answer[:successful]
        # Проверка является ли абонент SIP
        unless @ats.answer[:data][/Port type  =  SIP subscriber/]
          self.errors.add(:cmd, "Номер #{number} не является SIP.")

          return nil
        end

        # !!! Нужно добавить более полную проверку ошибок.
        # !!! Нужно искать не только EID абонента, но и LP по коду города. Есть проблема с несколькими LP в городе и они завязаны на не правильный Area код (код города)
        self.eid = @ats.answer[:data][/(?<=Equipment ID  =  )\d+/]

      else
        self.errors.add(:cmd, "Номер #{number} не прописан.")
        return nil
      end
end
# Проверяем Equipment ID
def verification_EID_from_station
  @ats.cmd("LST MSBR: EID=\"#{eid}\";")
  if @ats.answer[:successful] && @ats.answer[:data].include?("Subscriber number  =  #{number}")

  else
    errors.add(:cmd, "Номер #{number} и Equipment ID #{eid} не соответствуют друг другу.")
    self.eid = nil
  end


end

end




