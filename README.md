# itp_extract
Proof of concept command line tool for extracting ITP records from MongoDB

### Usage

Takes three positional arguments:

```perl
perl itp_extract.pl <mongo_connection_string> <190$b (body)> <190$c (session)> 
```

Outputs one bib .mrc file and one auth .mrc file, named by the body/session.
