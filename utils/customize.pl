#!/usr/local/bin/perl
#
# If this script doesn't work for you, try changing the first line
# to point to the location of Perl on your system. That shouldn't
# be necessary if you're running it via 'make customize'
#
# This script asks the user for a mush name and makes a copy of the
# game/ directory called servers/<mush>/

$tar1="(cd game; tar cf - .) | (cd ";
$tar2="; tar xfBp -)";

$serversdir = "servers/";

# Interact with the user
print <<END;
Welcome. This script creates a directory for MUSH game servers and
customizes the files in order to keep MUSHes tidy and make running
multiple MUSHes easier.

When choosing the name for your directory, use a short version of
the MUSH name. For example, if you MUSH was called Fallen Angels MUSH,
you might choose 'fallen' or 'fa'. Use only upper- or lower-case
letters and numbers in directory names.

END

print "Please enter the name for your directory: ";
chop($name = <STDIN>);

# Verify that the target directory is writable and alphanumeric.

$name =~ s/ +//g;
die "Invalid directory: contains a non-alphanumeric character.\n"
	if ($name =~ /[^A-Za-z0-9_]/);

$targetdir = $serversdir . $name;

die "Directory '$targetdir' already exists! Aborting!\n" if (-d $targetdir);

# Ok, go ahead and create it.

print "Making $targetdir...";
mkdir($serversdir,0755) unless (-d $serversdir);
die "Failed to create $serversdir\n" unless (-d $serversdir);
mkdir($targetdir,0755) unless (-d $targetdir);
die "Failed to create $targetdir\n" unless (-d $targetdir);
print "done.\n";

print "Using tar to copy from game/ to $targetdir/...";
$tar = $tar1 . $targetdir . $tar2;
if (system($tar)) {
	die "Failed!\n";
}
print "done.\n";

foreach $file (<$targetdir/*.dst>) {
  unlink($file) || die "Failed to delete '$file'.";
}

print "Replacing standard files in $targetdir/txt/hlp with\nlinks to files in game/txt/hlp...";
chop($curdir = `pwd`);
foreach $file (<$targetdir/txt/hlp/penn*.hlp>) {
  unlink($file) || die "Failed!\n";
  ($newfile) = $file =~ /(penn.*\.hlp)/;
  symlink("$curdir/game/txt/hlp/$newfile","$targetdir/txt/hlp/$newfile") || die "Failed!\n";
}
print "Fixing links...";
@binaries = qw(netmud info_slave ssl_slave);
foreach $binary (@binaries) {
  symlink("$curdir/src/$binary", "$targetdir/$binary");
}
print "done.\n";

print "Removing game/mush.cnf so the server cannot be started from game/ directory.\n";
unlink("$curdir/game/mush.cnf");
print "Installing restart script.\n";
copy("$curdir/game/restart.dst", "$targetdir/restart") unless (-e "$targetdir/restart");
print "Customization complete for $targetdir/\n";

exit 0;
