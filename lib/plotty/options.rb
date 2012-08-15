require 'optparse'

module Plotty
  module Options
    def self.parse!(argv)
      options = {}
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: plotty"
        # The normal usage/help option
        opts.on("-h","--help") do 
          puts opts
          Kernel.exit(true)
        end
        # Option to specify configfile
        opts.on("-c","--conf [config] ") do |c|
          options[:config] = c
        end
        # Option to specify latex template
        options[:template] = "template.tex"
        opts.on("-t","--template [template]" ) do |t|
          options[:template] = t
        end
        # Options to specify output
        options[:output] = "out.tex"
        opts.on("-o","--output [out]") do |o|
          options[:output] = o
        end
      end
      parser.parse!
      unless options.include?(:config)
        puts parser
        puts "\n     Please specify config file!"
        Kernel.exit(false)
      end
      options
    end
  end
end