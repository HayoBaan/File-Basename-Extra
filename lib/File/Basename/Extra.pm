package File::Basename::Extra;
use strict;
use warnings;

# ABSTRACT: Extension to File::Basename, adds named access to file parts and handling of filename suffixes
# VERSION

=head1 SYNOPSIS

  # Note: by default no symbols get exported so make sure you export
  # the ones you need!
  use File::Basename::Extra qw(basename);

  # basename and friends
  my $file      = basename('/foo/bar/file.txt');          # "file.txt"
  my $fileext   = basename_suffix('/foo/bar/file.txt');   # ".txt"
  my $filenoext = basename_nosuffix('/foo/bar/file.txt'); # "file"

  # dirname
  my $dir       = dirname('/foo/bar/file.txt');           # "/foo/bar/"

  # fileparse
  my ($filename, $dirs, $suffix) = fileparse('/foo/bar/file.txt', qr/\.[^.]*/);
                                                          # ("file", "/foo/bar/", ".txt")

  # pathname
  my $path      = pathname('/foo/bar/file.txt');          # "/foo/bar/"

  # fullname and friends
  my $full      = fullname('/foo/bar/file.txt');          # "/foo/bar/file.txt"
  my $fullext   = fullname_suffix('/foo/bar/file.txt');   # ".txt"
  my $fullnoext = fullname_nosuffix('/foo/bar/file.txt'); # "/foo/bar/file"

  # getting/setting the default suffix patterns
  my @patterns = default_suffix_patterns(); # Returns the currently active patterns

  # setting the default suffix patterns
  my @previous = default_suffix_patterns(qr/[._]bar/, '\.baz');
                 # Now only .bar, _bar, and .baz are matched suffixes

=head1 DESCRIPTION

This module provides functionalty for handling file name suffixes (aka
file name extensions).

=head1 SEE ALSO

L<File::Basename> for the suffix matching and platform specific details.

=cut

use File::Basename;

our @ISA = qw(Exporter File::Basename);
our @EXPORT = ();
our @EXPORT_OK = (@File::Basename::EXPORT,
                  qw(basename_suffix basename_nosuffix
                     filename filename_suffix filename_nosuffix
                     pathname
                     fullname fullname_suffix fullname_nosuffix
                     default_suffix_patterns));

my @default_suffix_patterns = (qr/\.[^.]*/);

# Special version of the fileparse function, used in the basename versions of the functions
sub _basename_fileparse {
    my $path = shift;
    my @suffix_patterns = @_ ? map { "\Q$_\E" } @_ : @default_suffix_patterns;

    # "hidden" function in File::Basename, strips final path separator
    # (e.g., / or \)
    File::Basename::_strip_trailing_sep($path);

    my($basename, $dirname, $suffix) = fileparse( $path, @suffix_patterns );

    # The suffix is not stripped if it is identical to the remaining
    # characters in string.
    if( length $suffix and !length $basename ) {
        $basename = $suffix;
        $suffix = '';
    }

    # Ensure that basename '/' == '/'
    if( !length $basename ) {
        $basename = $dirname;
        $dirname = '';
    }

    return ($basename, $dirname, $suffix);
}

=func fileparse FILEPATH

=func fileparse FILEPATH PATTERN_LIST

=func basename FILEPATH

=func basename FILEPATH PATTERN_LIST

=func dirname FILEPATH

=func fileparse_set_fstype FSTYPE

These functions are exactly the same as the corresponding ones from
L<File::Basename> except that they aren't exported by default.

=func basename_suffix FILEPATH

=func basename_suffix FILEPATH PATTERN_LIST

Returns the file name suffix part of the given filepath. The default
suffix patterns are used if none are provided. Behaves the same as
C<basename>, i.e., it uses the last last level of a filepath as
filename, even if the last level is clearly directory.

Also, like C<basename>, files that consist of only a matched suffix
are treated as if they do not have a suffix. So, using the default
suffix pattern, C<basename_suffix('/Users/home/.profile')> would
return an empty string.

Note: Like the original C<basename> function from L<File::Basename>,
suffix patterns are automatically escaped so pattern C<.bar> only
matches C<.bar> and not e.g., C<_bar> (this is B<not> done for the
default suffix patterns, nor for patterns provided to the non-basename
family functions of this module!).

=cut

sub basename_suffix {
    my (undef, undef, $suffix) = _basename_fileparse(@_);
    return $suffix;
}

=func basename_nosuffix FILEPATH

=func basename_nosuffix FILEPATH PATTERN_LIST

Acts basically the same as the original C<basename> function, except
that the default suffix patterns are used to strip the name of its
suffixes when none are provided.

Also, like C<basename>, files that consist of only a matched suffix
are treated as if they do not have a suffix. So, using the default
suffix pattern, C<basename_nosuffix('/Users/home/.profile')> would
return C<.profile>.

Note: Like the original C<basename> function from L<File::Basename>,
suffix patterns are automatically escaped so pattern C<.bar> only
matches C<.bar> and not e.g., C<_bar> (this is B<not> done for the
default suffix patterns, nor for patterns provided to the non-basename
family of functions of this module!).

=cut

sub basename_nosuffix {
    my ($name, undef, undef) = _basename_fileparse(@_);
    return $name;
}

=func filename FILEPATH

=func filename FILEPATH PATTERN_LIST

Returns just the filename of the filepath, optionally stripping the
suffix when it matches a provided suffix patterns. Basically the same
as calling C<fileparse> in scalar context.

=cut

sub filename {
    my ($filename, undef, undef) = fileparse(@_);
    return $filename;
}

=func filename_suffix FILEPATH

=func filename_suffix FILEPATH PATTERN_LIST

Returns the matched suffix of the filename. The default suffix
patterns are used when none are provided.

=cut

sub filename_suffix {
    my $fullname = shift;
    my (undef, undef, $suffix) = fileparse($fullname, (@_ ? @_ : @default_suffix_patterns));
    return $suffix;
}

=func filename_nosuffix FILEPATH

=func filename_nosuffix FILEPATH PATTERN_LIST

Returns the filename with the the matched suffix stripped. The default
suffix patterns are used when none are provided.

=cut

sub filename_nosuffix {
    my $fullname = shift;
    my ($filename, undef, undef) = fileparse($fullname, (@_ ? @_ : @default_suffix_patterns));
    return $filename;
}

=func pathname FILEPATH

Returns the path part of the file. Contrary to C<dirname>, a filepath
that is clearly a directory, is treated as such (e.g., on Unix,
C<pathname('/foo/bar/')> returns C</foo/bar/>).

=cut

sub pathname {
    my (undef, $pathname, undef) = fileparse(@_);
    return $pathname;
}

=func fullname FILEPATH

=func fullname FILEPATH PATTERN_LIST

Returns the provided filepath, optionally stripping the filename of
its matching suffix.

=cut

sub fullname {
    my $fullname = shift;
    return @_ ? fullname_nosuffix($fullname, @_) : $fullname;
}

=func fullname_suffix FILEPATH

=func fullname_suffix FILEPATH PATTERN_LIST

Synonym for filename_suffix.

=cut

*fullname_suffix = *filename_suffix;

=func fullname_nosuffix FILEPATH

=func fullname_nosuffix FILEPATH PATTERN_LIST

Returns the full filepath with the the matched suffix stripped. The
default suffix patterns are used when none are provided.

=cut

sub fullname_nosuffix {
    my $fullname = shift;
    my $suffix = filename_suffix($fullname, @_);
    $fullname =~ s/\Q$suffix\E$// if $suffix;
    return $fullname;
}

=func default_suffix_patterns

=func default_suffix_patterns NEW_PATTERN_LIST

The default suffix pattern list (see the C<fileparse> function in
L<File::Basename> for details) is C<qr/\.[^.]*/>. Meaning that this
defines the suffix as the part of the filename from (and including)
the last dot. In other words, the part of a filename that is popularly
known as the file extension.

You can alter the suffix matching by proving this function with a
different pattern list.

This function returns the pattern list that was effective I<before>
optionally changing it.

=cut

sub default_suffix_patterns {
    my @org_suffix_patterns = @default_suffix_patterns;
    @default_suffix_patterns = @_ if @_;
    return @org_suffix_patterns;
}

1;
