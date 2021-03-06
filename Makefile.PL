use 5.006;
use strict;
use warnings;

use Config qw(%Config);
use ExtUtils::MakeMaker qw(&WriteMakefile &neatvalue);

unless ($^O eq "MSWin32" || $^O eq "cygwin") {
    die "OS unsupported\n";
}

my $INSTDIR = grep(/INSTALLDIRS=perl/i, @ARGV) ? "lib" : "site\\lib";

my %param =
(
    NAME         => 'Win32::OLE',
    VERSION_FROM => 'lib/Win32/OLE.pm',
    XS           => { 'OLE.xs' => 'OLE.cpp' },
    # Without the next line MakeMaker will not export the bootstrap function
    # (because we are using FUNCLIST too).
    DL_FUNCS     => { 'Win32::OLE' => [] },
    clean        => { FILES => 'test.xls' },
    LICENSE => 'perl',
    AUTHOR       => [
        'Jan Dubois <jand@activestate.com>',
    ],
    ABSTRACT     => 'OLE Automation extensions',
    MIN_PERL_VERSION => 5.006,
    META_MERGE => {
        resources => {
            repository => 'https://libwin32.googlecode.com/svn/trunk/Win32-OLE',
            license => 'http://dev.perl.org/licenses/',
            homepage => 'http://code.google.com/p/libwin32/',
        },
    },
);
my $FUNCLIST = [qw(SetSVFromVariant SetSVFromVariantEx SetVariantFromSV CreatePerlObject)];
$param{FUNCLIST} = $FUNCLIST if eval "$ExtUtils::MakeMaker::VERSION" >= 5.4302;
WriteMakefile1(%param);

sub MY::xs_c {
    '
.xs.cpp:
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(XSUBPP) $(XSPROTOARG) $(XSUBPPARGS) $*.xs >xstmp.c && $(MV) xstmp.c $*.cpp
';
}

sub MY::dlsyms {
    my($self,%attribs) = @_;

    my($funcs) = $attribs{DL_FUNCS} || $self->{DL_FUNCS} || {};
    my($vars)  = $attribs{DL_VARS} || $self->{DL_VARS} || [];
    my($imports)  = $attribs{IMPORTS} || $self->{IMPORTS} || {};
    my(@m);
    (my $boot = $self->{NAME}) =~ s/:/_/g;

    if (not $self->{SKIPHASH}{'dynamic'}) {
	push(@m,"
$self->{BASEEXT}.def: Makefile.PL
",
     q!	$(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" -MExtUtils::Mksymlists \\
     -e "Mksymlists('NAME' => '!, $self->{NAME},
     q!', 'DLBASE' => '!,$self->{DLBASE},
     q!', 'DL_FUNCS' => !,neatvalue($funcs),
     q!, 'FUNCLIST' => !,neatvalue($FUNCLIST),
     q!, 'IMPORTS' => !,neatvalue($imports),
     q!, 'DL_VARS' => !, neatvalue($vars), q!);"
!);
    }
    join('',@m);
}

sub WriteMakefile1 {  #Written by Alexandr Ciornii, version 0.23. Added by eumm-upgrade.
    my %params=@_;
    my $eumm_version=$ExtUtils::MakeMaker::VERSION;
    $eumm_version=eval $eumm_version;
    die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
    die "License not specified" if not exists $params{LICENSE};
    if ($params{AUTHOR} and ref($params{AUTHOR}) eq 'ARRAY' and $eumm_version < 6.5705) {
        $params{META_ADD}->{author}=$params{AUTHOR};
        $params{AUTHOR}=join(', ',@{$params{AUTHOR}});
    }
    if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
        #EUMM 6.5502 has problems with BUILD_REQUIRES
        $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
        delete $params{BUILD_REQUIRES};
    }
    delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
    delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
    delete $params{META_MERGE} if $eumm_version < 6.46;
    delete $params{META_ADD} if $eumm_version < 6.46;
    delete $params{LICENSE} if $eumm_version < 6.31;
    delete $params{AUTHOR} if $] < 5.005;
    delete $params{ABSTRACT_FROM} if $] < 5.005;
    delete $params{BINARY_LOCATION} if $] < 5.005;

    WriteMakefile(%params);
}

