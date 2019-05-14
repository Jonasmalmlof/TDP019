require './libs/rdparse.rb'
require './libs/nodes.rb'
require './libs/parser.rb'


if !ARGV.empty?

  flag = ARGV.first.delete('-')
  EPParser.new.compile(ARGV[1]) if flag == 'f'
elsif $PROGRAM_NAME.include? 'EasyProgramming.rb'
  puts "EasyProgramming help:
  Flags:
    -f <filename> Runs the code in a file.
    -v Prints the version"
end
