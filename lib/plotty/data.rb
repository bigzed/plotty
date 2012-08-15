require 'csv'

module Plotty
  module Data
    def self.parse!(datafile)
      unless File.exists?(datafile)
        puts "Specified data file #{datafile} doesn't exist."
        Kernel.exit(false)
      end
      csv_array = CSV.parse(File.open(datafile).read)
      # Get the description of each field in a line from the first line
      header = csv_array.delete_at(0)
      header = header.first.split(";")
      polygons = []
      csv_array.each do |l|
        polygon = {}
        data = l.first.split(";")
        data.each_with_index do |d,i|
          # If i is 0 then we now its the polygon column
          if i == 0
            polygon["points"] = []
            d.split(":").each do |pair|
              polygon["points"] << pair.split(" ")
            end
          else
            polygon[header[i]] = d
          end
        end
        polygons << polygon
      end
      polygons
    end
  end
end