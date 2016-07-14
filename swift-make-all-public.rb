#!/usr/bin/ruby

require 'optparse'

filename = ''
replace = true
options = OptionParser.new do |opts|
	opts.banner = "Usage: swift-make-all-public.rb [options]"

	opts.on("-i", "--input-filename=NAME", "Input filename") do |name|
		filename = name
	end
	opts.on("-n", "--not-replace", "Input filename") do |name|
		replace = false
	end
	opts.on("-h", "--help", "Prints this help") do
		puts opts
		exit
	end
end

options.parse!
if filename == ''
	puts "Missing filename.\n---\n"
	puts options
	exit
end

# filename = "/Users/leo/prj/ios/LFramework2/Pod/Classes/LFoundation/LFoundation.swift"
# s = IO.read("/Users/leo/prj/ios/LFramework2/Pod/Classes/LFoundation/LFoundation.swift")
# puts s

def swift_make_all_public(filename, replace)
	File.open('temp.swift', 'w') do |file|
		File.open(filename, 'rb').each do |line|
			# struct, class, static, protocol, or extension starts with whitespaces, without // or /* in front
			# 	struct/class/extension definition
			# 	static/class var/func
			if line =~ /^(?!\/(\/|\*))(\s)*((struct|class|static|protocol|extension|func|mutating|subscript|@IBOutlet|@IBAction|override|enum)(\s)+(?!public)|(var)(\s)+(?!public).*{)/
				# puts line
				s = line.strip.sub('@IBAction', '').sub('@IBOutlet', '').strip
				s = line.sub(s, 'public ' + s)
				file.puts s
			else
				file.puts line
			end
		end
	end
	`mv temp.swift #{filename}` if replace
end

if filename[-1] == ?/
	filenames = Dir["#{filename}/**/*.swift"]
	puts "Processing '#{filenames}'..."
	filenames.each do |name|
		swift_make_all_public(name, replace)
	end
else
	puts "Processing '#{filename}'..."
	swift_make_all_public(filename, replace)
end