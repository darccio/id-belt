# encoding: UTF-8
# Author:: Dario Castañé (mailto:i@dario.im)
# License:: This class is free and unemcumbered software released into the public domain. For more information, see the included UNLICENSE file.

require 'yajl'
require 'sequel'

class JsonLoader
  # Loads and parse a JSON with Hash structure ({'table_name' => [ lots of moar hashes ], 'another_table_name' => [ ... ]}). Anyway, find an example.json, based on Qomun database, in the same directory as this script.
  # Params:
  # +json+:: JSON file to load.
  # +connection_string+:: A Sequel connection string (http://sequel.rubyforge.org/rdoc/files/doc/opening_databases_rdoc.html)
  def initialize(json, connection_string)
    @db = Sequel.connect connection_string
    parser = Yajl::Parser.new
    @data = parser.parse json
    @mapping = {}
  end

  # Loads to DB a given sub-structure from the parsed JSON, based on params.
  # Params:
  # +type+:: key used in the hash, related with the final name of the table (stated in 'table').
  # +table+:: symbol used in Sequel for the destination table. Usually it is going to be :'#{type.pluralize}'. Check the examples.
  # +keys+:: Key fields to check if it already exists on destination table.
  def load(type, table, keys)
    @mapping[type] = {}
    # For each entry (one entry, one row).
    @data[type].each do |raw|
      # Removing the id helps to ease the process.
      id = raw.delete 'id'
      # Creating the filter to check if it already exists on destination table.
      filter = {}
      keys.each do |key|
        filter[key.to_sym] = raw[key]
      end
      # Gotcha!
      value = @db[table].filter(filter).first
      # Before going further, allowing the user to manipulate the raw data in a block.
      # @mapping is provided to handle special cases where field names doesn't match.
      yield raw, @mapping if block_given?
      # Replacing imported keys for new ones.
      # This is done to handle the ever changing ids (Sequel doesn't allow to force an id, as long as I know).
      raw.each_key do |key|
        if @mapping.include? key
          id_key = if raw[key].is_a? Hash
            raw[key]['id']
          else
            raw[key]
          end
          if @mapping[key].include? id_key
            raw[key] = @mapping[key][id_key]
          else
            puts "warn: unable to find matching mapping for id '#{id_key}' in '#{key}' for #{raw.inspect}."
          end
        end
      end
      # Inserting if it doesn't exist.
      value = @db[table].filter(:id => @db[table].insert(raw)).first if value.nil?
      # Keeping track of the final id in any case.
      @mapping[type][id] = value[:id]
    end
  end
end

if ARGV.size == 0
  puts 'Usage: json_loader.rb file.json'
  exit 0
end

####################################################################
# Attention: you MUST replace the connection string for your case. #
# This is an example.                                              #
####################################################################
#json_loader = JsonLoader.new File.new(ARGV[0], 'r'), 'postgres://user:password@127.0.0.1:5432/database'
#json_loader.load('via', :vias, [ 'site', 'name' ])
#json_loader.load('kind', :kinds, [ 'name' ]) do |data|
#  parent = data.delete 'parent'
#  data['kind'] = parent
#end
#json_loader.load('license', :licenses, [ 'site', 'name' ])
#json_loader.load('creator', :creators, [ 'quid' ])
#json_loader.load('qreation', :qreations, [ 'quid' ]) do |data, mapping|
#  id_key = data['parentKind']
#  if mapping['kind'].include? id_key
#    data['parentKind'] = mapping['kind'][id_key]
#  else
#    puts "warn: unable to find matching mapping for id '#{id_key}' in 'parentKind' for #{data.inspect}."
#  end
#end
