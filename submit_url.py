# Copyright  2019 Amphora Research Systems Ltd.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
# documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
# Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
# OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


# Parsing arguments
import argparse

import urllib.request

# ---------------------------------------------------------------------------------------------------------------------
# Process the command line arguments
# ---------------------------------------------------------------------------------------------------------------------
parser = argparse.ArgumentParser(description='Create a PatentSafe document from the contents of a URL')
parser.add_argument('ps_hostname', help="The hostname of the destination PatentSafe. Required.")
parser.add_argument('authorId', help="The PatentSafe user ID (or alias) of the document's author")
parser.add_argument('url', help="The URL PatentSafe should retrieve and convert to a PDF. Required.")
parser.add_argument('--princeParamsFile', default="",
                    help="The name of the file on the server which contains additional parameters for Prince. You can use this for both authentication and processing arguments")
parser.add_argument('--summary', help="Optional summary for this document")
#parser.add_argument('--metadata', help="Optional metadata, in the form of a simple XML packet (as above)")
parser.add_argument('--submissionDate', help="Optional submission date for the document in iso (yyyy-m-dd HH:MM:ss) format")
parser.add_argument('--queue', help="Optional submission queue for document processing (defaults to sign)")
#parser.add_argument('--attachment', help="Optional multipart mime attachment(s) to be saved with the submission")
#parser.add_argument('--validateAuthor', help="Optional argument to validate the authorId exists in PatentSafe. If true the submission is rejected if the authorId is not allowed to submit to PatentSafe (default is false)")

args = parser.parse_args()
print(args)

# ---------------------------------------------------------------------------------------------------------------------
# Extract the fields just so it's really clear what's being used for laster
# ---------------------------------------------------------------------------------------------------------------------

submission_url = "https://" + args.ps_hostname + "/sumbit/http_retrieval"

values = {}
# These are mandatory
values['url'] = args.url
values['authorId'] = args.authorId
# These are optional
if args.princeParamsFile: values['princeParamsFile'] = args.princeParamsFile
if args.princeParamsFile: values['summary'] = args.summary
if args.princeParamsFile: values['queue'] = args.queue
if args.princeParamsFile: values['submissionDate'] = args.submissionDate


# ---------------------------------------------------------------------------------------------------------------------
# Build the request and send to PatentSafe
# ---------------------------------------------------------------------------------------------------------------------
data = urllib.parse.urlencode(values)
data = data.encode('ascii') # data should be bytes
req = urllib.request.Request(submission_url, data)
with urllib.request.urlopen(req) as response:
    the_page = response.read()
    print(the_page)



# url | The URL of a web page you wish to become a PDF in PatentSafe
# princeParamsFile | The name of a file which contains the Parameters to pass to the Prince command line.
# This is most often used to supply authentication information, but you can also pass information to Prince about
# how you'd like the document processed.
# Note that the actual parameters are stored on the server for security reasons,
# using the HTTP API you can only refer to something that's already in place.
# authorId | The PatentSafe user ID (or alias) of the document's author.
# summary | Optional summary for this document
# metadata | Optional metadata, in the form of a simple XML packet (as above)
# submissionDate | Optional submission date for the document in iso (yyyy-m-dd HH:MM:ss) format.
# queue (or destination) | Optional submission queue for document processing (defaults to sign)
# attachment | Optional multipart mime attachment(s) to be saved with the submission.
# validateAuthor | Optional argument to validate the authorId exists in PatentSafe. If true the submission is rejected if the authorId is not allowed to submit to PatentSafe (default is false).


# TODO
# Submit to PatentSafe
# Metadata
# Complete command line parsing https://docs.python.org/3.3/library/argparse.html#argparse.ArgumentParser.add_argument
# Metadata as nargs
# Complete all the arguments
# Do normal submission too