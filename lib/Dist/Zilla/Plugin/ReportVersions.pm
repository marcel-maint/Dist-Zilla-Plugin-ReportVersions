use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::ReportVersions;
# ABSTRACT: Write a test that reports used module versions
use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';

__PACKAGE__->meta->make_immutable;
no Moose;
1;

=begin :prelude

=for test_synopsis
1;
__END__

=end :prelude

=head1 SYNOPSIS

In C<dist.ini>:

    [ReportVersions]

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
following file:

  t/000-report-versions.t

The C<000> prefix is chosen so it runs first to make sure it shows up in CPAN
tester reports.

=cut

__DATA__
___[ t/000-report-versions.t ]___
#!perl
use warnings;
use strict;
use Test::More 0.94;

BEGIN {

    # Skip modules that either don't want to be loaded directly, such as
    # Module::Install, or that mess with the test count, such as the Test::*
    # modules listed here.
    #
    # Moose::Role conflicts if Moose is loaded as well, but Moose::Role is in
    # the Moose distribution and it's certain that someone who uses
    # Moose::Role also uses Moose somewhere, so if we disallow Moose::Role,
    # we'll still get the relevant version number.

    my %skip = map { $_ => 1 } qw(
        App::FatPacker
        Class::Accessor::Classy
        Devel::Cover
        Module::Install
        Moose::Role
        POE::Loop::Tk
        Template::Test
        Term::ReadLine::Gnu
        Test::Kwalitee
        Test::Pod::Coverage
        Test::Portability::Files
        Test::YAML::Meta
        open
    );

    my $Test = Test::Builder->new;

    eval { require CPAN::Meta::YAML };
    $Test->plan( skip_all => "CPAN::Meta::YAML not installed" ) if $@;

    $Test->plan( skip_all => "META.yml could not be found" )
        unless -f 'META.yml' and -r _;

    my $meta = ( CPAN::Meta::YAML->read('META.yml') )->[0];
    my %requires;
    for my $require_key ( grep {/requires/} keys %$meta ) {
        my %h = %{ $meta->{$require_key} };
        $requires{$_}++ for keys %h;
    }
    delete $requires{perl};

    diag("Testing with Perl $], $^X");
    for my $module ( sort keys %requires ) {
        if ( $skip{$module} ) {
            note "$module doesn't want to be loaded directly, skipping";
            next;
        }
        local $SIG{__WARN__} = sub { note "$module: $_[0]" };
        require_ok $module or BAIL_OUT("can't load $module");
        my $version = $module->VERSION;
        $version = 'undefined' unless defined $version;
        diag("    $module version is $version");
    }
    done_testing;
}
