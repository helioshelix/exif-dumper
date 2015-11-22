#!/usr/bin/perl -w
use strict;
use warnings;

use Cwd 'abs_path';
use File::Basename;

use Image::ExifTool;

use Data::Dumper;
#$Data::Dumper::Sortkeys=1;
#$Data::Dumper::Terse=1;   
#$Data::Dumper::Quotekeys=0;   
#$|++;

#A picture is worth a thousand words

sub cd(;$);
sub get_longest(@);

cd;

unless(@ARGV){
	print "No files specified\n";
	exit 0;
}

my %options = 
(

	CoordFormat	=> '%+.6f', #Formats coordinates to their decimal values
	Escape		=>'HTML',	#Escape special characters in extracted values for HTML or XML. 
							#Also unescapes HTML or XML character entities in input values passed to "SetNewValue". 
							#Valid settings are 'HTML', 'XML' or undef. Default is undef.
	#Verbose	=> 1,
	
	Binary 				=> 0,
	DateFormat 			=> '%Y-%m-%d %H:%M:%S',
	StrictDate 			=> 'UNABLE TO FORMAT DATE',
	LargeFileSupport 	=> 1,
	MissingTagValue 	=> 'ERROR',
	RequestAll 			=> 1,
	Unknown 			=> 1,
	
);

my @files = @ARGV;
my $exifTool = new Image::ExifTool;

my $outputStr = "";



foreach my $file(@files)
{
	
	unless(defined $file && -e $file){
		$outputStr .= "Error: can not locate $file\n\n";
		next;
	}
	
	unless(-f $file){
		$outputStr .= "Error: '$file' does not appear to be a file\n\n";
		next;
	}
	
	$outputStr .= "File: $file\n";

	my $info = $exifTool->ImageInfo($file, \%options);
	#print Dumper($info);exit;
	
	if(!defined $info){
		$outputStr .= "Unable to extract image info\n\n";
		next;
	}elsif($info->{Error}){
		$outputStr .= "Error: " . $info->{Error} . "\n\n";
		next;
	}
	
	my @tags = $exifTool->GetTagList($info);
	unless(@tags){
		$outputStr .= "No tags found\n";
		next;
	}
	#@tags = sort{$a cmp $b} @tags;
	
	my %imginfo = ();
	foreach my $tag(@tags)
	{
		my $val = $exifTool->GetValue($tag);
		#Only show info if value is printable
		if (ref $val eq 'SCALAR'){
			$imginfo{$tag} = '(unprintable value)';
		}else{
			#Skip tags with no values
			$val =~ s/^\s+|\s+$//g;
			unless(length ($val)){
				next;
			}
			
			#Clean up non printable chars
			$val =~ s/([^\x{0}-\x{7E}])/sprintf'\\x{%02X}',ord($1)/gse;
			
			$imginfo{$tag} = $val;
		}
	}
	
	my $longest = get_longest(keys %imginfo);
	foreach my $k(sort{lc($a) cmp lc($b)} keys %imginfo){
		$outputStr .= $k . '.' x ($longest - length($k)) . ": $imginfo{$k}\n";
	}
	
	$outputStr .= "\n";
}

chomp($outputStr);

print $outputStr;

	
exit 0;

sub get_longest(@)
{ 
	return (sort{$b<=>$a} map{length($_)} @_)[0]; 
}

#use Cwd 'abs_path';
#use File::Basename;
#sub cd(;$);
#cd(); or cd('/some/directory');
sub cd(;$)
{
	my $dir = $_[0];
	#print __FILE__ . "\n$0\n"; exit;
	unless(defined $dir){
		(undef, $dir) = fileparse(abs_path($0));
		#(undef, $dir) = fileparse(__FILE__);
	}
	$dir =~ s/\\+/\//g;
	chdir($dir) or die "Can't change directory to $dir: $!\n";
	#print "Changed cwd to: $dir\n";
}
