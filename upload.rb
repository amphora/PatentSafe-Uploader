#!/usr/bin/env ruby
# == Synopsis 
#   Upload a directory of PDFs to PatentSafe
#
# == Examples
#   
#     ruby upload.rb --hostname demo.morescience.com --username simonc --destination patentsafe <directory or filename>
#
#   Other examples:
#     ruby pscheck.rb -q /path/to/repository
#     ruby pscheck.rb --verbose /path/to/repository
#     ruby pscheck.rb -y 2007 -v /path/to/repository
#
# == Usage 
#   upload.rb [options] --hostname <patentsafe_server> --username <userid> --destination <destination> path_to_directory_or_file
#
#   For help use: ruby upload.rb -h
#
# == Options
#   -h, --help          Displays help message
#   -u, --username      Username to sutmit as
#   -h, --hostname      Hostname of the PatentSafe server
#   -d, --destination   Destination in PatentSafe (sign, intray, searchable)
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
    opts.on('-u', '--username')    { @options.username = username }
    opts.on('-h', '--hostname')    { @options.hostname = hostname }
    opts.on('-d', '--destination')    { @options.destination = destination }
    opts.on('-v', '--version')  { output_version ; exit 0 }
    opts.on('-h', '--help')     { output_help }
    opts.on('-V', '--verbose')  { @options.verbose = true }
    opts.parse!(@arguments) rescue return false
    process_options
    true
  end

  # Performs post-parse processing on options
  def process_options
    @options.verbose = false if @options.quiet
  end

  # True if required arguments were provided
  def arguments_valid?
    true if @arguments.length == 2 &&  @options.username && @options.hostname && @options.destination
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
    uploader = PatentSafe::Uploader.new(:username => @options.username, :hostname => @options.hostname, :destination => @options.destination)
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
    attr_accessor :username, :hostname, :destination

    def initialize(options={})

      LOG.info "-----------------------------------------------------------------------"
      LOG.info " PatentSafe Uploader "
      LOG.info "-----------------------------------------------------------------------"
      LOG.info " Started at: #{Time.now}"
      LOG.info ""

    end

    def upload_file(filename)
      result = HTTPClient.post "#{@hostname}/submit/pdf.jspa",
      { :authorId => @username, 
        :destination => @destination, 
        :pdfContent => File.new(filename) 
      }
      # This should then come back with something like OK:SJCC0100000059
      LOG.info  result.content
      # Return true or false
      result.content[0...2]=="OK"
    end

    # Process an entire directory
    def upload(pathname)
      if File.is_dir?(pathname)
        LOG.info  "Directory called on #{directory_name}"
        Find.find(upload) do |f|
          # Only work on files which end in .pdf
          if f.ends_with?(".pdf")
            result = upload_file(f)
            LOG.info  "Uploaded #{f}, result = #{result}"
          end
        end
      elsif pathname.ends_with?(".pdf")
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
