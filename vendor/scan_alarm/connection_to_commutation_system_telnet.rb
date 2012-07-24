
# Подключение к коммутационным объектам с помощью telnet.

require 'net/telnet'
require 'timeout'     # Таймер выполнения кода

# Данные выполнения команды на станции.
# command              => команда посланная на станцию
# start_time           => время начала выполнения команды
# data                 => ответ на команду
# successful           => результат выполнения команды в станциии. Сравниваем результат с RETCODE = 0  Operation succeeded
# retcode              => код выполнения команды на станции. коды выполнения команд (при 2-х рапортах на одну команду)
# time                 => время выполнения команды на станции
# connection_integrity => выполнилась ли каманда "до конца" (без timeout, ошибка telnet подключения)
# error                => ошибка telnet соединения
Answer = Struct.new(:command, :start_time, :data, :successful, :retcode,
  :time, :connection_integrity, :error)

# Подключение осуществляется по не стандартному порту telnet
# Авторизация производится с помощью команды
# Ответ на команду содержит подтверждение её выполнения и код ошибки
# CC08, SoftX => нет приглашения к вводу команд
module ConsoleConfirmation #ConsoleTelnet
  # Посылка команды
  # timeout_total   => общее время на выполнение всей команды
  # timeout_waitfor => время на ожидание частичных ответов на команду
  def cmd(command, timeout_total = 60, timeout_waitfor = 60)
    @answer = Answer.new(command, Time.new, '', false, [], nil, false, nil)
    # Генерация исключения, если флаг состояния соединения (@connect) = false
    unless @connect
      close
      raise "Telnet connection closed"
    end
    begin
      timeout(timeout_total + 1) do
        begin
          continue = false # Требуется ли ожидание ответа на команду. Это когда результат на команду выдаётся с задержкой
          @connection.cmd("String" => command, "Timeout" => timeout_waitfor) do |temp_data|
            @answer[:data] << temp_data
            # Сохраняем коды выполнения команды
            @answer[:retcode] << temp_data[@options[:retcode_regexp]]
            # Определяем требуется ли дополнительное ожидание в ответ на команду
            @options[:array_continue_regexp].each {|array_regexp| continue = true if temp_data[array_regexp]}
            if block_given?
              yield(temp_data)
            end
          end

          @options[:array_end_continue_regexp].each {|array_regexp| continue = false if @answer[:data][array_regexp]}
          # Ожидаем дополнительных данных
          while continue
            @connection.waitfor("Match" => @options[:end_report_regexp], 'Timeout' => timeout_waitfor) do |temp_data|
              @answer[:data] << temp_data
              # Сохраняем коды выполнения команды
              @answer[:retcode] << temp_data[@options[:retcode_regexp]]
              # Определяем требуется ли дополнительное ожидание в ответ на команду
              @options[:array_continue_regexp].each {|array_regexp| continue = true if temp_data[array_regexp]}
              if block_given?
                yield(temp_data)
              end
            end
            @options[:array_end_continue_regexp].each {|array_regexp| continue = false if @answer[:data][array_regexp]}
          end
        rescue Errno::ECONNABORTED  # Telnet соединение сброшено
          @connect = false
          @login = false
          @answer[:error] = Errno::ECONNABORTED
        rescue Errno::ECONNRESET  # Удаленный хост принудительно разорвал существующее подключение.
          @connect = false
          @login = false
          @answer[:error] = Errno::ECONNRESET
        rescue => err      # Остальные ошибки
          @answer[:error] = err
        else
          @answer[:connection_integrity] = true
        end
      end
    rescue Timeout::Error      # Истекло время ожидания данных. Превышено значение Timeout.
      @answer[:error] << Timeout::Error
    end

    @answer[:retcode].compact! # Удаление значений nil из массива с кодами выполнения комманды
    @answer[:successful] = true if @answer[:retcode].detect { |e| e =~ @options[:retcode0_regexp] }
    @answer[:time] = Time.new - @answer[:start_time] # время выполнения команды на станции
    @answer
  end

  # Авторизация
  def login
    command = "LGI:OP=\"#{@options[:username]}\", PWD=\"#{@options[:password]}\";"
    cmd(command)
    @login = @answer[:successful]
  end

end

# Подключение осуществляется по стандартному порту (23) telnet
# Авторизация вводится по запросу имени пользователя и пароля
# Ответ на команду не содержит подтверждение её выполнения и код ошибки
# UA5000, коммутаторы
module ConsoleNotConfirmation #ConsolePortTelnet
 
  # Определение приглашения командной строки
  def invitation(str)
    array_host_name = /^\S+>\z/.match(str)
    return array_host_name[0].chop!
  end

  # Авторизация по запросу имени пользователя и пароля
  def login    
    sleep 0.5
    @answer = Answer.new("login", Time.new, '', false, nil, nil, false, nil) 
    begin
      timeout(20) {
        @connection.login("Name" => @options[:username],
          "LoginPrompt" => @options[:login_prompt],
          "Password" => @options[:password],
          "PasswordPrompt" => @options[:password_prompt]) do |recvdata|
          @answer[:data] << recvdata if recvdata          
        end
      }            
      # Выявляем приглашение командной строки      
      @options[:prompt] = invitation(@answer[:data]) unless @options[:prompt]
      @answer[:successful] = true
      @answer[:connection_integrity] = true
      @answer[:time] = Time.new - @answer[:start_time]
      @login = true
    rescue Timeout::Error  # Превышен интервал ожидания авторизации
      @answer[:time] = Time.new - @answer[:start_time]
      @connect = false
      @login = false
    end    
  end  

  # Отправка команды на станцию с ожиданием ответа
  def cmd(command, timeout_total = 60, timeout_waitfor = 60)    
    @answer = Answer.new(command, Time.new, '', true, nil, nil, false, nil)
    # Генерация исключения, если флаг состояния соединения (@connect) = false
    unless @connect
      close
      raise "Telnet connection closed"
    end
    begin
      timeout(timeout_total + 1) do
        begin
          continue = false # Требуется ли ожидание ответа на команду. Это когда результат на команду выдаётся с задержкой
          @connection.cmd("String" => command, "Timeout" => timeout_waitfor) do |temp_data|            
            @answer[:data] << temp_data
            # Определяем требуется ли дополнительное ожидание в ответ на команду
            @options[:array_continue_regexp].each {|array_regexp| continue = true if temp_data[array_regexp]}
            if block_given?
              yield(temp_data)
            end
          end

          # !!!!! @options[:array_end_continue_regexp].each {|array_regexp| continue = false if @answer[:data][array_regexp]}
          # Ожидаем дополнительных данных
          while continue
            @connection.waitfor("Match" => @options[:end_report_regexp], 'Timeout' => timeout_waitfor) do |temp_data|
              @answer[:data] << temp_data
              # Определяем требуется ли дополнительное ожидание в ответ на команду
              @options[:array_continue_regexp].each {|array_regexp| continue = true if temp_data[array_regexp]}
              if block_given?
                yield(temp_data)
              end
            end
            @options[:array_end_continue_regexp].each {|array_regexp| continue = false if @answer[:data][array_regexp]}
          end
        rescue Errno::ECONNABORTED  # Telnet соединение сброшено
          close
          @answer[:error] = Errno::ECONNABORTED
        rescue Errno::ECONNRESET  # Удаленный хост принудительно разорвал существующее подключение.
          close
          @answer[:error] = Errno::ECONNRESET
        rescue => err      # Остальные ошибки
          @answer[:error] = err
        else
          @answer[:connection_integrity] = true
        end
      end
    rescue Timeout::Error      # Истекло время ожидания данных. Превышено значение Timeout.
      @answer[:error] = Timeout::Error
    end

    # Поиск сообщений о ошибочности выполнения команды
    @options[:retcode_err_regexp].each do |array_regexp|
      @answer[:successful] = false if @answer[:data][array_regexp]
    end   

    @answer[:time] = Time.new - @answer[:start_time] # время выполнения команды на станции
    @answer
  end

end

class ConnectionTelnet
  #  @@options = Hash.new
  #  # Создание методов класса
  #	class << self
  #    def options(key, value)
  #      @@options.store(key, value)
  #    end
  #  end
  

  attr_reader :answer, :options

  def initialize(options)
    @options = Hash.new
    @options = options
    @options[:waittime] = 0.5 unless @options.has_key?(:waittime)    
    @connect = false   # Состояние telnet подключения
    @login = false     # Авторизация на устройстве
  end

  def options_add(key, value)
    @options.store(key, value)
  end

  # Проверка обязательных параметров
  def verification
    raise ArgumentError.new("There is no option :host") unless @options.has_key?(:host)
    raise ArgumentError.new("There is no option :username") unless @options.has_key?(:username)
    raise ArgumentError.new("There is no option :password") unless @options.has_key?(:password)    
    raise ArgumentError.new("There is no option :port") unless @options.has_key?(:port)
  end

  # Открытие telnet подключения
  def connect
    @answer = Answer.new  # Данные выполнения команды на станции
    verification # Проверка обязательных параметров
    begin
      @connection = Net::Telnet::new("Host"  => @options[:host],
        "Port"  => @options[:port],
        "Prompt"     => @options[:end_report_regexp], # Признак окончания вывода ответа на команду
        "Waittime" => @options[:waittime],
        "Output_log" => File.join(WORK_DIR, "output_#{@options[:name]}_#{Time.now.strftime("%Y_%m_%d_%H_%M_%S")}.log"))
        #"Dump_log"   => "dump_log")
      #rescue Errno::EHOSTUNREACH # Сделана попытка выполнить операцию на сокете для недоступного хоста
    rescue => err
      raise err #return false
    else
      @connect = true
      return true
    end
  end

  # Запрос состояние telnet подключения
  def connect?
    @connect
  end

  # Запрос авторизации на объекте
  def login?
    @login
  end

  # Закрытие telnet подключения
  def close
    @connect = false
    @login = false
    if @connection
      @connection.close unless @connection.sock.closed? # Если соединение уже не закрыто, то закрываем
    end
  end
# !!!!!!!!!!!!!!!!!!!!!!!!!
# !!!!!!!!!!!!!!!!!!!!!!!!!
# !!!!!!!!!!!!!!!!!!!!!!!!!
  # Отправка команды без ожидания ответа
  def __puts(command)
    sleep 0.5
    @connection.puts(command)
  end

  # Ожидание данных
  # _match Признак окончания вывода данных со станции
  def wait(_match = @options[:end_report_regexp])
    @answer = Answer.new(nil, Time.new, '', false, [], nil, false, nil)
    begin      
      @connection.waitfor("Match" => _match,
        "Timeout" => false,
        "FailEOF" => true){ |temp_data| @answer[:data] << temp_data }
      @answer[:successful] = true
      @answer[:connection_integrity] = true      
    rescue => err
      puts err
      puts "280"
      
      @answer[:error] = err
      close
      raise err      
    end
    @answer[:time] = Time.new - @answer[:start_time] # время выполнения команды на станции
    @answer
  end

  #  def add_options(key, value)
  #    @options.store(key, value)
  #  end

end


class ConnectionTelnet_UA5000 < ConnectionTelnet
  include ConsoleNotConfirmation

  def initialize(options)
    super(options)

    # Признаки ошибочной команды
    @options[:retcode_err_regexp] = [/% Unknown command, the error locates at/, /Failure: /]
    # Признаки длительного ожидания ответа на ранее данную команду
    @options[:array_continue_regexp] = [/Please wait....../]
    # Приглашение к вводу имени пользователя при авторизации
    @options[:login_prompt] = /User name.*[: ]*\z/n
    # Приглашение к вводу пароля при авторизации
    @options[:password_prompt] = /User password.*[: ]*\z/n
    # Признак окончания вывода ответа на команду
    @options[:end_report_regexp] = /[#>]\z/n
    # Приглашение к вводу команд. Определим после авторизации
    @options[:prompt] = nil

    @options[:port] = 23
  end
end

# Коммутаторы
class ConnectionTelnet_Switch < ConnectionTelnet
  include ConsoleNotConfirmation

  def initialize(options)
    super(options)

    # Признаки ошибочной команды
    @options[:retcode_err_regexp] = [/Error: Unrecognized command found at /,
      /Error: Wrong parameter found at /,
      /Error:Incomplete command found at /]
    # Признаки длительного ожидания ответа на ранее данную команду
    @options[:array_continue_regexp] = [/Please wait....../] # ???
    # Приглашение к вводу имени пользователя при авторизации
    @options[:login_prompt] = /Username:\z/n
    # Приглашение к вводу пароля при авторизации
    @options[:password_prompt] = /Password:\z/n
    # Признак окончания вывода ответа на команду
    @options[:end_report_regexp] = /[#>]\z/n
    # Приглашение к вводу команд. Определим после авторизации
    @options[:prompt] = nil

    @options[:port] = 23
  end

  # Определение приглашения командной строки
  def invitation(str)   
    array_host_name = /^<\S+>/.match(str)    
    return array_host_name[0].delete!("<").chop!
  end
end

class ConnectionTelnet_SoftX < ConnectionTelnet
  include ConsoleConfirmation
  def initialize(options)
    super(options)
    @options[:end_report_regexp]     = /^\---    END/
    @options[:retcode_regexp]        = /RETCODE = \d+  .+/
    @options[:retcode0_regexp]       = /RETCODE = 0/
    @options[:array_continue_regexp] = [/More report continuing .../, /Task is started, please wait .../]
    @options[:array_end_continue_regexp]  = [/report[(s)]* in total/]

     @options[:end_report_alarm] =@options[:end_report_regexp]
    @options[:port] = 6000 unless @options.has_key?(:port) # Telnet порт для подключения
  end
end

class ConnectionTelnet_CC08 < ConnectionTelnet
  include ConsoleConfirmation
  def initialize(options)
    super(options)
    @options[:end_report_regexp]     = /^\---    END/
    @options[:retcode_regexp]        = /RETCODE = \d+  .+/
    @options[:retcode0_regexp]       = /RETCODE = 0/
    @options[:array_continue_regexp] = [/More report continuing .../, /Task is started, please wait .../]
    @options[:array_end_continue_regexp]  = [/report[(s)]* in total/]

     @options[:end_report_alarm] =@options[:end_report_regexp]

    @options[:port] = 6000 unless @options.has_key?(:port) # Telnet порт для подключения
  end
  
  # Авторизация
  def login
    super
    cmd("SET CWSON: SWT=OFF;")
    @login
  end
end





# Станции Neax С (ОПТС-275).
class ConnectionTelnet_NeaxE < ConnectionTelnet
  include ConsoleNotConfirmation

  def initialize(options)
    super(options)
    # Приглашение к вводу имени пользователя при авторизации
    @options[:login_prompt] = /User name.*[: ]*\z/n
    # Приглашение к вводу пароля при авторизации
    @options[:password_prompt] = /Password.*[: ]*\z/n
    # Признаки ошибочной авторизаци
    @options[:login_err_regexp] = /Password  Invalid/
    # Признак окончания вывода ответа на команду
    @options[:end_report_regexp]     = /\n/

    @options[:end_report_alarm] =@options[:end_report_regexp]

    @options[:port] = 5017  unless @options.has_key?(:port) # Telnet порт для подключения 
  end

 # Авторизация по запросу имени пользователя и пароля
  def login    
    sleep 0.5
    @answer = Answer.new("login", Time.new, '', false, nil, nil, false, nil) 
    begin
      timeout(4) {
        @connection.login("Name" => @options[:username],
          "LoginPrompt" => @options[:login_prompt],
          "Password" => @options[:password],
          "PasswordPrompt" => @options[:password_prompt]){|recvdata| @answer[:data] << recvdata if recvdata}
      }      
      # Проверяем успешность соединения путём сравнения с шаблоном 
      # не правильной авторизации      
      @answer[:time] = Time.new - @answer[:start_time]
      unless @answer[:data] =~ @options[:login_err_regexp] 
        @login = true
        @answer[:successful] = true
      else
        @login = false
        @connect = false
        @answer[:successful] = false
      end
      @answer[:connection_integrity] = true
    rescue Timeout::Error  # Превышен интервал ожидания авторизации     
      @answer[:error] = 'Timeout'
      @answer[:time] = Time.new - @answer[:start_time]
      @connect = false
      @login = false
    end    
  end  
  
  
end

# Станции Neax Sigma (ОПТС-255).
class ConnectionTelnet_NeaxSigma < ConnectionTelnet
  include ConsoleNotConfirmation
    
  

  
  def initialize(options)
    super(options)
    # Приглашение к вводу имени пользователя при авторизации
    @options[:login_prompt] = /login:.*[: ]*\z/n
    # Приглашение к вводу пароля при авторизации
    @options[:password_prompt] = /Password:.*[: ]*\z/n
    # Признаки ошибочной авторизаци
    @options[:login_err_regexp] = /ERROR: Login incorrect/
    # Признак окончания вывода ответа на команду
    @options[:end_report_regexp]     = /#{@options[:username]} >(?!\w+)/
    # Приглашение командной строки
    @options[:prompt] = "#{@options[:username]} >"

    @options[:end_report_alarm] = /\n^ {11}\n/

    @options[:retcode_err_regexp] = [/err-/, /operation code incorrect/]
    @options[:array_continue_regexp] = [/st_tst=str/]
    @options[:port] = 23
  end

end


class ConnectionTelnet_IMS < ConnectionTelnet
  include ConsoleConfirmation
  def initialize(options)
    super(options)
    @options[:end_report_regexp]     = /^\---    END/
    @options[:retcode_regexp]        = /RETCODE = \d+  .+/
    @options[:retcode0_regexp]       = /RETCODE = 0/
    @options[:array_continue_regexp] = [/More report continuing .../, /Task is started, please wait .../]
    @options[:array_end_continue_regexp]  = [/report[(s)]* in total/]

    @options[:port] = 6000 unless @options.has_key?(:port) # Telnet порт для подключения
  end
end



#ats = ConnectionTelnet_NeaxSigma.new(:name => 'opts250', :host => '10.132.50.1', :username => 'swsh', :password => 'swsh123')
#p ats
#puts ats.connect

#puts ats.login
#p ats.answer
#ats.cmd("reg amc almsg=1159008 def=mat"){|qq| puts qq}
#p ats.answer
#loop do
#       puts @tmp_data = ats.wait(ats.options[:end_report_alarm])[:data] # Ожидание данных со станции
#       caller = ats.finding_caller @tmp_data
 #      called = ats.finding_called @tmp_data
 #      puts "caller = #{caller}"
  #     puts "called = #{called}"
#
#end















#class ConnectionTelnet_SoftX < ConnectionTelnet
#  @options[:alarm_malicious_regexp] = [/Event  Warning     Exchange  903     Software/]
#end
#
#class ConnectionTelnet_CC08 < ConnectionTelnet
#  @options[:alarm_malicious_regexp] = [/Warning alarm    Exchange  481     Software system/,
#    /Warning alarm    Exchange  523     Software system/]
#end
