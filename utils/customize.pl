#!/usr/local/bin/perl
use File::Copy;
use File::Copy::Recursive qw(dircopy dirmove);
#
# If this script doesn't work for you, try changing the first line
# to point to the location of Perl on your system. That shouldn't
# be necessary if you're running it via 'make customize'
#
# This script asks the user for a mush name and makes a copy of the
# game/ directory called servers/<mush>/

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

print "Moving from game/ to $targetdir/...";
dirmove("game/save", "$targetdir/save");
dirmove("game/log", "$targetdir/log");
dirmove("game/data", "$targetdir/data");
dircopy("game/txt", "$targetdir/txt");
foreach $file (<game/*>) {
  copy($file, "$targetdir/");
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


print "Removing old files...";
print "removing game/restart so the server cannot be started from game/ directory.\n" if (-e "game/restart");
unlink("game/restart") if (-e "game/restart");
@remove = (qw(game/netmush game/info_slave game/ssl_slave), <game/*.cnf>);
foreach $file (@remove) {
  print "removing '$file'..." if (-e "$file");
  unlink($file) if (-e "$file");
}
print "done\n";

copy("$curdir/game/namescnf.dst", "$targetdir/names.cnf") unless (-e "$targetdir/names.cnf");

print "Installing restart script.\n";
copy("$curdir/game/restart.dst", "$targetdir/restart") unless (-e "$targetdir/restart");
chmod(0744,"$targetdir/restart");
print "Customization complete for $targetdir/\n";

exit 0;
