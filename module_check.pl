#!/usr/local/bin/perl

use warnings;
use strict;

use File::Find;
use File::Basename;
use Data::Dumper;
use Getopt::Long;
use Pod::Usage;

my $VERSION = 0.01;

my $errors;
my $vfiles;
my $nonVmods;
my $gCount;
my $manager;
my $help;

GetOptions(
            "count"    => \$gCount,
            "errors"   => \$errors,
            "files"    => \$vfiles,
            "folders"  => \$nonVmods,
            "manager"  => \$manager,
            "help|?|h" => \$help,
          );
pod2usage(1) if $help;

my @version_files;    # The list of all version files.
my %mods
  ; # The full hash of folders.  (And whether they contain version files in any subfolder.)
my $gamedata_count;    # The count of GameData folders.
my @module_manager;    # The list of all Module Manager installs.

foreach (@ARGV) {
    find( {
             preprocess  => \&filters,
             wanted      => \&search,
             postprocess => \&after
          },
          $_
        );
}

print "\nCount of GameData folders (should be 1): $gamedata_count\n" if ($gCount or ($errors and $gamedata_count > 1));

if ( $manager or ( @module_manager > 1 and $errors ) ) {
    print "\nModule Manager found at:\n";
    print "========================\n";
    print sort map { $_ . "\n" } @module_manager;
} ## end if ( $manager or ( @module_manager...))

if ($vfiles) {
    print "\nList of version files:\n";
    print "======================\n";
    print sort map { fileparse($_) . "\n" } @version_files;
} ## end if ($vfiles)

if ($nonVmods) {
    print "\nList of directories without version files:\n";
    print "==========================================\n";
    my @folder_list =
      sort grep { ( $_ =~ m|GameData/[^/]+$| ) and ( $mods{$_} eq 'false' ) }
      keys %mods;
    print map { fileparse($_) . "\n" } @folder_list;
} ## end if ($nonVmods)

exit;

sub filters {

    # Set that we haven't seen a version file here yet.
    $mods{$File::Find::dir} = 'false';

    # Count GameData folders and print out their locations.
    if ( $File::Find::dir =~ m/GameData$/ ) {
        $gamedata_count++;
        print "Found nested GameData folder at: $File::Find::dir\n"
          if ( $errors and $gamedata_count > 1 );
    } ## end if ( $File::Find::dir ...)

# Return the list.
# We're checking all visible (not hidden) folders that aren't PluginData or Squad.
  return grep { $_ !~ m/PluginData$|^\.|^Squad$/ } @_;
} ## end sub filters

sub search {

    # Check to see if this is a version file.
    if ( $_ =~ m/\.version$/ ) {
        push @version_files, $File::Find::name;
        $mods{$File::Find::dir} = 'true';
    }

    # Check to see if this is a copy of Module Manager.
    if ( $_ =~ m/ModuleManager\..*\.dll/ ) {
        push @module_manager, $File::Find::name;
    }
  return;
} ## end sub search

sub after {
    my ( $temp, $parent ) = fileparse($File::Find::dir);
    chop $parent;
    $mods{$parent} = 'true' if ( $mods{$File::Find::dir} eq 'true' );
} ## end sub after