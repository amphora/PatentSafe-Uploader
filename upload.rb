require "rubygems"
require 'httpclient' # gem install httpclient

USERNAME = "allisonc@amphora-research.com"
HOST = "https://records.amphora-research.com"
FILENAME = "/Users/simonc/Documents/Scans/2010_09_23_10_53_41.pdf"


def upload_file(filename)
  result = HTTPClient.post "#{HOST}/submit/pdf.jspa",
    { :authorId => USERNAME, 
      :destination => "InTray", 
      :pdfContent => File.new(FILENAME) 
    }
  # This should then come back with something like OK:SJCC0100000059
  result.content[0...2]=="OK"
end

# Loop through the contents
# If it comes back OK then put in Done folder
# Otherwise put it in Error folder
# Create the folders if needed

# Then probably put this into an automator script
puts upload_file(FILENAME)
