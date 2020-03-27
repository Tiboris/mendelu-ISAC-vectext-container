FROM registry.fedoraproject.org/fedora:31

# VecText specific

# RUN dnf update -y

RUN dnf install xorg-x11-* perl -y

RUN dnf install patch libX11-devel zlib-devel libpng perl-Tk-* -y

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
WORKDIR /usr/local/share/perl5/5.30/Tk/
# WORKDIR /usr/lib/perl5/site_perl/5.30.2/Tk/
COPY ./FileDialog.patched /
RUN diff -u FileDialog.pm /FileDialog.patched > /FileDialog.patch  || echo "Patch generated"
RUN patch --verbose -p0 --fuzz=0 < /FileDialog.patch
# RUN cat /usr/local/lib/perl5/site_perl/5.30.2/Tk/FileDialog.pm | grep '\^W'

WORKDIR /usr/src/VecText

USER 1000

# ENTRYPOINT /usr/bin/dumb-init vncserver $DISPLAY -fg -Log *:stderr:100

CMD [ "perl", "./vectext.pl" ]
