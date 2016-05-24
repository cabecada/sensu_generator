#!/usr/bin/env ruby
require 'sensu_generator'
require 'optparse'
require 'daemons'

module SensuGenerator
  class << self
    def parse_args!
      args = ARGV.dup

      # get elements after '--' because of Daemons
      args = args[(args.index('--')+1)..-1] if args.include? ('--')
      config = nil
      optparse = OptionParser.new do |opts|
                  opts.banner = "sensu-generator run|start|stop|status -- [options]"

                  opts.on("-c", "--config File", String, "Path to config file") do |item|
                    config = item
                  end
                  opts.on_tail("--version", "Show version") do
                    puts VERSION
                    exit
                  end

                  opts.on_tail("-h", "--help", "Show this message") do
                    puts opts
                    exit
                  end
                end

      optparse.parse!(args)
      File.expand_path config
    end

    def run(config_file)
      config       = Config.new(config_file)
      logger       = Logger.new(config.get[:logger])
      logger.level = eval("Logger::#{config.get[:logger][:log_level].upcase}")
      notifier     = Notifier.new(config.get[:slack])

      Application.new(config: config, logger: logger, notifier: notifier).run
    # rescue => exception
    #   msg = %("Sensu_generator exited with non-zero code.\n #{exception.backtrace.join("\n\t")}")
    #   Logger.new(file: STDOUT).fatal msg
    end
  end
end

config = SensuGenerator::parse_args!

Daemons.run_proc(__FILE__) do
  SensuGenerator::run(config)
end
