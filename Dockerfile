FROM openjdk:8

# Environment variables for the package installations
# Java options
# ENV JAVA_HOME "/usr/lib/jvm/java-8-oracle" \
# ENV PATH $JAVA_HOME/bin:$PATH
# Let the container know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

# Install Java 8
#RUN apt-get update -yq \
	# add Java 8 repository
#	&& apt-get install -yq software-properties-common \
#	&& add-apt-repository -y ppa:webupd8team/java \
#	&& echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections \

	# install Java 8
#	&& apt-get update -yq \
#	&& apt-get install -yq oracle-java8-installer wget \
#	&& update-java-alternatives -s java-8-oracle

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
		    nodejs-legacy \
			screen \
			wget \
			maven

RUN npm install -g http-server bower grunt-cli grunt

# Add MySQL configuration
COPY mysql.cnf /etc/mysql/conf.d/mysql.cnf
COPY mysqld_charset.cnf /etc/mysql/conf.d/mysqld_charset.cnf

#install and configure mysql
RUN apt-get -yq install mysql-server-5.5 && \
     rm /etc/mysql/conf.d/mysqld_safe_syslog.cnf && \
     if [ ! -f /usr/share/mysql/my-default.cnf ] ; then cp /etc/mysql/conf.d/mysql.cnf /usr/share/mysql/my-default.cnf; fi && \
     mysql_install_db > /dev/null 2>&1

#Create file structure
RUN mkdir services && \
	mkdir services/lib && \
	mkdir web && \
 	mkdir source

######## ROLE ##########
 RUN cd source && \
	git clone https://github.com/rwth-acis/ROLE-SDK.git && \
	cd ROLE-SDK && \
	git checkout develop-noDUI && \
 	mvn clean package

RUN cd source/ROLE-SDK/assembly/target && \
	tar -C / -zxvf role-m10-sdk.tar.gz
########################

######## yjs server ###########
RUN npm install -g y-websockets-server
########################

######## CAE ###########
RUN cd source && \
	git clone https://github.com/rwth-acis/CAE-Model-Persistence-Service.git && \
	git clone https://github.com/rwth-acis/CAE-Code-Generation-Service.git && \
	git clone https://github.com/rwth-acis/CAE-Frontend.git && \
	cd CAE-Model-Persistence-Service && \
	ant jar && \
	cp service/*.jar /services/ && \
	cp lib/*.jar /services/lib/ && \
	cd ../CAE-Code-Generation-Service && \
	ant jar && \
	cp service/*.jar /services/ && \
	cd ../CAE-Frontend
########################

# Create mount point
WORKDIR /build
# Add default appliction structure and deployment script
COPY build/ ./
COPY opt/ /opt

RUN chmod +x /opt/cae/deployment.sh
RUN chmod +x /opt/startup.sh

# #Environment variables for the deployment script
# # Mysql options
# ENV MYSQL_USER cae-user
# ENV MYSQL_PASS cae-user-1234
# ENV ON_CREATE_DB cae-schema
# # Urls
# ENV JENKINS_URL http://192.168.2.101:8000
# ENV DOCKER_URL http://192.168.2.101
# ENV MICROSERVICE_PORT 8086
# ENV HTTP_PORT 8087

# #CMD "/opt/cae/deployment.sh"

# EXPOSE 8086
# EXPOSE 8087

EXPOSE 80
EXPOSE 8073
EXPOSE 1234

WORKDIR /

CMD "/opt/startup.sh"

