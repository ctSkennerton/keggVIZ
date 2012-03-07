#!/usr/bin/env ruby 

# == Synopsis 
#
#   Given a gff file extracts annotations
#
# == Examples
#     extractKeggAnnotations.rb -k foo.txt
#
#   Other examples:
#     extractKeggAnnotations.rb -ce bar.gff
#     extractKeggAnnotations.rb --verbose -g foo.html
#
# == Usage 
#   extractKeggAnnotations.rb [-hvcV] -k|e|g|t [source_file]
#
#   For help use: extractKeggAnnotations.rb -h
#
# == Options
#   -h, --help          Displays help message
#   -V, --version       Display the version, then exit
#   -v, --verbose       Verbose output
#   -k, --ko_number     Search for ko numbers
#   -e, --ec_number     Search for EC numbers
#   -g, --gene          Search for KEGG gene annotations
#   -t, --taxon         Search for Taxon numbers
#   -c, --count         Print the number of times each annotation is seen
#
#
# == Author
#   Connor Skennerton
# == Copyright
#    
#    Copyright (c) 2011, 2012 Connor Skennerton 
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

require 'optparse' 
require 'rdoc/usage'
require 'ostruct'
require 'date'
class App
  VERSION = '0.0.2'

  attr_reader :options

  def initialize(arguments, stdin)
    @arguments = arguments
    @stdin = stdin

    @genes = Hash.new(0)
    # Set defaults
    @options = OpenStruct.new
    @options.verbose = false
    @options.ko = false
    @options.gene = false
    @options.ec = false
    @options.count = false
    @options.taxon = false
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
      printGenes
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
    opts.on('-e', '--ec_number')  { @options.ec = true}
    opts.on('-k', '--ko_number')  { @options.ko = true}
    opts.on('-g', '--gene')       { @options.gene = true}
    opts.on('-c', '--count')      {@options.count = true}
    opts.on('-t', '--taxon')      {@options.taxon = true}

    opts.parse!(@arguments) rescue return false

    process_options
    true
  end

  # Performs post-parse processing on options
  def process_options
    @options.verbose = false if @options.quiet
    
    # make sure that only one of gene, ko or EC is set
    if @options.ko && (@options.ec || @options.gene || @options.taxon)
      puts "options -k -e -g -t are mutualy exclusive"
      output_usage
      exit(1)
    end
    if @options.ec && (@options.ko || @options.gene || @options.taxon)
      puts "options -k -e -g -t are mutualy exclusive"
      output_usage
      exit(1)
    end
    if @options.gene && (@options.ko || @options.ec || @options.taxon)
      puts "options -k -e -g -t are mutualy exclusive"
      output_usage
      exit(1)
    end
    if @options.taxon and ( @options.ko || @options.ec || @options.gene)
      puts "options -k -e -g -t are mutualy exclusive"
      output_usage
      exit(1)
    end
    unless @options.gene || @options.ko || @options.ec || @options.taxon
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

  def printGenes
    @genes.each do |k, v|
      if @options.count
        puts "#{v}\t#{k}"
      else
        puts k
      end
    end
  end

  def readInputFile(file)
    extract_ann = ExtractAnotations.new

    File.open(file, 'r') do |infile|
      while line = infile.gets
        extract_ann.input = line
        if @options.ec
          extract_ann.extractEc
        elsif @options.gene
          extract_ann.extractGene
        elsif @options.ko
          extract_ann.extractKo 
        end
        @genes[extract_ann.annotation] += 1
      end
    end
  end #readInputFile

  def process_standard_input
    extract_ann = ExtractAnotations.new
    @stdin.each do |line| 
      extract_ann.input = line
      if @options.ec
        extract_ann.extractEc
      elsif @options.gene
        extract_ann.extractGene
      elsif @options.ko
        extract_ann.extractKo 
      end
      @genes[extract_ann.annotation] += 1
    end
  end # process_standard_input
end # App


class ExtractAnotations
  
  attr_reader :annotation
  attr_writer :input
  # regexp to find EC numbers
  def extractEc
    if (@input =~ /EC.*(\d+\.(\d+|-)\.(\d+|-)\.(\d+|-))/)
      @annotation = $1
    end	
  end

  # regexp to find KEGG ko numbers
  def extractKo
    if (@input =~ /(ko\:K\d+)/)
      @annotation = $1
    end
  end

  # regexp to find KEGG gene identifiers
  def extractGene
    if (@input =~ /([a-zA-Z]{3}\:\w+_\w+)/)
      @annotation = $1
    end
  end
  
  #regexp to find taxon numbers
  def extractTaxon
    if (@input =~ /taxon:\s*(\d+);/)
      @annotation = $1
    end
  end

end #ExtractAnotations
# Create and run the application
app = App.new(ARGV, STDIN)
app.run
