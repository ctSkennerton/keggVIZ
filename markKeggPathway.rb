#!/usr/bin/env ruby 

# == Synopsis 
#   takes a list of EC or KO numbers and produces annotated KEGG pathways
# == Examples 
#     markKeggPathway foo.txt
#
#   Other examples:
#     markKeggPathway -q bar.doc
#     markKeggPathway --verbose foo.html
# == Usage 
#   markKeggPathway [options] source_file
#   For help use: markKeggPathway.rb -h
# == Options
#   -h, --help          Displays help message
#   -V, --version       Display the version, then exit
#   -q, --quiet         Output as little as possible, overrides verbose [default: false]
#   -v, --verbose       Verbose output [Default: false]
#   -k, --ko_numbers    Input is a list of KO numbers. [Default: EC numbers]
#   -a, --allpath       Keep allpathways, even the global ones [Default: false]
#   -r, --report        Print a .csv file of the pathways and their enzymes [Default: false]

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



require 'rubygems'
require 'optparse' 
require 'rdoc/usage'
require 'ostruct'
require 'date'
require 'bio'

class App
    VERSION = '0.0.2'
    
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
        #@report_file = "#{File.basename(arguements[0])}.report" 
        @serv = Bio::KEGG::API.new

        # TO DO - add additional defaults
    end
    
    # Parse options, check arguments, then process the command
    def run
        
        if parsed_options? && arguments_valid? 
            
            puts "Start at #{DateTime.now}\
            \
            " if not @options.quiet
            
            output_options if @options.verbose # [Optional]

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
            
            report_pathways if @options.report
            
            remove_global if not @options.allpath
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
        opts.on('-V', '--version')    { output_version ; exit 0 }
        opts.on('-h', '--help')       { output_help }
        opts.on('-v', '--verbose')    { @options.verbose = true }  
        opts.on('-q', '--quiet')      { @options.quiet = true }
        opts.on('-k', '--ko_number')  { @options.ko = true}
        opts.on('-a', '--allpath')    { @options.allpath = true}
        opts.on('-r', '--report')     { @options.report = true}
        
        opts.parse!(@arguments) rescue return false
        
        process_options
        true      
    end
    
    # Performs post-parse processing on options
    def process_options
        @options.verbose = false if @options.quiet
    end
    
    def output_options
        puts "Options:\
        "
        
        @options.marshal_dump.each do |name, val|        
            puts "  #{name} = #{val}"
        end
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
        pathways = @serv.get_pathways_by_kos(enzyme)
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
    		f.print "#{key}"
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
app = App.new(ARGV, STDIN)
app.run
