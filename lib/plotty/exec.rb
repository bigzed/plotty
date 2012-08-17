require File.join(File.dirname(__FILE__), "options")
require File.join(File.dirname(__FILE__), "data")
require File.join(File.dirname(__FILE__), "database/sqlite")
require File.join(File.dirname(__FILE__), "database/mysql")
require 'gnuplot'
require 'yaml'

module Plotty
  module Exec
    def self.run!(argv)
      options = Plotty::Options.parse!(argv)

      # Load yaml file in config
      config = YAML.load_file(options[:config])
      # For each seaction in your config, parse the datafile
      # and generate every plot which is specified.
      config.each do |key,value|
        # create empty array for diagrams
        diagrams = []

        # Iterate over each diagram
        (value.size - 3).times do |i|
          diagram_name = "diagram#{i}"
          # Create dataset from data and select 2 values, sort by one 
          # of the asc
          # Check which database adapter we need and instantiate it accordingly
          db = value["adapter"] == sqlite ? 
            Plotty::Sqlite.new(value["data"]) : Plotty::Mysql.new
          data_set = db.create_dataset(value[diagram_name]["query"])
          plot_file = "plot" + i.to_s
          diagram_file = "diagram" + i.to_s + ".pdf"
          create_plot_file(plot_file, data_set, diagram_file, value[diagram_name])
          `gnuplot #{plot_file}`
          diagrams << diagram_file
        end

        # Write it to file!
        content = write_to_tex(options[:template],diagrams,value["doc_title"])
        File.open("#{key}_#{options[:output]}","w").write(content)
      end
    end

    private 
      def self.write_to_tex(template,diagrams,title)
        out = diagrams.map { |d| "\\includegraphics{#{d}}"}.join("\n \n")
        template = File.open(template,"r").read
        template.gsub!(/!!title!!/, title)
        template.gsub!(/!!diagrams!!/, out)
        template
      end

      # Copied from Jannis Ihrig former version of plotty
      def self.create_plot_file(plot_file, data_set, diagram_file, diagram_meta)
        File.open(plot_file, "w") do |gp|
          Gnuplot::Plot.new( gp ) do |plot|
            labels = data_set[0]
            cols = data_set[1]

            plot.output diagram_file
            plot.set("terminal", value = "pdfcairo")
            plot.title  diagram_meta["title"]
            plot.xlabel diagram_meta["xlabel"]
            plot.ylabel diagram_meta["ylabel"]
            plot.yrange diagram_meta["yrange"] if diagram_meta["yrange"] != nil

            
            plot.data = Array.new

            (cols.size-1).times do |i|
              plot.data[i] =
                Gnuplot::DataSet.new( [cols[0], cols[i+1]] ) do |ds|
                  ds.with = diagram_meta["style"] != nil ? diagram_meta["style"] : "lines"
                  ds.title = labels[i+1]
                end
            end
          end
        end
      end
  end
end