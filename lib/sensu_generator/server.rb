require 'json'
require 'socket'

module SensuGenerator
  class Server
    attr_reader :logger, :config

    def initialize
      @config  = Application.config
      @logger  = Application.logger
      @trigger = Application.trigger
      logger.info "Server: starting server."
      listen_and_serve
    end

    def listen_and_serve
      @server = TCPServer.new(server_addr, server_port)
      logger.info "Server: started server on #{@server.addr}"

      while client = @server.accept
        logger.info "Server: client #{client.addr} connected"
        Thread.start(client) do
          begin
            data = client.read
            process data
            client.close
          rescue => e
            client&.close
            raise ServerError, "Server: error occured #{e.inspect} #{e.backtrace}\n"
          end
        end
      end
    rescue
      close
    end

    def close
      @server.close
      @server = nil
    end

    private

    def process(data)
      hash = JSON.parse data

      if hash.key? 'FLUSH_WITH_PREFIX'
        logger.info "Server: removing files with prefix #{hash['FLUSH_WITH_PREFIX']}"
        CheckFile.remove_all_with(hash['FLUSH_WITH_PREFIX'])
      elsif hash.key? 'filename'
        filename = hash['filename']
        data     = JSON.pretty_generate hash['data']

        logger.info "Server: received file #{filename}"
        CheckFile.new(filename).write(data)
      end
    rescue
      logger.info "Server: not json data received. Ignoring."
    end

    def server_port
      @server_port ||= config.get[:server][:port]
    end

    def server_addr
      @server_addr ||= config.get[:server][:addr]
    end
  end
end
