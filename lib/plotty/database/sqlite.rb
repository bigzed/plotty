require 'sqlite3'
require 'fileutils'

module Plotty
  class Sqlite
    def initialize(db_name)
      @db_name = db_name
    end

    def get_dataset(query)
      #fetch from db
      row = []
      if @db_name.size == 1
        puts "Fetching data from #{@db_name.first}.."
        db = SQLite3::Database.new(@db_name.first)
        rows = db.execute2(query)
        puts "Done."
      else
        puts "Fetching data from #{@db_name}.."
        db = Plotty::Sqlite.merge(@db_name)
        rows = db.execute2(query)
        puts "Done."
      end

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

    def self.merge(databases)
      # First copy the first DB_file to not alter the existing files
      merge ="merged.db"
      # begin
      #   FileUtils.copy(databases.pop, merge)
      # rescue => err
      #   raise "Database file doesn't exist. #{err}"
      # end
      puts "Created new merge Database."
      db = SQLite3::Database.new(merge)
      databases.each_with_index do |path,i|
        puts "Mergin #{path}..."
        db.execute "attach \"#{path}\" as #{File.basename(path,'.db')};"
        puts "Done..."
      end
      db
    end
  end
end