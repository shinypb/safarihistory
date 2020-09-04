#!/usr/bin/ruby
require 'shellwords'

SAFARI_HISTORY_FILENAME = File.join(ENV['HOME'], "Library/Safari/History.db")
SAFARI_TIMESTAMP_EPOCH = 978307200;
SQLITE_COLUMN_SEPARATOR = '|'

def query(sql)
	lines = `sqlite3 -readonly #{SAFARI_HISTORY_FILENAME.shellescape} #{sql.shellescape}`.strip.split("\n")

	lines.map do |line|
		line.split(SQLITE_COLUMN_SEPARATOR)
	end
end

def main
	if ARGV.empty?
		puts "usage: safarihistory <timestamp>"
		puts ""
		puts "Prints a list of all of the URLs that have been visited since the given timestamp,"
		puts "one per line. Even if a given URL was visited more than one time, it will only be"
		puts "included once."
		puts ""
		puts "Timestamp can either be a Unix timestamp (e.g. 1599238860) or a Safari history"
		puts "item timestamp (e.g. 620931660). Safari history item timestamps are the number"
		puts "of seconds since January 1, 2001 (UTC)."
		puts ""
		abort
	end

	since_timestamp = ARGV[0].to_i
	if since_timestamp > SAFARI_TIMESTAMP_EPOCH
		# User passed in a real Unix timestamp; turn it into a Safari history timestamp
		since_timestamp -= SAFARI_TIMESTAMP_EPOCH
	end

	history_item_ids = query("select distinct(history_item) from history_visits where visit_time > #{since_timestamp} order by visit_time desc;").map(&:first)
	urls = query("select url from history_items where id in (#{history_item_ids.join(',')})").map(&:first)
	puts urls.join("\n")
end

main
