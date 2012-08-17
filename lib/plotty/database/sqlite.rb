require 'sqlite3'

module Plotty
  class Sqlite
    def initialize(db_name)
      @db_name = db_name
    end

    def get_dataset(query)
        #fetch from db
        puts "Fetching data from #{db_name}.."
        db = SQLite3::Database.new( db_name )
        rows = db.execute2(query)
        puts "Done."

        labels = []
        cols = nil


        rows.each_with_index do |row, row_idx|
          if row_idx == 0
            cols = Array.new(row.size).map{|i| i = []}
            labels = row
          else
            row.each_with_index{|value, col_idx| cols[col_idx][row_idx] = value}
          end
        end
        return [labels, cols]
      end
  end
end