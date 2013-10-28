$verbose = false

def error(msg)
	puts "Error: #{msg}"
	exit
end

def verbose_msg(msg)
	puts msg if $verbose
end