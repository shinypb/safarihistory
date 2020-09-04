#!/usr/bin/env swift
import Foundation

let SQLITE_SEPARATOR: Character = "|"
let SAFARI_HISTORY_FILENAME = "/Users/mark/Library/Safari/History.db"
let SAFARI_TIMESTAMP_EPOCH = 978307200

func runCommand(cmd: String, args: String...) -> (output: [String], error: [String], exitCode: Int32) {
	// this function is from https://stackoverflow.com/a/29519615

	var output : [String] = []
	var error : [String] = []

	let task = Process()
	task.launchPath = cmd
	task.arguments = args

	let outpipe = Pipe()
	task.standardOutput = outpipe
	let errpipe = Pipe()
	task.standardError = errpipe

	task.launch()

	let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
	if var string = String(data: outdata, encoding: .utf8) {
		string = string.trimmingCharacters(in: .newlines)
		output = string.components(separatedBy: "\n")
	}

	let errdata = errpipe.fileHandleForReading.readDataToEndOfFile()
	if var string = String(data: errdata, encoding: .utf8) {
		string = string.trimmingCharacters(in: .newlines)
		error = string.components(separatedBy: "\n")
	}

	task.waitUntilExit()
	let status = task.terminationStatus

	return (output, error, status)
}

func query(sql: String) -> [[String]] {
	let lines = runCommand(cmd: "/usr/bin/sqlite3", args: "-readonly", SAFARI_HISTORY_FILENAME, sql).output
	return lines.map { $0.split(separator: SQLITE_SEPARATOR).map { String($0) } }
}

func main() -> Void {
	if (CommandLine.arguments.count < 2) {
		print("usage: safarihistory <timestamp>")
		print("")
		print("Prints a list of all of the URLs that have been visited since the given timestamp,")
		print("one per line. Even if a given URL was visited more than one time, it will only be")
		print("included once.")
		print("")
		print("Timestamp can either be a Unix timestamp (e.g. 1599238860) or a Safari history")
		print("item timestamp (e.g. 620931660). Safari history item timestamps are the number")
		print("of seconds since January 1, 2001 (UTC).")
		print("")
		exit(1)
	}

	if var sinceTimestamp = Int(CommandLine.arguments[1]) {
		if (sinceTimestamp > SAFARI_TIMESTAMP_EPOCH) {
			// User passed in a real Unix timestamp; turn it into a Safari history timestamp
			sinceTimestamp -= SAFARI_TIMESTAMP_EPOCH
		}
		let historyItemIds = query(sql: "select distinct(history_item) from history_visits where visit_time > \(sinceTimestamp) order by visit_time desc;").map { $0.first! }
		let historyItemIdsJoined = historyItemIds.joined(separator: ",")
		let urls = query(sql: "select url from history_items where id in (\(historyItemIdsJoined))").map { $0.first! }
		print(urls.joined(separator: "\n"))
	} else {
		print("Invalid timestamp; expected a Unix timestamp (e.g. 1599235434) or a Safari history item timestamp (e.g. 620928234).")
		exit(1)
	}
}

main()
