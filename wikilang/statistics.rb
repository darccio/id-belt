#!/usr/bin/env ruby

require 'pp'

def check_and_add(value)
  value.nil? ? 1 : value + 1
end

langs = {}
langs_by_continent = {}
current = nil
ARGF.readlines.each do |line|
  line.downcase!
  if line =~ /^    /
    line.strip!
    langs[line] = check_and_add langs[line]
    langs_by_continent[current] = {} if langs_by_continent[current].nil?
    langs_by_continent[current][line] = check_and_add langs_by_continent[current][line]
  else
    country = line.strip.gsub(')', '').split(' (')
    current = country[1]
  end
end

langs = langs.sort_by { |key, value| value }
langs_by_continent.each do |key, value|
  langs_by_continent[key] = value.sort_by { |k, v| v }
end
pp langs
pp langs_by_continent
