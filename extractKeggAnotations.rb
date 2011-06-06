#!/usr/bin/env ruby 

# == Synopsis 
#   This is a sample description of the application.
#   Blah blah blah.
#
# == Examples
#   This command does blah blah blah.
#     extractKeggAnnotations.rb foo.txt
#
#   Other examples:
#     extractKeggAnnotations.rb -q bar.doc
#     extractKeggAnnotations.rb --verbose foo.html
#
# == Usage 
#   extractKeggAnnotations.rb [-hvqkegV] source_file
#
#   For help use: extractKeggAnnotations.rb -h
#
# == Options
#   -h, --help          Displays help message
#   -V, --version       Display the version, then exit
#   -q, --quiet         Output as little as possible, overrides verbose
#   -v, --verbose       Verbose output
#   -k, --ko_number     Search for ko numbers
#   -e, --ec_number     Search for EC numbers
#   -g, --gene          Search for KEGG gene annotations
#
#
# == Author
#   Connor Skennerton
# == Copyright
#    
#    Copyright (c) 2011 Connor Skennerton 
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.


# TO DO - replace all extractKeggAnnotations.rb with your app name
# TO DO - replace all YourName with your actual name
# TO DO - update Synopsis, Examples, etc
# TO DO - change license if necessary



require 'optparse' 
require 'rdoc/usage'
require 'ostruct'
require 'date'


class ExtractKeggAnotations
  VERSION = '0.0.1'
  
  attr_reader :options

  def initialize(arguments, stdin)
    @arguments = arguments
    @stdin = stdin
    
    # Set defaults
    @options = OpenStruct.new
    @options.verbose = false
    @options.quiet = false
    @options.ko = false
    @options.gene = false
    @options.ec = false
    # TO DO - add additional defaults
  end

  # Parse options, check arguments, then process the command
  def run
        
    if parsed_options? 
      
      puts "Start at #{DateTime.now}\
\
" if @options.verbose
      
      output_options if @options.verbose # [Optional]
            
      process_arguments            
	if @arguments.length == 0
		process_standard_input
	else
      	@arguments.each do |file|
      		readInputFile(file)
      	end
    end
      puts "\
Finished at #{DateTime.now}" if @options.verbose
      
    else
      output_usage
    end
      
  end
  
  protected
  
    def parsed_options?
      
      # Specify options
      opts = OptionParser.new 
      opts.on('-V', '--version')    { output_version ; exit 0 }
      opts.on('-h', '--help')       { output_help }
      opts.on('-v', '--verbose')    { @options.verbose = true }  
      opts.on('-q', '--quiet')      { @options.quiet = true }
      opts.on('-e', '--ec_number')  { @options.ec = true}
      opts.on('-k', '--ko_number')  { @options.ko = true}
      opts.on('-g', '--gene')       { @options.gene = true}
      # TO DO - add additional options
            
      opts.parse!(@arguments) rescue return false
      
      process_options
      true      
    end

    # Performs post-parse processing on options
    def process_options
    	@options.verbose = false if @options.quiet
		
		# make sure that only one of gene, ko or EC is set
		if @options.ko && @options.ec || @options.gene
			output_usage
			exit(1)
		end
		if @options.ec && @options.ko || @options.gene
			output_usage
			exit(1)
		end
		if @options.gene && @options.ko || @options.ec
			output_usage
			exit(1)
		end
		unless @options.gene || @options.ko || @options.ec
			output_usage
			exit(1)
		end
    end
    
    def output_options
      puts "Options:\
"
      
      @options.marshal_dump.each do |name, val|        
        puts "  #{name} = #{val}"
      end
    end

    # True if required arguments were provided
#     def arguments_valid?
#       # TO DO - implement your real logic here
#       true if @arguments.length >= 1 
#     end
    
    # Setup the arguments
    def process_arguments
      # TO DO - place in local vars, etc
    end
    
    def output_help
      output_version
      RDoc::usage() #exits app
    end
    
    def output_usage
      RDoc::usage('usage') # gets usage from comments above
    end
    
    def output_version
      puts "#{File.basename(__FILE__)} version #{VERSION}"
    end
    
    def process_command
      # TO DO - do whatever this app does
      
      #process_standard_input # [Optional]
    end
	
	# regexp to find EC numbers
	def extractEc(line)
		if (line =~ /EC.*(\d+\.\d+\.\d+\.\d+)/)
        	puts $1;
    	end	
	end
	
	# regexp to find KEGG ko numbers
	def extractKo(line)
		if (line =~ /(ko\:K\d+)/)
        	puts $1;
    	end
	end
	
	# regexp to find KEGG gene identifiers
	def extractGene(line)
		if (line =~ /([a-zA-Z]{3}\:\w+_\w+)/)
        	puts $1;
    	end
	end
	
	def readInputFile(file)
		File.open(file, 'r') do |infile|
            while line = infile.gets
            	if @options.ec
                	extractEC(line)
                elsif @options.gene
                	extractGene(line)
                elsif @options.ko
                	extractKo(line) 
                end
            end
        end
	end
	
    def process_standard_input
       @stdin.each do |line| 
		if @options.ec
			extractEC(line)
		elsif @options.gene
			extractGene(line)
		elsif @options.ko
			extractKo(line) 
		end
      end
    end
end


# TO DO - Add your Modules, Classes, etc


# Create and run the application
app = ExtractKeggAnotations.new(ARGV, STDIN)
app.run