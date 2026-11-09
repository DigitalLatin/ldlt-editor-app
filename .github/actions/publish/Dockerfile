FROM debian:bullseye-slim
RUN apt-get update && apt-get -y install openjdk-17-jdk-headless \
  wget \
  zip \
  git \
  ruby \
  ruby-dev \
  ubuntu-dev-tools
# Packaged Saxon is still v9.x, so we need to get it the hard way
RUN wget -O SaxonHE11.zip https://downloads.sourceforge.net/project/saxon/Saxon-HE/11/Java/SaxonHE11-3J.zip; \ 
  unzip -d SaxonHE11 SaxonHE11.zip; \
  mv SaxonHE11 /usr/share/java/; \
  echo "#! /bin/bash" > /usr/local/bin/saxon \
    && echo "java -jar /usr/share/java/SaxonHE11/saxon-he-11.3.jar \$@" >> /usr/local/bin/saxon \
    && chmod 755 /usr/local/bin/saxon; \
  mkdir /opt/actions; \
  gem install bundler
COPY process.sh /opt/actions/process.sh
ENTRYPOINT ["/opt/actions/process.sh"]
