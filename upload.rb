#!/usr/bin/env ruby

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
    true if @arguments.length == 2
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
    uploader = PatentSafe::Uploader.new()
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
    attr_accessor :username, :host, :destination, :directory

    def initialize(options={})

      LOG.info "-----------------------------------------------------------------------"
      LOG.info " PatentSafe Stripper "
      LOG.info "-----------------------------------------------------------------------"
      LOG.info " Started at: #{Time.now}"
      LOG.info ""
      
    end


    USERNAME = "simonc"
    HOST = "https://jjcr20.morescience.com"
    #DESTINATION = "searchable"
    DESTINATION = "intray"

    def upload_file(filename)
      result = HTTPClient.post "#{HOST}/submit/pdf.jspa",
      { :authorId => USERNAME, 
        :destination => DESTINATION, 
        :pdfContent => File.new(filename) 
      }
      # This should then come back with something like OK:SJCC0100000059
      LOG.info  result.content
      # Return true or false
      result.content[0...2]=="OK"
    end

    # Process an entire directory
    def upload(directory_name)
      LOG.info  "Directory called on #{directory_name}"
      Find.find(directory_name) do |f|
        # Only work on files which end in .pdf
        if f.ends_with?(".pdf")
          result = upload_file(f)
          LOG.info  "Uploaded #{f}, result = #{result}"
        end
      end
    end

    # At the moment take one argument, which is the directory to process
    opts = OptionParser.new
    rest = opts.parse(ARGV)
    directory_name = rest[0]
    # Start with the first directory
    process_directory(directory_name)
  end
end


# Only run script if called from command line and not included as a lib
if __FILE__ == $PROGRAM_NAME
  # Create and run the application
  script = Script.new(ARGV, STDIN)
  script.run
end
