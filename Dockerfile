FROM java:8

# Environment variables for the package installations
# Java options
ENV JAVA_HOME "/usr/lib/jvm/java-8-oracle" \
ENV PATH $JAVA_HOME/bin:$PATH
# Let the container know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

# Install Java 8
ONBUILD RUN apt-get update -yq \
	# add Java 8 repository
	&& apt-get install -yq software-properties-common \
	&& add-apt-repository -y ppa:webupd8team/java \
	&& echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections \

	# install Java 8
	&& apt-get update -yq \
	&& apt-get install -yq oracle-java8-installer wget \
	&& update-java-alternatives -s java-8-oracle

# General update packages
RUN sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list
RUN apt-get update -y
RUN apt-get upgrade -y

# Install build tools
RUN apt-get install -y \
                     wget \
                     unzip \
                     npm \
		     nodejs \
		     nodejs-legacy

# Add MySQL configuration
COPY mysql.cnf /etc/mysql/conf.d/mysql.cnf
COPY mysqld_charset.cnf /etc/mysql/conf.d/mysqld_charset.cnf

#install and configure mysql
RUN apt-get -yq install mysql-server-5.5 && \
    rm /etc/mysql/conf.d/mysqld_safe_syslog.cnf && \
    if [ ! -f /usr/share/mysql/my-default.cnf ] ; then cp /etc/mysql/conf.d/mysql.cnf /usr/share/mysql/my-default.cnf; fi && \
    mysql_install_db > /dev/null 2>&1

# Create mount point
WORKDIR /build
# Add default appliction structure and deployment script
COPY build/ ./
COPY opt/ /opt

RUN chmod +x /opt/cae/deployment.sh

#Environment variables for the deployment script
# Mysql options
ENV MYSQL_USER cae-user
ENV MYSQL_PASS cae-user-1234
ENV ON_CREATE_DB cae-schema
# Urls
ENV JENKINS_URL http://192.168.2.101:8000
ENV DOCKER_URL http://192.168.2.101
ENV MICROSERVICE_PORT 8086
ENV HTTP_PORT 8087

CMD "/opt/cae/deployment.sh"

EXPOSE 8086
EXPOSE 8087
