#!/usr/bin/env ruby
# == Synopsis 
#   Upload a directory of PDFs to PatentSafe
#
# == Examples
#   
#     ruby upload.rb --hostname demo.morescience.com --username simonc --destination patentsafe <directory or filename>
#     ruby upload.rb --hostname demo.morescience.com --username simonc --destination patentsafe --metadata project=suntan <directory or filename>
#
# == Usage 
#   upload.rb [options] --hostname PATENTSAFE_HOSTNAME --username USERID --destination DESTINATION path_to_directory_or_file
#
#   For help use: ruby upload.rb -h
#
# == Options
#   -h, --help          Displays help message
#   -u, --username      Username to sutmit as
#   -h, --hostname      Hostname of the PatentSafe server
#   -d, --destination   Destination in PatentSafe (sign, intray, searchable)
#   -m, --metatada      Metadata (in the form TAG=VALUE)
#   -v, --version       Display the version, then exit
#   -q, --quiet         Output as little as possible, overrides verbose
#   -V, --verbose       Verbose output
#   
#
# == Author
#   Amphora Research Systems, Ltd.
#
# == Copyright
#   Copyright (c) 2010-2011 Amphora Research Systems Ltd.
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
# 
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
# 
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.

# TODO - add Metadata as well

# This brings in Gems so we can get httpclient in
require "rubygems"

# Bring in httpclient - install the gem as follows
# gem install httpclient
require 'httpclient' 

# Ruby extensions - get from "gem install -r extensions"
# See http://extensions.rubyforge.org/rdoc/index.html
require 'extensions/string'

# So we can iterate over directory contents
require 'find'

require 'date'
require 'fileutils'
require 'find'
require 'logger'
require 'optparse'
require 'ostruct'
require 'pathname'
require 'rdoc/usage'


#DESTINATION = "searchable"
# DESTINATION = "intray"

# setup the logger if this is the main file
if __FILE__ == $PROGRAM_NAME
  LOG = Logger.new(STDOUT)
end

# Script
#   sets up arguments, logging level, and options. Also handles help output.
class Script
  VERSION = '0.1'

  # Simple log formatter
  class Formatter < Logger::Formatter
    def call(severity, time, program_name, message)
      "#{message}\n"
    end
  end

  attr_reader :options

  def initialize(arguments, stdin)
    @arguments = arguments
    @stdin = stdin
    @options = OpenStruct.new
    @options.verbose = false
    @options.quiet = false
  end

  def run
    LOG.formatter = Formatter.new

    if parsed_options? && arguments_valid?

      LOG.level = if @options.verbose
        Logger::INFO
      elsif @options.quiet
        Logger::ERROR
      else # default
        Logger::WARN
      end

      process_arguments
      process_command
    else
      output_usage
    end

  end

  protected

  def parsed_options?
    opts = OptionParser.new
    
    # Initialise the metadata packet
    @options.metadata = "<metadata>\n"
    
    # Mandatory argument - the username to use
    opts.on("-u", "--username USERNAME",
            "You must specify a username") do |username|
      @options.username = username
    end

    # Mandatory argument - the hostname
    opts.on("-u", "--hostname HOSTNAME",
            "You must specify a hostname") do |hostname|
      @options.hostname = hostname
    end

    # Mandatory argument - the destination
    opts.on("-u", "--destination DESTINATION",
            "You must specify a Destination Submission Queue") do |destination|
      @options.destination = destination
    end
    
    opts.on("-m", "--metadata TAG=VALUE") do |mditem|
      # Adding a line for this metadata item
      bits = mditem.split("=")
      mdentry = "<tag name=\""  + bits[0] + "\">" + bits[1] + "</tag>\n"
      @options.metadata << mdentry
    end
    
    opts.on('-v', '--version')  { output_version ; exit 0 }
    opts.on('-h', '--help')     { output_help }
    opts.on('-V', '--verbose')  { @options.verbose = true }
    
    opts.parse!(@arguments) 
#    opts.parse!(@arguments) rescue return false
    process_options
    true
  end

  # Performs post-parse processing on options
  def process_options
    # Sort out the Verbose/Quiet flags
    @options.verbose = false if @options.quiet
    
    # Close the Metadata Packet 
    @options.metadata << "</metadata>"
  end

  # True if required arguments were provided
  def arguments_valid?
    true if @arguments.length == 1 &&  @options.username && @options.hostname && @options.destination
  end

  # Setup the arguments
  def process_arguments
    @source = Pathname.new(File.expand_path(ARGV[0])) if ARGV[0]

    # # check the target
    # if @target.exist?
    #   if !@target.children.empty? && !@options.force
    #     LOG.error "Target directory '#{@target.to_s}' exists and is not empty. Pass -f (--force) option to proceed anyway."
    #     exit 0
    #   end
    # else
    #   @target.mkpath
    # end

  end

  def process_command
    uploader = PatentSafe::Uploader.new(:username => @options.username, :hostname => @options.hostname, :destination => @options.destination, :metadata => @options.metadata)
    uploader.upload(@source)
  end

  def version_text
    "#{File.basename(__FILE__)} version #{VERSION}"
  end

  def output_help
    LOG.info version_text
    RDoc::usage() #exits app
  end

  def output_usage
    RDoc::usage('usage') # gets usage from comments above
  end

  def output_version
    LOG.info version_text
    RDoc::usage('copyright')
  end

  def output_options
    LOG.info "Options:\n"
    @options.marshal_dump.each do |name, val|
      LOG.info "  #{name} = #{val}"
    end
  end

end # class Script

module PatentSafe
  class Uploader 
    attr_accessor :username, :hostname, :destination, :metadata

    def initialize(options={})
      LOG.info "-----------------------------------------------------------------------"
      LOG.info " PatentSafe Uploader "
      LOG.info "-----------------------------------------------------------------------"
      LOG.info " Started at: #{Time.now}"
      LOG.info ""

      @hostname = options[:hostname]
      @username = options[:username]
      @destination = options[:destination]
      @metadata = options[:metadata]

    end

    def upload_file(filename)
      result = HTTPClient.post "https://#{hostname}/submit/pdf.jspa",
                    { :authorId => username, 
                      :destination => destination, 
                      :pdfContent => File.new(filename),
                      :metadata => metadata
                    }
      # This should then come back with something like OK:SJCC0100000059
      LOG.info result.content
      success = result.content[0...2]=="OK"
      docid = result.content[3..-1]
      # If we had success, put the DocID on the end of the file
      if success
        File.rename(filename, "#{docid}_#{filename.to_s}")
      end
      # Return true or false
      success
    end

    # Process an entire directory
    def upload(pathname)
      if File.directory?(pathname)
        LOG.info  "Directory called on #{directory_name}"
        Find.find(upload) do |f|
          # Only work on files which end in .pdf
          if f.to_s.ends_with?(".pdf")
            result = upload_file(f)
            LOG.info  "Uploaded #{f}, result = #{result}"
          end
        end
      elsif pathname.to_s.ends_with?(".pdf")
        result = upload_file(pathname)
        LOG.info  "Uploaded #{pathname}, result = #{result}"
      else
        LOG.info("#{pathname} is not a PDF, ignoring")
      end
      
      LOG.info "-----------------------------------------------------------------------"
      LOG.info " Completed at: #{Time.now}"
    end

  end
end


# Only run script if called from command line and not included as a lib
if __FILE__ == $PROGRAM_NAME
  # Create and run the application
  script = Script.new(ARGV, STDIN)
  script.run
end