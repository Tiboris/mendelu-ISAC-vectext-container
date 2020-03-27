FROM registry.fedoraproject.org/fedora:31

RUN dnf -y install \
    xorg-x11-* \
    perl patch \
    libX11-devel \
    zlib-devel \
    libpng \
    perl-Tk-*

# VecText specific
RUN [ "cpan", "install", "YAML"]
RUN [ "cpan", "install", "Tk::FileDialog"]
RUN [ "cpan", "install", "Tk::DirSelect"]
RUN [ "cpan", "install", "-T", "Tk::Help"]
RUN [ "cpan", "install",  "List::Util"]
RUN [ "cpan", "install",  "Cwd"]
RUN [ "cpan", "install",  "URI::Find"]
RUN [ "cpan", "install",  "Lingua::Stem::Snowball"]
RUN [ "cpan", "install",  "Encode::Unicode"]

COPY ./VecText /usr/src/VecText

# Patch the script
RUN dnf install /usr/bin/diff -y
# LOCATION when dnf is used to install Tk
ENV TK_LOCATION /usr/local/share/perl5/5.30/Tk
# LOCATION when cpan is used:
# ENV TK_LOCATION /usr/lib/perl5/site_perl/5.30.2/Tk
WORKDIR $TK_LOCATION
COPY ./FileDialog.patched /
RUN diff -u FileDialog.pm /FileDialog.patched > /FileDialog.patch  || echo "Patch generated"
RUN patch --verbose -p0 --fuzz=0 < /FileDialog.patch
# check if patched
RUN cat $TK_LOCATION/FileDialog.pm | grep '\^W'

WORKDIR /usr/src/VecText

USER 1000

CMD [ "perl", "./vectext.pl" ]
