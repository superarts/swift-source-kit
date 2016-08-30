#!/usr/bin/ruby

require 'optparse'
require 'set'

filename = ''
destname = ''
options = OptionParser.new do |opts|
	opts.banner = "Usage: swift-make-all-public.rb [options]"

	opts.on("-i", "--input-filename=NAME", "Input filename") do |name|
		filename = name
	end
	opts.on("-o", "--output-filename=DESTNAME", "Output filename") do |name|
		destname = name
	end
	opts.on("-h", "--help", "Prints this help") do
		puts opts
		exit
	end
end

options.parse!
if filename == '' || destname == ''
	puts "Missing input or output filename.\n---\n"
	puts options
	exit
end

# filename = "/Users/leo/prj/ios/LFramework2/Pod/Classes/LFoundation/LFoundation.swift"
# s = IO.read("/Users/leo/prj/ios/LFramework2/Pod/Classes/LFoundation/LFoundation.swift")
# puts s

def swift_wrap_underscore(filename)
	File.open('temp.swift', 'a') do |file|
		file.puts "// #{filename} {"
		scope = ''
		is_commented = false
		bracket = 0
		bracket_last = 0
		name_class = ''
		symbols = []
		classes = Set.new
		File.open(filename, 'rb').each do |line|
			# puts scope
			# struct, class, static, protocol, or extension starts with whitespaces, without // or /* in front
			# 	struct/class/extension definition
			# 	static/class var/func

			is_commented = (line.include? '/*') if !is_commented
			is_commented = !(line.include? '*/') if is_commented
			line_without_comment = line
			line_without_comment = line.slice(0 .. line.index('//') - 1) if line.include? '//'
			if (line.include? '/*') && (line.include? '*/')
				line_without_comment = line.slice(line.index('/*')..line.index('*/'))
			elsif line.include? '/*'
				line_without_comment = line.slice(0..line.index('/*'))
			elsif line.include? '*/'
				line_without_comment = line.slice(line.index('*/')..-1)
			end

			if is_commented
				# file.puts line
				next
			end

			if line_without_comment =~ /^(?!\/(\/|\*))(\s)*/
				bracket += line_without_comment.scan('{').length
				bracket -= line_without_comment.scan('}').length
			end
			# detect scope
			if bracket == 1 
				if match = line_without_comment.match(/^((\s)*public(\s)+)?struct(\s)+(([\w\d])+)+.*/)
					scope = 'struct'
					name_class = match.captures[4]
				elsif match = line_without_comment.match(/^((\s)*public(\s)+)?class(\s)+(([\w\d])+)+.*/)
					scope = 'class'
					name_class = match.captures[4]
				elsif match = line_without_comment.match(/^((\s)*public(\s)+)?protocol(\s)+(([\w\d])+)+.*/)
					scope = 'protocol'
					name_class = match.captures[4]
				elsif match = line_without_comment.match(/^((\s)*public(\s)+)?extension(\s)+(([\w\d])+)+.*/)
					scope = 'extension'
					name_class = match.captures[4]
				end
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

			if line_without_comment =~ regex && bracket_last == 1
				s = line.strip.sub('@IBAction', '').sub('@IBOutlet', '').strip
				s = line.sub(s, 'public ' + s)
				# file.puts s
			else
				# file.puts line
			end

			if bracket_last == 1 && (line_without_comment.include? '_')
				puts bracket.to_s + " " + name_class + " " + scope + " " + line_without_comment
				classes.add(name_class)
				symbols << {
					parent: name_class,
					scope: scope,
					line: line_without_comment
				}
			end
			#	puts bracket.to_s + " " + name_class + " " + scope + " " + line_without_comment

			bracket_last = bracket
		end
		puts classes.to_a
		puts symbols
		classes.each do |class_name|
			puts class_name
			file.puts "extension #{class_name} {"
			symbols.each do |symbol|
				if symbol[:parent] == class_name
					puts symbol
					if symbol[:scope] == 'class'
						# public var name_1: Type = value
						if match_var = symbol[:line].match(/(public\s+.*\s*var\s+(?!_)([\w\d_]+))/)
							next if !match_var.captures[1].include? '_'
							type = 'XXX'
							if match = symbol[:line].match(/(public\s+.*\s*var\s+(?!_)([\w\d_]+))(:.*)(=.*)/)
								# p match.captures
								type = match.captures[2]
							elsif match = symbol[:line].match(/(public\s+.*\s*var\s+(?!_)([\w\d_]+))(:.*)/)
								# p match.captures
								type = match.captures[2]
							elsif match = symbol[:line].match(/(public\s+.*\s*var\s+(?!_)([\w\d_]+))\s*(=.*)/)
								# p match.captures
								type = match.captures[2]
								type = ': Bool' if (type.include? 'false') || (type.include? 'true')
								type = ': Int' if (type.include? '= 0') || (type.include? '= -1')
							end
							type += ' {' if !type.include? '{'
							name = match_var.captures[1].split('_').map(&:capitalize).join('_').gsub('_', '')
							name[0] = name[0].chr.downcase
							s = match_var.captures[0].sub(match_var.captures[1], name)
							s = "\t#{s}#{type}\n"\
								"\t\tget {\n"\
								"\t\t\treturn #{match_var.captures[1]}\n"\
								"\t\t}\n"\
								"\t\tset(v) {\n"\
								"\t\t\t#{match_var.captures[1]} = v\n"\
								"\t\t}\n"\
								"\t}\n"
							puts s
							file.puts s
						# public func name_1(name: Type) -> Type
						elsif match_func = symbol[:line].match(/(public\s+.*\s*func\s+(?!_)([\w\d_]+))\((.*)\)((\s*->\s?(.+)|))/)
							next if !match_func.captures[1].include? '_'
							# puts '--- func: ' + symbol[:line]
							# p match_func.captures
							param = ''
							match_func.captures[2].split(',').each_with_index do |parameters, index|
								if match_param = parameters.match(/(([\w\d_]+)\s+)?([\w\d_]+):(.*)/)
									# p match_param.captures
									if index == 0
										if match_param.captures[0] == nil
											param += "#{match_param.captures[2]}, "
										elsif match_param.captures[0] == '_'
											param += "#{match_param.captures[2]}: #{match_param.captures[2]}, "
										else
											param += "#{match_param.captures[0]}: #{match_param.captures[2]}, "
										end
									else
										if match_param.captures[0] == nil
											param += "#{match_param.captures[2]}: #{match_param.captures[2]}, "
										else
											param += "#{match_param.captures[0]}: #{match_param.captures[2]}, "
										end
									end
									# p index
									# p param
								end
							end
							param = param[0..-3] if param != ''
							# p param
							name = match_func.captures[1].split('_').map(&:capitalize).join('_').gsub('_', '')
							name[0] = name[0].chr.downcase
							s = match_func.captures[0].sub(match_func.captures[1], name)
							type = match_func.captures[3]
							ret = ''
							ret = 'return ' if type != ''
							type = ' {' if type == ''
							s = "\t#{s}(#{match_func.captures[2]})#{type}\n"\
								"\t\t#{ret}#{match_func.captures[1]}(#{param})\n"\
								"\t}\n"
							puts s
							file.puts s
						end
					end
				end
			end
			file.puts "}"
		end
	end
end

`rm temp.swift`
if filename[-1] == ?/
	filenames = Dir["#{filename}/**/*.swift"]
	puts "Processing '#{filenames}'..."
	filenames.each do |name|
		swift_wrap_underscore(name)
	end
else
	puts "Processing '#{filename}'..."
	swift_wrap_underscore(filename)
end

`mv temp.swift #{destname}`