from pymongo import MongoClient

class Config(object):
    DB_CLIENT = MongoClient(
        'your.db.host',
        port=13207,
        username='username',
        password='password',
        authSource='authentication database',
        authMechanism='SCRAM-SHA-256'
    )

    DB = DB_CLIENT['your database']

    BIBS = DB['your bib collection']
    AUTHS = DB['your auth collection']