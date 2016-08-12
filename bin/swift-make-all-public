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
		scope = ''
		is_commented = false
		bracket = 0
		File.open(filename, 'rb').each do |line|
			# puts scope
			# struct, class, static, protocol, or extension starts with whitespaces, without // or /* in front
			# 	struct/class/extension definition
			# 	static/class var/func

			is_commented = (line.include? '/*') if !is_commented
			is_commented = !(line.include? '*/') if is_commented
			line_without_comment = line
			line_without_comment = line.slice(0..line.index('//')) if line.include? '//'
			if (line.include? '/*') && (line.include? '*/')
				line_without_comment = line.slice(line.index('/*')..line.index('*/'))
			elsif line.include? '/*'
				line_without_comment = line.slice(0..line.index('/*'))
			elsif line.include? '*/'
				line_without_comment = line.slice(line.index('*/')..-1)
			end

			if is_commented
				file.puts line
				next
			end

			# detect scope
			if line =~ /^((\s)*public(\s)+)?class/
				scope = 'class'
			elsif line =~ /^((\s)*public(\s)+)?protocol/
				scope = 'protocol'
			end
			if line =~ /^(?!\/(\/|\*))(\s)*/
				bracket += line.scan('{').length
				bracket -= line.scan('}').length
			end
			scope = '' if bracket == 0
			# puts scope
			# puts bracket

			regex = '^(?!\/(\/|\*))(\s)*((struct|class|static|protocol|extension|func|mutating|subscript|@IBOutlet|@IBAction|override|enum|required)(\s)+(?!public)|(var)(\s)+(?!public).*{'
			# regex = '^(?!\/(\/|\*))(\s)*((struct|class|static|protocol|extension|func|mutating|subscript|@IBOutlet|@IBAction|override|enum|required)(\s)+(?!public)'
			if scope == 'protocol'
				regex = '^(\s)*protocol(\s)+(?!public)'
			elsif scope == 'class' && bracket == 1
				regex += '|(var|let)(\s)+(?!public))'
			else
				regex += ')'
			end
			regex = /#{regex}/
			# puts regex

			if line_without_comment =~ regex
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