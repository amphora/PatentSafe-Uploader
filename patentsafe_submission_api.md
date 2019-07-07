# Overview
This is the summary documentation for PatentSafe HTTP APIs. Contents coped from the "PatentSafe Customisation Overview" document. 


# Document Submission
Allows an external application to submit content to PatentSafe.

## URL
`/submit/document.html`

## Authentication
None. This URL can be called without authentication.

## Parameters

Parameter | Description 
--------- | ----------- 
pdfContent | The content of the PDF you want to submit to PatentSafe as a multipart MIME field
encodedPdf | As an alternative to using pdfContent and multipart MIME, you can Base64 encode your PDF and use this field.
authorId | The PatentSafe user ID (or alias) of the document's author.
summary	| Optional summary for this document
metadata | Optional metadata, in the form of a simple XML packet (see below)
submissionDate | Optional submission date for the document in iso (yyyy-m-dd HH:MM:ss) format.
queue (or destination) | Optional submission queue for document processing (defaults to sign)
mimetype | Optional mimetype for the submission (defaults to application/pdf)
encoding | BINARY (default) or BASE64
attachment | Optional multipart mime attachment(s) to be saved with the submission.
validateAuthor | Optional argument to validate the authorId exists in PatentSafe. If true the submission is rejected if the authorId is not allowed to submit to PatentSafe (default is false).


## Metadata
Metadata values may be passed in the metadata attribute of the POST request. This should be a simple XML packet as follows:
<metadata>
<tag name="TAG NAME">VALUE</tag>
</metadata>

## Returns
PatentSafe will return a string which is OK: docId where docId is the document ID that's been allocated by PatentSafe. If there's an error, PatentSafe will return ERR: message where message is some kind of useful error message.

# Submitting a web Page
A lot of web-based systems will have a web page which represents a document which should be in PatentSafe but creating a PDF representation of that page would require additional development work.

Amphora have licensed the Prince library (https://www.princexml.com) will can convert a web page to a PDF. It is used in the PatentSafe email in and archiving facility as well as other ad-hoc places.

Using this method you can request that PatentSafe call your application, get the HTML page and other associated graphics and assets, and render a PDF which is then submitted to PatentSafe as above.

## URL
`/sumbit/http_retrieval`

## Authentication
None. This URL can be called without authentication.

## Parameters

Parameter | Description 
--------- | ----------- 
url | The URL of a web page you wish to become a PDF in PatentSafe
princeParamsFile | The name of a file which contains the Parameters to pass to the Prince command line. This is most often used to supply authentication information, but you can also pass information to Prince about how you’d like the document processed. Note that the actual parameters are stored on the server for security reasons, using the HTTP API you can only refer to something that’s already in place.
authorId | The PatentSafe user ID (or alias) of the document's author.
summary | Optional summary for this document
metadata | Optional metadata, in the form of a simple XML packet (as above)
submissionDate | Optional submission date for the document in iso (yyyy-m-dd HH:MM:ss) format.
queue (or destination) | Optional submission queue for document processing (defaults to sign)
attachment | Optional multipart mime attachment(s) to be saved with the submission.
validateAuthor | Optional argument to validate the authorId exists in PatentSafe. If true the submission is rejected if the authorId is not allowed to submit to PatentSafe (default is false).

# User Creation
Allows an external application to create users in PatentSafe.

Users will only be created if there isn’t an existing user with that ID. So it is harmless to call this for existing users.

## URL
`/submit/add-user.html`

Note this URL can only be called from localhost. It will not accept requests from anything other than 172.0.0.1.

## Authentication
None. This URL can be called without authentication but only from localhost.

## Parameters

Parameter | Description 
--------- | ----------- 
userId | The ID of the user you want to create
name | The name for the user
password | Optional initial password for the user
workgroup | One or more workgroup names for the user. The first value is used as the primary workgroup and any additional values are added as secondary workgroups.
enabled | true/false - Initial enabled state for the user
locked | true/false - Initial locked state for the user
alias | One or more alias values to give the user.
roles | One or more roles to assign the user (overriding the initial defaults). Allowed values are "submit", "author" and "witness".  To disable a role prepend it with !.