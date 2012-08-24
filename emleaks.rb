require 'eventmachine'
require 'set'

if ARGV[0] == 'patch_em'
  puts 'Patching EM...'
  module EventMachine
    def self.injected_event_callback conn_binding, opcode, data # :nodoc:
      if opcode == ConnectionUnbound
        puts 'ConnectionUnbound'
        if c = @conns.delete( conn_binding )
          begin
            c.unbind
          rescue
            @wrapped_exception = $!
            stop
          end
        elsif c = @acceptors.delete( conn_binding )
          # no-op
        else
          raise ConnectionNotBound, "recieved ConnectionUnbound for an unknown signature: #{conn_binding}"
        end
        c = nil
        GC.start
      else
        self.original_event_callback conn_binding, opcode, data
      end
      nil
    end
  end

  class << EventMachine
    alias_method :original_event_callback, :event_callback
    alias_method :event_callback, :injected_event_callback
  end
end

class OuroborosFromOuterSpace
  def initialize
    @previous = {}
    @total_previous = 0
  end

  def collect
    GC.start
    current = {}
    total = 0
    ObjectSpace.each_object do |object|
      current[object.class] = current[object.class].to_i + 1
      total += 1
    end
    unless @previous.empty?
      keys = Set.new current.keys
      keys.merge @previous.keys
      puts "[keys => #{keys.size}, total => #{total}, total_diff => #{total - @total_diff}]"
      keys.each do |key|
        diff = current[key].to_i - @previous[key].to_i
        # In Rubinius there is a second "leak" from OuroborosFromOuterSpace keys set. Not a big deal, it is controlled by GC.
        puts "#{key} => #{current[key].to_i} (#{diff > 0 ? '+' : nil}#{diff})" if diff > 0 or key == EventMachine::Connection or key == String
      end
      puts "---"
      keys.clear; keys = nil
      @previous.clear; @previous = nil
    end
    @total_diff = total
    @previous = current
  end
end

class RequestHandler < EM::Connection
  # We minimize the creation of objects caching all what we need at class level.
  @@data = 'Hello World!'
  @@http_response = "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: #{@@data.size}\r\n\r\n#{@@data}"
  @@size = @@http_response.size
  @@ofos = OuroborosFromOuterSpace.new

  def receive_data(data)
    EventMachine::send_data @signature, @@http_response, @@size
    @@ofos.collect
    close_connection_after_writing
  end
end

EM.run { EM.start_server '127.0.0.1', 3000, RequestHandler }
