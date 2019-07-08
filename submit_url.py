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

# For building the URL request
import urllib.request
import uuid
import io
import mimetypes

# For building the Metadata XML
from xml.sax.saxutils import escape

# For getting filenames
import os.path

# ---------------------------------------------------------------------------------------------------------------------
# Helper class to do Multipart Forms from https://pymotw.com/3/urllib.request/
# ---------------------------------------------------------------------------------------------------------------------

class MultiPartForm:
    """Accumulate the data to be used when posting a form."""

    def __init__(self):
        self.form_fields = []
        self.files = []
        # Use a large random byte string to separate
        # parts of the MIME data.
        self.boundary = uuid.uuid4().hex.encode('utf-8')
        return

    def get_content_type(self):
        return 'multipart/form-data; boundary={}'.format(
            self.boundary.decode('utf-8'))

    def add_field(self, name, value):
        """Add a simple field to the form data."""
        self.form_fields.append((name, value))

    def add_file(self, fieldname, filename, fileHandle,
                 mimetype=None):
        """Add a file to be uploaded."""
        body = fileHandle.read()
        if mimetype is None:
            mimetype = (
                    mimetypes.guess_type(filename)[0] or
                    'application/octet-stream'
            )
        self.files.append((fieldname, filename, mimetype, body))
        return

    @staticmethod
    def _form_data(name):
        return ('Content-Disposition: form-data; '
                'name="{}"\r\n').format(name).encode('utf-8')

    @staticmethod
    def _attached_file(name, filename):
        return ('Content-Disposition: file; '
                'name="{}"; filename="{}"\r\n').format(
            name, filename).encode('utf-8')

    @staticmethod
    def _content_type(ct):
        return 'Content-Type: {}\r\n'.format(ct).encode('utf-8')

    def __bytes__(self):
        """Return a byte-string representing the form data,
        including attached files.
        """
        buffer = io.BytesIO()
        boundary = b'--' + self.boundary + b'\r\n'

        # Add the form fields
        for name, value in self.form_fields:
            buffer.write(boundary)
            buffer.write(self._form_data(name))
            buffer.write(b'\r\n')
            buffer.write(value.encode('utf-8'))
            buffer.write(b'\r\n')

        # Add the files to upload
        for f_name, filename, f_content_type, body in self.files:
            buffer.write(boundary)
            buffer.write(self._attached_file(f_name, filename))
            buffer.write(self._content_type(f_content_type))
            buffer.write(b'\r\n')
            buffer.write(body)
            buffer.write(b'\r\n')

        buffer.write(b'--' + self.boundary + b'--\r\n')
        return buffer.getvalue()


if __name__ == '__main__':

    # -----------------------------------------------------------------------------------------------------------------
    # Process the command line arguments
    # -----------------------------------------------------------------------------------------------------------------
    parser = argparse.ArgumentParser(description='Create a PatentSafe document from the contents of a URL')
    parser.add_argument('ps_hostname', help="The hostname of the destination PatentSafe. Required.")
    parser.add_argument('authorId', help="The PatentSafe user ID (or alias) of the document's author")
    parser.add_argument('target', help="Required. The target to retrieve from, see documentation for the target definitions")
    parser.add_argument('--urlQuery', help="Optional query parameters to use when accessing the URL defined in the target")
    parser.add_argument('--summary', help="Optional summary for this document")
    parser.add_argument('--metadata', action='append', help="Optional metadata, in the form tag,value. Can be used multiple times")
    parser.add_argument('--submissionDate', help="Optional submission date for the document in iso (yyyy-m-dd HH:MM:ss) format")
    parser.add_argument('--queue', help="Optional submission queue for document processing (defaults to sign)")
    parser.add_argument('--attachment', action='append', help="Optional files to attach to the submission")
    parser.add_argument('--validateAuthor', action='store_true', help="Optional argument to validate the authorId exists in PatentSafe. If true the submission is rejected if the authorId is not allowed to submit to PatentSafe (default is false)")
    parser.add_argument('--verbose', '-v', action='count', help="Output helpful debugging information")

    args = parser.parse_args()
    print(args)

    submission_url = "https://" + args.ps_hostname + "/submit/http-retrieval"

    # -----------------------------------------------------------------------------------------------------------------
    # Create the form
    # -----------------------------------------------------------------------------------------------------------------
    form = MultiPartForm()
    # The required fields
    form.add_field('urlTarget', args.target)
    form.add_field('authorId', args.authorId)

    # Optional Fields
    if args.summary: form.add_field('urlQuery', args.urlQuery)
    if args.summary: form.add_field('summary', args.summary)
    if args.queue: form.add_field('queue', args.queue)
    if args.submissionDate: form.add_field('submissionDate', args.submissionDate)
    if args.validateAuthor: form.add_field('validateAuthor', 'true')

    # -----------------------------------------------------------------------------------------------------------------
    # Create the Metadata XML packet which looks like
    # <metadata>
    # <tag name="TAG NAME">VALUE</tag>
    # </metadata>
    # -----------------------------------------------------------------------------------------------------------------
    metadata_field = None
    if args.metadata:
        metadata_components = ""
        for m in args.metadata:
            tag, value = m.split(',')
            metadata_components = metadata_components + "<tag name=\"" + escape(tag) + "\">" + escape(value) + "</tag>"
        metadata_field = "<metadata>" + metadata_components + "</metadata>"
        print(metadata_field)

    # If Metadata was built
    if metadata_field: form.add_field('metadata', metadata_field)

    # -----------------------------------------------------------------------------------------------------------------
    # Add Attachments
    # -----------------------------------------------------------------------------------------------------------------
    if args.attachment:
        for filepath in args.attachment:
            # Get the filename
            filename = os.path.basename(filepath)
            with open(filepath, 'rb') as fileHandle:
                form.add_file("attachment", filename, fileHandle)


    # Build the request, including the byte-string
    # for the data to be posted.
    data = bytes(form)
    r = urllib.request.Request(submission_url, data=data)
    r.add_header(
        'User-agent',
        'Python Uploader',
    )
    r.add_header('Content-type', form.get_content_type())
    r.add_header('Content-length', len(data))

    if args.verbose:
        print("======================================================================")
        print('OUTGOING DATA:')
        print("----------------------------------------------------------------------")
        for name, value in r.header_items():
            print('{}: {}'.format(name, value))
        print()
        print(r.data.decode('utf-8'))
        print("----------------------------------------------------------------------")


    with urllib.request.urlopen(r) as response:
        response_from_patentsafe = response.read()
        print(response_from_patentsafe)

