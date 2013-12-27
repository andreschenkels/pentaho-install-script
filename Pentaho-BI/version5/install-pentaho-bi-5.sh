#!/bin/bash
################################################################################
# Script for Installation: Pentaho BI 5.0 Server CE on Ubuntu 12.04 LTS
# Author: André Schenkels, ICTSTUDIO 2013
#-------------------------------------------------------------------------------
#
# This script will install Pentaho BI Server CE with PostgreSQL server 9.2 on
# clean Ubuntu 12.04 Server
#-------------------------------------------------------------------------------
# USAGE:
#
# ./install-pentaho-bi-5.sh
#
# EXAMPLE:
# install-pentaho-bi-5.sh
#
################################################################################
 
##fixed parameters
#pentaho user
PENT_USER="pentaho_user"
PENT_HOME="/opt/pentaho"
PENT_CONFIG="pentaho-server"

#choose postgresql version [8.4, 9.1, 9.2 or 9.3]
PG_VERSION="9.2"

#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------
echo -e "\n---- Install PostgreSQL Server $PG_VERSION  ----"
sudo wget -O - http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | sudo apt-key add -
sudo su root -c "echo 'deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main' >> /etc/apt/sources.list.d/pgdg.list"
sudo su root -c "echo 'Package: *' >> /etc/apt/preferences.d/pgdg.pref"
sudo su root -c "echo 'Pin: release o=apt.postgresql.org' >> /etc/apt/preferences.d/pgdg.pref"
sudo su root -c "echo 'Pin-Priority: 500' >> /etc/apt/preferences.d/pgdg.pref"
yes | sudo apt-get update
yes | sudo apt-get install pgdg-keyring
yes | sudo apt-get install postgresql-$PG_VERSION
	
echo -e "\n---- PostgreSQL $PG_VERSION Settings  ----"
sudo sed -i s/"#listen_addresses = 'localhost'"/"listen_addresses = '*'"/g /etc/postgresql/$PG_VERSION/main/postgresql.conf

echo -e "\n---- Creating the Pentaho PostgreSQL User ----"
sudo su - postgres -c "createuser -s $PENT_USER" 2> /dev/null || true

#--------------------------------------------------
# Install Dependencies
#--------------------------------------------------
echo -e "\n---- Install packages ----"
yes | sudo apt-get install wget openjdk-6-jdk unzip
        
echo -e "\n---- Set environment ----"
sudo su root -c "echo 'export JAVA_HOME=\"/usr/lib/jvm/java-1.6.0-openjdk-amd64\"' >> /etc/environment"
        
echo -e "\n---- Create Pentaho system user ----"
sudo adduser --system --quiet --shell=/bin/bash --home=$PENT_HOME --gecos 'Pentaho' --group $PENT_USER

#--------------------------------------------------
# Install Pentaho
#--------------------------------------------------
echo -e "\n==== Installing Pentaho Server ===="

echo -e "\n---- Getting latest stable from sourceforge ----"
sudo su root -c "wget http://freefr.dl.sourceforge.net/project/pentaho/Business%20Intelligence%20Server/5.0.1-stable/biserver-ce-5.0.1-stable.zip"
sudo su root -c "unzip biserver-ce-5.0.1-stable.zip -d $PENT_HOME"

echo -e "* Setup PostgreSQL Server for Pentaho"
sudo su postgres -c "psql -a -f $PENT_HOME/biserver-ce/data/postgresql/create_quartz_postgresql.sql"
sudo su postgres -c "psql -a -f $PENT_HOME/biserver-ce/data/postgresql/create_repository_postgresql.sql"
sudo su postgres -c "psql -a -f $PENT_HOME/biserver-ce/data/postgresql/create_repository_postgresql.sql"

echo -e "* Add PostgreSQL JDBC driver to Pentaho Server"
sudo su root -c "wget jdbc.postgresql.org/download/postgresql-9.2-1003.jdbc4.jar"
sudo su root -c "mv postgresql-9.2-1003.jdbc4.jar /usr/share/java/postgresql-9.2-1003.jdbc4.jar"
sudo su root -c "ln -s /usr/share/java/postgresql-9.2-1003.jdbc4.jar /usr/share/java/postgresql-9.2-jdbc4.jar "
sudo su root -c "ln -s /usr/share/java/postgresql-9.2-jdbc4.jar $PENT_HOME/biserver-ce/tomcat/lib/postgresql-9.2-jdbc4.jar"

echo -e "* Making the .sh files executable"
sudo su root -c "chmod +x /opt/pentaho/biserver-ce/*.sh"

echo -e "Changing the HSQL to PostgreSQL"
echo -e "* Change the pentaho tomcat context.xml file (/opt/pentaho/biserver-ce/tomcat/webapps/pentaho/META-INF/context.xml)"
sudo sed -i s/"org.hsqldb.jdbcDriver"/"org.postgresql.Driver"/g $PENT_HOME/biserver-ce/tomcat/webapps/pentaho/META-INF/context.xml
sudo sed -i s/"jdbc:hsqldb:hsql:\/\/localhost\/hibernate"/"jdbc:postgresql\/\/localhost:5432\/hibernate"/g $PENT_HOME/biserver-ce/tomcat/webapps/pentaho/META-INF/context.xml
sudo sed -i s/"select count(\*) from INFORMATION_SCHEMA.SYSTEM_SEQUENCES"/"select 1"/g $PENT_HOME/biserver-ce/tomcat/webapps/pentaho/META-INF/context.xml
sudo sed -i s/"org.hsqldb.jdbcDriver"/"org.postgresql.Driver"/g $PENT_HOME/biserver-ce/tomcat/webapps/pentaho/META-INF/context.xml
sudo sed -i s/"jdbc:hsqldb:hsql:\/\/localhost\/quartz"/"jdbc:postgresql\/\/localhost:5432\/quartz"/g $PENT_HOME/biserver-ce/tomcat/webapps/pentaho/META-INF/context.xml
sudo sed -i s/"select count(\*) from INFORMATION_SCHEMA.SYSTEM_SEQUENCES"/"select 1"/g $PENT_HOME/biserver-ce/tomcat/webapps/pentaho/META-INF/context.xml

echo -e "* Change the hibernate config files (/opt/pentaho/biserver-ce/pentaho-solutions/system/applicationContext-spring-security-hibernate.properties)"
sudo sed -i s/"org.hsqldb.jdbcDriver"/"org.postgresql.Driver"/g $PENT_HOME/biserver-ce/pentaho-solutions/system/applicationContext-spring-security-hibernate.properties
sudo sed -i s/"jdbc:hsqldb:hsql:\/\/localhost\/hibernate"/"jdbc:postgresql\/\/localhost:5432\/hibernate"/g $PENT_HOME/biserver-ce/pentaho-solutions/system/applicationContext-spring-security-hibernate.properties

echo -e "* Change the hibernate config files (/opt/pentaho/biserver-ce/pentaho-solutions/system/hibernate/hibernate-settings.xml)"
sudo sed -i s/"system\/hibernate\/hsql.hibernate.cfg.xml"/"system\/hibernate\/postgresql.hibernate.cfg.xml"/g $PENT_HOME/biserver-ce/pentaho-solutions/system/hibernate/hibernate-settings.xml

echo -e "* Change the hibernate config files (/opt/pentaho/biserver-ce/pentaho-solutions/system/simple-jndi/jdbc.properties)"
sudo sed -i s/"SampleData\/type=javax.sql.DataSource"/"#SampleData\/type=javax.sql.DataSource"/g $PENT_HOME/biserver-ce/pentaho-solutions/system/simple-jndi/jdbc.properties
sudo sed -i s/"SampleData\/driver=org.hsqldb.jdbcDriver"/"#SampleData\/driver=org.hsqldb.jdbcDriver"/g $PENT_HOME/biserver-ce/pentaho-solutions/system/simple-jndi/jdbc.properties
sudo sed -i s/"SampleData\/url=jdbc:hsqldb:hsql:\/\/localhost\/sampledata"/"#SampleData\/url=jdbc:hsqldb:hsql:\/\/localhost\/sampledata"/g $PENT_HOME/biserver-ce/pentaho-solutions/system/simple-jndi/jdbc.properties
sudo sed -i s/"SampleData\/user=pentaho_user"/"#SampleData\/user=pentaho_user"/g $PENT_HOME/biserver-ce/pentaho-solutions/system/simple-jndi/jdbc.properties
sudo sed -i s/"SampleData\/password=password"/"#SampleData\/password=password"/g $PENT_HOME/biserver-ce/pentaho-solutions/system/simple-jndi/jdbc.properties
sudo sed -i s/"Hibernate\/driver=org.hsqldb.jdbcDriver"/"Hibernate\/driver=org.postgresql.Driver"/g $PENT_HOME/biserver-ce/pentaho-solutions/system/simple-jndi/jdbc.properties
sudo sed -i s/"Hibernate\/url=jdbc:hsqldb:hsql:\/\/localhost\/hibernate"/"Hibernate\/url=jdbc:postgresql:\/\/localhost:5432\/hibernate"/g $PENT_HOME/biserver-ce/pentaho-solutions/system/simple-jndi/jdbc.properties
sudo sed -i s/"Quartz\/driver=org.hsqldb.jdbcDriver"/"Quartz\/driver=org.postgresql.Driver"/g $PENT_HOME/biserver-ce/pentaho-solutions/system/simple-jndi/jdbc.properties
sudo sed -i s/"Quartz\/url=jdbc:hsqldb:hsql:\/\/localhost\/quartz"/"Quartz\/url=jdbc:postgresql:\/\/localhost:5432\/quartz"/g $PENT_HOME/biserver-ce/pentaho-solutions/system/simple-jndi/jdbc.properties
sudo sed -i s/"Shark\/type=javax.sql.DataSource"/"#Shark\/type=javax.sql.DataSource"/g $PENT_HOME/biserver-ce/pentaho-solutions/system/simple-jndi/jdbc.properties
sudo sed -i s/"Shark\/driver=org.hsqldb.jdbcDriver"/"#Shark\/driver=org.hsqldb.jdbcDriver"/g $PENT_HOME/biserver-ce/pentaho-solutions/system/simple-jndi/jdbc.properties
sudo sed -i s/"Shark\/url=jdbc:hsqldb:hsql:\/\/localhost\/shark"/"#Shark\/url=jdbc:hsqldb:hsql:\/\/localhost\/shark"/g $PENT_HOME/biserver-ce/pentaho-solutions/system/simple-jndi/jdbc.properties
sudo sed -i s/"Shark\/user=sa"/"#Shark\/user=sa"/g $PENT_HOME/biserver-ce/pentaho-solutions/system/simple-jndi/jdbc.properties
sudo sed -i s/"Shark\/password="/"#Shark\/password="/g $PENT_HOME/biserver-ce/pentaho-solutions/system/simple-jndi/jdbc.properties
sudo sed -i s/"SampleDataAdmin\/type=javax.sql.DataSource"/"#SampleDataAdmin\/type=javax.sql.DataSource"/g $PENT_HOME/biserver-ce/pentaho-solutions/system/simple-jndi/jdbc.properties
sudo sed -i s/"SampleDataAdmin\/driver=org.hsqldb.jdbcDriver"/"#SampleDataAdmin\/driver=org.hsqldb.jdbcDriver"/g $PENT_HOME/biserver-ce/pentaho-solutions/system/simple-jndi/jdbc.properties
sudo sed -i s/"SampleDataAdmin\/url=jdbc:hsqldb:hsql:\/\/localhost\/sampledata"/"#SampleDataAdmin\/url=jdbc:hsqldb:hsql:\/\/localhost\/sampledata"/g $PENT_HOME/biserver-ce/pentaho-solutions/system/simple-jndi/jdbc.properties
sudo sed -i s/"SampleDataAdmin\/user=pentaho_admin"/"#SampleDataAdmin\/user=pentaho_admin"/g $PENT_HOME/biserver-ce/pentaho-solutions/system/simple-jndi/jdbc.properties
sudo sed -i s/"SampleDataAdmin\/password=password"/"#SampleDataAdmin\/password=password"/g $PENT_HOME/biserver-ce/pentaho-solutions/system/simple-jndi/jdbc.properties

#--------------------------------------------------
# Adding Pentaho Server as a service (initscript)
#--------------------------------------------------
echo -e "* Create init file"

echo '#!/bin/sh -e' >> ~/$PENT_CONFIG
echo '### BEGIN INIT INFO' >> ~/$PENT_CONFIG
echo '# Provides: start-pentaho stop-pentaho' >> ~/$PENT_CONFIG
echo '# Required-Start: networking' >> ~/$PENT_CONFIG
echo '# Default-Start: 2 3 4 5' >> ~/$PENT_CONFIG
echo '# Default-Stop: 0 1 6' >> ~/$PENT_CONFIG
echo '# Description: Pentaho BI Server' >> ~/$PENT_CONFIG
echo '### END INIT INFO' >> ~/$PENT_CONFIG
echo '' >> ~/$PENT_CONFIG
echo "export BISERVER_HOME=$PENT_HOME/biserver-ce" >> ~/$PENT_CONFIG
echo 'export JAVA_HOME="/usr/lib/jvm/java-1.6.0-openjdk-amd64"' >> ~/$PENT_CONFIG
echo 'export JRE_HOME="/usr/lib/jvm/java-1.6.0-openjdk-amd64/jre"' >> ~/$PENT_CONFIG
echo '' >> ~/$PENT_CONFIG
echo 'case "$1" in' >> ~/$PENT_CONFIG
echo ''start')' >> ~/$PENT_CONFIG
echo '  cd $BISERVER_HOME' >> ~/$PENT_CONFIG
echo '  ./start-pentaho.sh' >> ~/$PENT_CONFIG
echo ';;' >> ~/$PENT_CONFIG
echo ''stop')' >> ~/$PENT_CONFIG
echo '  cd $BISERVER_HOME' >> ~/$PENT_CONFIG
echo '  ./stop-pentaho.sh' >> ~/$PENT_CONFIG
echo ';;' >> ~/$PENT_CONFIG
echo '*)' >> ~/$PENT_CONFIG
echo 'echo "Usage: $0 { start | stop }"' >> ~/$PENT_CONFIG
echo ';;' >> ~/$PENT_CONFIG
echo 'esac' >> ~/$PENT_CONFIG
echo 'exit 0' >> ~/$PENT_CONFIG

echo -e "* Security Init File"
sudo mv ~/$PENT_CONFIG /etc/init.d/$PENT_CONFIG
sudo chmod 755 /etc/init.d/$PENT_CONFIG
sudo chown root: /etc/init.d/$PENT_CONFIG

echo -e "* Start Pentaho Server on Startup"
sudo update-rc.d $PENT_CONFIG defaults
 
echo "Done! You can start Pentaho Server by using the command /etc/init.d/"