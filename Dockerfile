FROM perl:latest
RUN [ "cpan", "install", "YAML"]
RUN [ "cpan", "install", "Tk"]
RUN [ "cpan", "install", "Tk::FileDialog"]
RUN [ "cpan", "install", "Tk::DirSelect"]
RUN [ "cpan", "install", "-T", "Tk::Help"]
# RUN [ "cpan", "install", "Win32"]
# RUN [ "cpan", "install", "Win32::LongPath"]
RUN [ "cpan", "install",  "List::Util"]
RUN [ "cpan", "install",  "Cwd"]
RUN [ "cpan", "install",  "URI::Find"]
RUN [ "cpan", "install",  "Lingua::Stem::Snowball"]
RUN [ "cpan", "install",  "Encode::Unicode"]
COPY ./VecText /usr/src/VecText
WORKDIR /usr/src/VecText
CMD [ "perl", "./vectext.pl" ]
