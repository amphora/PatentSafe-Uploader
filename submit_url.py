# Submit to PatentSafe

import argparse

parser = argparse.ArgumentParser(description='Submit to PatentSafe.')
parser.add_argument('url', help="The URL PatentSafe should retrieve and convert to a PDF. Required.")
parser.add_argument('--princeParamsFile', default="",
                    help="The name of the file on the server which contains additional parameters for Prince. You can use this for both authentication and processing arguments")
parser.add_argument('--authorId', help="The PatentSafe user ID (or alias) of the document's author")
parser.add_argument('--summary', help="Optional summary for this document")
#parser.add_argument('--metadata', help="Optional metadata, in the form of a simple XML packet (as above)")
#parser.add_argument('--submissionDate', help="Optional submission date for the document in iso (yyyy-m-dd HH:MM:ss) format")
parser.add_argument('--queue', help="Optional submission queue for document processing (defaults to sign)")
#parser.add_argument('--attachment', help="Optional multipart mime attachment(s) to be saved with the submission")
#parser.add_argument('--validateAuthor', help="Optional argument to validate the authorId exists in PatentSafe. If true the submission is rejected if the authorId is not allowed to submit to PatentSafe (default is false)")

args = parser.parse_args()
args = parser.parse_args()
print(args)




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