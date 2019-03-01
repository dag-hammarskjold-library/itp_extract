#!/usr/bin/env python
"""
itp_extract.py

Python version of the ITP Extracts script. Generates MARC 21 formatted ITP files for a body and session.

Usage:
  itp_extracy.py -b <body> -s <session>

Options:
  -h --help                  Show this help screen.
  -b --body <body>           UN Body you want to query.
  -s --session <session>     Session you want to query.
"""
from pymongo import MongoClient
from docopt import docopt
from collections import OrderedDict
from pymarc import Record, JSONReader
from config import Config
from bson import SON
#from marctools.pymarcer import make_json
from dlx.jmarc import JMARC
#from dlx.db import DB
from dlx.query import *
from tqdm import tqdm
import re
import yaml






if __name__ == '__main__':
    #arguments = docopt(__doc__,version='itp_extract 1.0')
    #body = arguments['--body']
    #session = arguments['--session']
    body='S/'
    session='70'

    bib_out = re.sub('/','',str(body)) + str(session) + '_BIB'
    auth_out = re.sub('/','',str(body)) + str(session) + '_AUTH'

    auths = Config.AUTHS
    bibs = Config.BIBS
    #db=DB()

    
    
    
    # Get the authority record for the body/session
    query = {
        '$and': [
            tag_sub_val('190','b',body),
            tag_sub_val('190','c',session)
        ]
    }
    found_auth = auths.find_one(query)['_id']
    print('Found series auth id: %s' % found_auth)

    # Get the bib records for the target body/session authority id
    agenda_ids = []
    print("Fetching bib records...")
    with open(bib_out + '.mrc', 'wb') as f:
        bibs_query = {
            '$or': [
                
                tag_sub_val('191','0',str(found_auth)),
                tag_sub_val('791','0',str(found_auth))
            ]
        }
        cursor = bibs.find(bibs_query)

        for doc in tqdm(cursor, total=cursor.count()):
            jmarc=JMARC(doc)
            #py_m=jmarc.to_pymarc
            record = jmarc.to_pymarc()
            f.write(record.as_marc())
            try:
                agenda_ids.append(record['991']['0'])
            except TypeError:
                pass

    # Get the agenda authorities for the body/session bib records
    print("Fetching agenda authorities...")
    with open(auth_out + '.mrc', 'wb') as f:
        for this_id in tqdm(set(agenda_ids)):
            agenda = auths.find_one({'_id': int("0" + str(this_id))})
            jmarc=JMARC(agenda)
            #reader = JSONReader(make_json(agenda))
            #for record in reader:
            #    record.force_utf8 = True
            #py_m_auth=jmarc.to_pymarc
            #f.write(py_m_auth.as_marc())
            record = jmarc.to_pymarc()
            f.write(record.as_marc())