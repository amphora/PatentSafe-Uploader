
# This brings in Gems so we can get httpclient in
require "rubygems"
# Bring in httpclient - install the gem as follows
# gem install httpclient
require 'httpclient' 

# Command line parser
require 'optparse'

# Ruby extensions - get from "gem install -r extensions"
# See http://extensions.rubyforge.org/rdoc/index.html
require 'extensions/string'

# So we can iterate over directory contents
require 'find'

USERNAME = "simonc"
HOST = "https://coles.morescience.com"


def upload_file(filename)
  result = HTTPClient.post "#{HOST}/submit/pdf.jspa",
    { :authorId => USERNAME, 
      :destination => "searchable", 
      :pdfContent => File.new(filename) 
    }
  # This should then come back with something like OK:SJCC0100000059
  puts result.content
  # Return true or false
  result.content[0...2]=="OK"
end

# Process an entire directory
def process_directory(directory_name)
  puts "Directory called on #{directory_name}"
  Find.find(directory_name) do |f|
      # Only work on files which end in .pdf
      if f.ends_with?(".pdf")
        result = upload_file(f)
        puts "Uploaded #{f}, result = #{result}"
    end
  end
end

# At the moment take one argument, which is the directory to process
opts = OptionParser.new
rest = opts.parse(ARGV)
directory_name = rest[0]
# Start with the first directory
process_directory(directory_name)
