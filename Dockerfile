FROM mhart/alpine-node

LABEL maintainer "jonas.koenning@rwth-aachen.de"

# Java Version and other ENV
ENV JAVA_VERSION_MAJOR=8 \
    JAVA_VERSION_MINOR=131 \
    JAVA_VERSION_BUILD=11 \
    JAVA_PACKAGE=jdk \
    JAVA_JCE=unlimited \
    JAVA_HOME=/opt/jdk \
    PATH=${PATH}:/opt/jdk/bin \
    GLIBC_VERSION=2.23-r3 \
    LANG=C.UTF-8

# Environment variables for the deployment script
# Mysql options
ENV MYSQL_USER cae-user
ENV MYSQL_PASS cae-user-1234
ENV ON_CREATE_DB cae-schema
# Urls
ENV JENKINS_URL http://192.168.2.101:8000
ENV DOCKER_URL http://192.168.2.101
ENV MICROSERVICE_PORT 8086
ENV HTTP_PORT 8087

# do all in one step
# TODO: Image can be made leaner here by removing parts of the java installation
RUN set -ex && \
    apk upgrade --update && \
    apk add --update libstdc++ curl ca-certificates bash && \
    for pkg in glibc-${GLIBC_VERSION} glibc-bin-${GLIBC_VERSION} glibc-i18n-${GLIBC_VERSION}; do curl -sSL https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/${pkg}.apk -o /tmp/${pkg}.apk; done && \
    apk add --allow-untrusted /tmp/*.apk && \
    rm -v /tmp/*.apk && \
    ( /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 C.UTF-8 || true ) && \
    echo "export LANG=C.UTF-8" > /etc/profile.d/locale.sh && \
    /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib && \
    mkdir /opt && \
    curl -jksSLH "Cookie: oraclelicense=accept-securebackup-cookie" -o /tmp/java.tar.gz \
      http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-b${JAVA_VERSION_BUILD}/d54c1d3a095b4ff2b6607d096fa80163/${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz && \
    gunzip /tmp/java.tar.gz && \
    tar -C /opt -xf /tmp/java.tar && \
    ln -s /opt/jdk1.${JAVA_VERSION_MAJOR}.0_${JAVA_VERSION_MINOR} /opt/jdk && \
    #find /opt/jdk/ -maxdepth 1 -mindepth 1 | grep -v jre | xargs rm -rf && \
    cd /opt/jdk/ && ln -s ./jre/bin ./bin && \
    if [ "${JAVA_JCE}" == "unlimited" ]; then echo "Installing Unlimited JCE policy" && \
      curl -jksSLH "Cookie: oraclelicense=accept-securebackup-cookie" -o /tmp/jce_policy-${JAVA_VERSION_MAJOR}.zip \
        http://download.oracle.com/otn-pub/java/jce/${JAVA_VERSION_MAJOR}/jce_policy-${JAVA_VERSION_MAJOR}.zip && \
      cd /tmp && unzip /tmp/jce_policy-${JAVA_VERSION_MAJOR}.zip && \
      cp -v /tmp/UnlimitedJCEPolicyJDK8/*.jar /opt/jdk/jre/lib/security/; \
    fi && \
    sed -i s/#networkaddress.cache.ttl=-1/networkaddress.cache.ttl=10/ $JAVA_HOME/jre/lib/security/java.security && \
    apk del curl glibc-i18n && \
    #rm -rf   /opt/jdk/jre/plugin \
    #        /opt/jdk/jre/bin/javaws \
    #        /opt/jdk/jre/bin/jjs \
    #        /opt/jdk/jre/bin/orbd \
    #        /opt/jdk/jre/bin/pack200 \
    #        /opt/jdk/jre/bin/policytool \
    #        /opt/jdk/jre/bin/rmid \
    #        /opt/jdk/jre/bin/rmiregistry \
    #        /opt/jdk/jre/bin/servertool \
    #        /opt/jdk/jre/bin/tnameserv \
    #        /opt/jdk/jre/bin/unpack200 \
    #        /opt/jdk/jre/lib/javaws.jar \
    #        /opt/jdk/jre/lib/deploy* \
    #        /opt/jdk/jre/lib/desktop \
    #        /opt/jdk/jre/lib/*javafx* \
    #        /opt/jdk/jre/lib/*jfx* \
    #        /opt/jdk/jre/lib/amd64/libdecora_sse.so \
    #        /opt/jdk/jre/lib/amd64/libprism_*.so \
    #        /opt/jdk/jre/lib/amd64/libfxplugins.so \
    #        /opt/jdk/jre/lib/amd64/libglass.so \
    #        /opt/jdk/jre/lib/amd64/libgstreamer-lite.so \
    #        /opt/jdk/jre/lib/amd64/libjavafx*.so \
    #        /opt/jdk/jre/lib/amd64/libjfx*.so \
    #        /opt/jdk/jre/lib/ext/jfxrt.jar \
    #        /opt/jdk/jre/lib/ext/nashorn.jar \
    #        /opt/jdk/jre/lib/oblique-fonts \
    #        /opt/jdk/jre/lib/plugin.jar \
    rm -rf   /tmp/* /var/cache/apk/* && \
    echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf

# Let the container know that there is no tty
#ENV DEBIAN_FRONTEND noninteractive

RUN apk update && apk upgrade

RUN apk add --update python g++ git apache-ant maven make bash

RUN npm install -g http-server bower grunt-cli grunt && \
    # --unsafe-perm fixes gyp issue
    npm install -g --unsafe-perm y-websockets-server

RUN apk add --update mariadb mariadb-client

# Add MySQL configuration
COPY mysql.cnf /etc/mysql/my.cnf
COPY mysqld_charset.cnf /etc/mysql/mysqld_charset.cnf

# #install and configure mysql
# RUN apt-get -yq install mysql-server-5.5 && \
#      rm /etc/mysql/conf.d/mysqld_safe_syslog.cnf && \
#      if [ ! -f /usr/share/mysql/my-default.cnf ] ; then cp /etc/mysql/conf.d/mysql.cnf /usr/share/mysql/my-default.cnf; fi && \
RUN mysql_install_db > /dev/null 2>&1

# #Create file structure
RUN mkdir CAE && \
    mkdir CAE/lib && \
    mkdir CAE/etc && \
    mkdir web && \
    mkdir source && \
    mkdir ROLE

# ######## ROLE ##########
ADD role-m10-sdk.tar.gz /ROLE

######## CAE ###########
RUN cd source && \
  git clone https://github.com/rwth-acis/CAE-Model-Persistence-Service.git && \
 	git clone https://github.com/rwth-acis/CAE-Code-Generation-Service.git && \
  git clone https://github.com/rwth-acis/CAE-Frontend.git && \
 	cd CAE-Model-Persistence-Service && \
 	ant jar && \
 	cp service/*.jar /CAE/ && \
 	cp lib/*.jar /CAE/lib/ && \
 	cd ../CAE-Code-Generation-Service && \
 	ant jar && \
 	cp service/*.jar /CAE/ && \
 	cp lib/*.jar /CAE/lib/ && \
	cd ../CAE-Frontend
########################

# Add default appliction structure and deployment script
COPY opt/ /opt

RUN chmod +x /opt/cae/deployment.sh && chmod +x /opt/startup.sh

# EXPOSE 8086
# EXPOSE 8087

EXPOSE 80
EXPOSE 8073
EXPOSE 1234

WORKDIR /

ENTRYPOINT ["/opt/startup.sh"]
#CMD "bash"
