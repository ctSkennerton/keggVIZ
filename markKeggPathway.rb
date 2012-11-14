#!/usr/bin/env ruby 
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
require 'ostruct'
require 'date'
require 'bio'

class MarkKeggPathway
  VERSION = '0.0.3'
  AUTHOR = "Connor Skennerton"
  NAME = "markKeggPathway"
  attr_reader :options

  def initialize(arguments, stdin)
    @arguments = arguments
    @stdin = stdin
    @objs = []

    # create multilayered hash
    @queryPathways= Hash.new {|hash,key| hash[key] = Hash.new{ 
      |hash,key| hash[key] = 0 
    }} 
    # Set defaults
    @options = OpenStruct.new
    @options.verbose = false
    @options.quiet = false
    @options.ko = false
    @options.allpath = false
    @options.report = false
    @serv = Bio::KEGG::API.new

  end

  # Parse options, check arguments, then process the command
  def run

    if parsed_options? && arguments_valid? 

      read_ec_file

      @objs.uniq!
      if @options.verbose
        puts "there are a total of #{@objs.length} enzymes"
      end
      puts "Querying KEGG for the pathways of each enzyme..." if not @options.quiet
      if @options.ko
        @objs.each do |enzyme|
          get_kegg_pathways_ko(enzyme)
        end
      else
        @objs.each do |enzyme|
          get_kegg_pathways_ec(enzyme)
        end
      end

      remove_global if not @options.allpath
      report_pathways if @options.report
      # iterate through the found pathways.  Give the key
      # which is the pathway and the internal hash for 
      # all of the enzymes that have matched to that pathway
      # calling the keys method returns an array which gets passed
      # in to the sub
      puts"Downloading marked pathways..." if not @options.quiet
      @queryPathways.each do |queryPath, listOfEnzymes|
        mark_enzymes(queryPath, listOfEnzymes.keys)
      end            
      puts "\
            Finished at #{DateTime.now}" if not @options.quiet

    else
      output_usage
    end

  end

  protected

  def parsed_options?

    # Specify options
    opts = OptionParser.new 
    opts.banner = "#{NAME} [options] source_file"
    opts.on('-V', '--version', "Output version information")    { output_version ; exit 0 }
    opts.on('-h', '--help', "Output usage")       { @options.help = true }
    opts.on('-v', '--verbose', "Output alot of information to screen")    { @options.verbose = true }  
    opts.on('-q', '--quiet')      { @options.quiet = true }
    opts.on('-k', '--ko_number', "source file contains a list of KO numbers [Default: EC numbers]")  { @options.ko = true}
    opts.on('-a', '--allpath', "Colour global pathways [Default: remove those pathways]")    { @options.allpath = true}
    opts.on('-r', '--report')     { @options.report = true}

    opts.parse!(@arguments) rescue puts opts
    if @options.help
      puts opts
    end

    process_options
    true      
  end

  # Performs post-parse processing on options
  def process_options
    @options.verbose = false if @options.quiet
  end

  # True if required arguments were provided
  def arguments_valid?
    # TO DO - implement your real logic here
    true if @arguments.length >= 1 
  end

  # Setup the arguments
  def remove_global
    # the following pathways are global
    # eg. map01100 is 'metabolism'
    # these are very big and are not nesessary to annotate
    if @queryPathways.has_key?('path:map01100')
      @queryPathways.delete('path:map01100')
    end
    if @queryPathways.has_key?('path:map01110')
      @queryPathways.delete('path:map01110')
    end
    if @queryPathways.has_key?('path:map01120')
      @queryPathways.delete('path:map01120')
    end


  end

  def output_version
    puts "#{NAME} version #{VERSION} copyright (c) #{AUTHOR}"
  end

  def read_ec_file
    File.open(@arguments[0], 'r') do |infile|
      while line = infile.gets
        @objs<<line.chomp
      end
    end
  end

  def get_kegg_pathways_ec(enzyme)
    pathways = @serv.get_pathways_by_enzymes(enzyme)
    if @options.verbose 
      puts "#{enzyme} is a member of #{pathways.length} pathway(s)"
    end
    pathways.each do |path|
      # add the enzyme to the pathway
      @queryPathways[path][enzyme] = 1
    end
  end

  def get_kegg_pathways_ko(enzyme)
    pathways = @serv.get_pathways_by_kos(enzyme, 'map')
    if @options.verbose 
      puts "#{enzyme} is a member of #{pathways.length} pathway(s)"
    end
    pathways.each do |path|
      @queryPathways[path][enzyme] = 1            
    end
  end

  def report_pathways
    f = File.new("#{@arguments[0]}.csv", 'w')
    @queryPathways.each do |key, hash|
      f.print "#{key},#{hash.length}"
      hash.each do |enzyme, val|
        f.print ",#{enzyme}"
      end
      f.puts
    end
    f.close
  end

  def print_kegg_pathway(url2, queryPath)
    @serv.save_image(url2, "#{queryPath}.gif")
  end

  def mark_enzymes(queryPath, matchEnzymes)
    #queryPathways.each do |queryPath| 
    puts "marking enzymes in #{queryPath}" if options.verbose
    url2 = @serv.mark_pathway_by_objects(queryPath, matchEnzymes)
    print_kegg_pathway(url2, queryPath)
  end
end


# TO DO - Add your Modules, Classes, etc


# Create and run the application
app = MarkKeggPathway.new(ARGV, STDIN)
app.run
