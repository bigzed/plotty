require File.join(File.dirname(__FILE__), "options")
require File.join(File.dirname(__FILE__), "data")
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
        # Parse data into array of polygon hashes:
        # 1 -> points -> first pair
        #             -> second pair
        #      algorithm -> ...
        data = Plotty::Data.parse!(value["data"])
        # create empty array for diagrams
        diagrams = []
        (value.size - 2).times do |i|
          # Iterate over each diagram
          diagram_name = "diagram#{i}"
          # Create dataset from data and select 2 values, sort by one 
          # of the asc
          data_set = create_dataset(data,
            value[diagram_name]["first_value"],
            value[diagram_name]["second_value"],
            value[diagram_name]["order"])
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
            puts labels
            cols = data_set[1]
            #puts cols

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

      def self.create_dataset(data,first_value,second_value)
        labels = [first_value, second_value]
        rows = []
        data.each do |p|
          if second_value == "surface_area"
            rows << [p[first_value],p[second_value].to_f.abs]
          else
            rows << [p[first_value],p[second_value]]
          end
        end
        # Sort arrays by order parameter and agregate if necessary
        rows.map! { |a| [a[0].to_i,a[1].to_i] }
        rows.sort! { |a,b| a[0] <=> b[0] }
        
        # Check if we need to aggregate
        if rows[0][0] == rows[1][0]
          rows.size.times do |i|
            break if rows[i].nil?
            current = rows[i][0]
            first = rows.index{ |e| e[0] == current }
            last = rows.rindex{ |e| e[0] == current }
            new_value = [current,0]
            (last+1-first).times do |j|
              new_value[1] = new_value[1] + rows[j+i][1]
            end
            rows.delete_if { |a| a[0] == current }
            rows.unshift(new_value)
          end
        end
        rows.reverse!
        cols = Array.new(rows.size).map { |c| c = [] }
        rows.each_with_index do |row,row_id|
          row.each_with_index { |v,col_id| cols[col_id][row_id] = v.to_s }
        end
        puts "#{cols[0]}"
        return [labels, cols]
      end
  end
end