# swift-source-kit

Source code helpers for Apple's `Swift` language.

## swift-make-all-public

Make everything public. Usage:

```
Usage: swift-make-all-public.rb [options]
    -i, --input-filename=NAME        Input filename
    -n, --not-replace                Input filename
    -h, --help                       Prints this help
```

The concept is quite simple:

```
if line =~ /^(?!\/(\/|\*))(\s)*((struct|class|static|protocol|extension|func|mutating|subscript|@IBOutlet|@IBAction|override|enum)(\s)+(?!public)|(var)(\s)+(?!public).*{)/
	s = line.strip.sub('@IBAction', '').sub('@IBOutlet', '').strip
	s = line.sub(s, 'public ' + s)
	...
```

TODO:

- add scope check for classes and protocols
- Make class variables public
- Don't make protocol functions public