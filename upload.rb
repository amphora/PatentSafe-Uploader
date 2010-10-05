
# This brings in Gems so we can get httpclient in
require "rubygems"
# Bring in httpclient - install the gem as follows
# gem install httpclient
require 'httpclient' 

# Command line parser
require 'optparse'


USERNAME = "simonc"
HOST = "https://coles.morescience.com"


def upload_file(filename)
  result = HTTPClient.post "#{HOST}/submit/pdf.jspa",
    { :authorId => USERNAME, 
      :destination => "searchable", 
      :pdfContent => File.new(FILENAME) 
    }
  # This should then come back with something like OK:SJCC0100000059
  result.content[0...2]=="OK"
end




# Loop through the contents
# If it comes back OK then put in Done folder
# Otherwise put it in Error folder
# Create the folders if needed

# At the moment take one argument, which is the directory to process
opts = OptionParser.new
rest = opts.parse(ARGV)
directory_name = rest[0]


puts upload_file(FILENAME)
