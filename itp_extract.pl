use v5.10;
use strict;
use warnings;

# core modules (no need tto install)

use List::Util qw<any all none uniq>;

# local libraries (included in this repo)

use FindBin;
use lib "$FindBin::Bin/lib";
use MARC;

# Dependencies to install from CPAN i.e.,
# 	cpanm install MongoDB
#	cpanm install Tie::IxHash

use MongoDB;
use Tie::IxHash;

# global objects to access database
# get connection string from first command line arg
my $DB = MongoDB->connect($ARGV[0])->get_database('undlFiles');
my $AUTH = $DB->get_collection('auth_JMARC');
my $BIB = $DB->get_collection('bib_JMARC');

# function for generating a query document matching a subfield value 
sub tag_sub_val {
	my ($tag,$code,$val) = @_;
	
	return {
		datafield => {
			'$elemMatch' => {
				tag => $tag,
				subfield => Tie::IxHash->new (
					code => $code,
					value => $val,
				),
			}
		}
	}
}

MAIN: {
	# get body and session from 2nd and 3rd command line args
	my ($body, $session) = @ARGV[1,2];
	$body .= '/' if substr($body,-1) ne '/';
	
	local $| = 1;

	# get auth# of series symbol
	my $series_id = do {
		
		my $query = {
			'$and' => [
				tag_sub_val('190','b',$body),
				tag_sub_val('190','c',$session)
			]
		};
	
		my $doc = $AUTH->find_one($query);
	
		$doc->{_id} // die "series symbol not found";
	};
	
	say "found series auth id: $series_id";
	
	# declare an array to collect agenda auth#s to use later
	my @agenda_ids;
	
	BIBS: {
		open my $bib_out,'>:utf8',("$body$session\_bib.mrc" =~ s./..r);
		
		# find the bib records that link to the series symbol
		
		my $query = {
			'$or' => [
				# subfield values, including subfield 0, are strings for now. ints won't match
				tag_sub_val('191','0',"$series_id"),
				tag_sub_val('791','0',"$series_id"),
			]
		};
			
		my $cursor = $BIB->find($query);
		my $i = 0;
		
		print "bibs processed:  ";
		while (my $doc = $cursor->next) {
			
			# convert to internal MARC object for printing as marc21
			my $marc = MARC::Record->new->from_mongo($doc);
			print {$bib_out} $marc->to_marc21;
			
			# save the cross-referenced auth# of agenda items
			push @agenda_ids, $marc->get_values('991','0');
		
			print "\b" x length $i;
			print ++$i;
		}
	}
	
	AUTHS: {
		open my $auth_out,'>:utf8',("$body$session\_auth.mrc" =~ s./..r);
		
		# use the unique agenda auth#s to look up the auth records 
		
		my $i = 0;
		
		print "\nauths processed:  ";
		for my $agenda_id (uniq @agenda_ids) {
			
			# find auth record
			# _id must be an int
			my $doc = $AUTH->find_one({_id => 0 + $agenda_id});
			
			# convert to internal MARC object for printing as marc21
			my $marc = MARC::Record->new->from_mongo($doc);
			print {$auth_out} $marc->to_marc21;
			
			print "\b" x length $i;
			print ++$i;
		}
	}
	
	exit;
}




