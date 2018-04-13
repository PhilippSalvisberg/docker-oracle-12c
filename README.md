# DEPRECATION NOTICE
This project has been deprecated in favor of the [docker-odb](https://github.com/PhilippSalvisberg/docker-odb). This repository will not be updated anymore.

# oddgen Demo using an Oracle Database 12.2.0.1 Enterprise Edition

## Content

Dockerfile including scripts to build an image containing the following:

* Oracle Linux 7.4-1.0.4.el7.x86_64
* Oracle Database 12.2.0.1 Enterprise Edition with non-CDB architecture
	* Sample schemas SCOTT, HR, OE, PM, IX, SH, BI (master branch as of build time)
	* APEX 5.1.3 including APEX\_LISTENER and APEX\_REST\_PUBLIC\_USER
	* Oracle REST Data Services 3.0.12
	* FTLDB 1.5.0
	* tePLSQL (master branch as of build time)
	* oddgen example/tutorial schemas ODDGEN, OGDEMO (master branch as of build time)

This image supports CDB and non-CDB architecture. The latter is the default. Please note that the non-CDB architecture is deprecated with Oracle 12.2.0.1. See [Oracle Database Upgrade Guide](http://docs.oracle.com/database/122/UPGRD/deprecated-features-oracle-database-12c-r2.htm#UPGRD-GUID-23F9C9D3-4267-4638-824D-C198D042B05B) for more information.

Due to [OTN Developer License Terms](http://www.oracle.com/technetwork/licenses/standard-license-152015.html) I cannot make this image available on a public Docker registry.

## Installation

### Using Default Settings (recommended)

Complete the following steps to create a new container:

1. Create the container

		docker run -d -p 8080-8081:8080-8081 -p 1521:1521 -h odb --name odb phsalvisberg/oddgendemo

2. wait around **25 minutes** until the Oracle database instance is created and APEX is updated to the latest version. Check logs with ```docker logs -f -t odb```. The container is ready to use when the last line in the log is ```Database ready to use. Enjoy! ;-)```. The container stops if an error occurs. Check the logs to determine how to proceed.

Feel free to stop the docker container after a successful installation with ```docker stop -t 60 odb```. The container should shutdown the database gracefully within the given 60 seconds and persist the data fully (ready for backup). Next time you start the container using ```docker start odb``` the database will start up.


### Options

#### Environment Variables

You may set the environment variables in the docker run statement to configure the container setup process. The following table lists all environment variables with its default values:

Environment variable | Default value | Comments
-------------------- | ------------- | --------
MULTITENANT | ```false``` | Set to ```true``` if you want to create a database with CDB architecture.
DBEXPRESS | ```true``` | Set to ```false``` if you do not want to use Enterprise Manger Database Express.
APEX | ```true``` | Set to ```false``` if you do not want to install Oracle Application Express (container will be created faster).
ORDS | ```true``` | Set to ```false``` if you do not want to install Oracle REST Data Services.
DBCA\_TOTAL\_MEMORY | ```2048```| Memory in kilobytes for the Database Creation Assistent.
GDBNAME | ```odb.docker``` | Global database name, used by DBCA
ORACLE_SID | ```odb```| Oracle System Identifier
SERVICE_NAME | ```odb.docker``` | Oracle Service Name (for the container database)
PDB_NAME | ```opdb1``` | Name of the pluggable database
PDB_SERVICE_NAME | ```opdb1.docker``` | Oracle Service Name for the pluggable database
PASS | ```oracle```| Password for SYS, SYSTEM, APEX_LISTENER, APEX_PUBLIC_USER, APEX_REST_PUBLIC_USER, ORDS_PUBLIC_USER
APEX_PASS | ```Oracle12c!```| Initial APEX ADMIN password

Here's an example run call amending the PASS environment variable skip APEX installation:

```
docker run -e PASS=manager -e APEX=false -d -p 8080-8081:8080-8081 -p 1521:1521 -h odb --name odb phsalvisberg/oddgendemo
```

Here's an other example createing a container database and extending the database port ranges to cover a total of three pluggable databases:

```
docker run -e MULTITENANT=true -d -p 8080-8081:8080-8081 -p 1521-1523:1521-1523 -h ocdb --name ocdb phsalvisberg/oddgendemo
```

#### Volumes

The image defines a volume for ```/u01/app/oracle```. You may map this volume to a storage solution of your choice. Here's an example using a named volume ```odb```:

```
docker run -v odb:/u01/app/oracle -d -p 8080-8081:8080-8081 -p 1521:1521 -h odb --name odb phsalvisberg/oddgendemo
```

Here's an example mapping the local directory ```$HOME/docker/odb/u01/app/oracle``` to ```/u01/app/oracle```.

```
docker run -v $HOME/docker/odb/u01/app/oracle:/u01/app/oracle -d -p 8080-8081:8080-8081 -p 1521:1521 -h odb --name odb phsalvisberg/oddgendemo
```

**Please note**: Volumes mapped to local directories are not stable, at least not in Docker for Mac 1.12.0. E.g. creating a database may never finish. So I recommend not to use local mapped directories for the time being. Alternatively you may use a volume plugin. A comprehensive list of volume plugins is listed [here](https://docs.docker.com/engine/extend/plugins/#volume-plugins).

#### Change Timezone

The default timezone of the container is UTC. To query the available timezones run:

```
docker exec odb ls -RC /usr/share/zoneinfo
```

To change the timezone to "Central European Time (CET)" run the following two commands:

```
docker exec odb unlink /etc/localtime
docker exec odb ln -s /usr/share/zoneinfo/Europe/Zurich /etc/localtime
```

Restart your container to ensure the new setting take effect.

```
docker restart -t 60 odb
```

## Access To Database Services

### Enterprise Manager Database Express

[http://localhost:8080/em/](http://localhost:8080/em/)

User | Password
-------- | -----
system | oracle
sys | oracle


### APEX

- when using ORDS: [http://localhost:8081/ords/](http://localhost:8081/ords/)
- when using EPG: [http://localhost:8080/apex/](http://localhost:8080/apex/)

Property | Value
-------- | -----
Workspace | INTERNAL
User | ADMIN
Password | Oracle12c!

### Database Connections

To access the database e.g. from SQL Developer you configure the following properties:

Property | Value
-------- | -----
Hostname | localhost
Port | 1521
SID | odb
Service | odb.docker

The configured user with their credentials are:

User | Password
-------- | -----
system | oracle
sys | oracle
apex_listener | oracle
apex\_rest\_public\_user | oracle
apex\_public\_user | oracle
ords\_public\_user | oracle
scott | tiger
hr | hr
oe | oe
pm | pm
ix | ix
sh | sh
bi | bi
ftldb | ftldb
teplsql | teplsql
oddgen | oddgen
ogdemo | ogdemo

Use the following connect string to connect as scott via SQL*Plus or SQLcl: ```scott/tiger@localhost/odb.docker```

## Backup

Complete the following steps to backup the data volume:

1. Stop the container with

		docker stop -t 30 odb

2. Backup the data volume to a compressed file ```odb.tar.gz``` in the current directory with a little help from the ubuntu image

		docker run --rm --volumes-from odb -v $(pwd):/backup ubuntu tar czvf /backup/odb.tar.gz /u01/app/oracle

3. Restart the container

		docker start odb

## Restore

Complete the following steps to restore an image from scratch. There are other ways, but this procedure is also applicable to restore a database on another machine:

1. Stop the container with

		docker stop -t 30 odb

2. Remove the container with its associated volume

		docker rm -v odb

3. Remove unreferenced volumes, e.g. explicitly created volumes by previous restores

		docker volume ls -qf dangling=true | xargs docker volume rm

4. Create an empty data volume named ```odb```

		docker volume create --name odb

5. Populate data volume ```odb``` with backup from file ```odb.tar.gz``` with a little help from the ubuntu image

		docker run --rm -v odb:/u01/app/oracle -v $(pwd):/backup ubuntu tar xvpfz /backup/odb.tar.gz -C /

6. Create the container using the ```odb```volume

		docker run -v odb:/u01/app/oracle -d -p 8080-8081:8080-8081 -p 1521:1521 -h odb --name odb phsalvisberg/oddgendemo

7. Check log of ```odb``` container

		docker logs odb

	The end of the log should look as follows:

		Reuse existing database.

		(...)

		Database ready to use. Enjoy! ;-)

## Issues

Please file your bug reports, enhancement requests, questions and other support requests within [Github's issue tracker](https://help.github.com/articles/about-issues/):

* [Existing issues](https://github.com/PhilippSalvisberg/docker-oddgendemo/issues)
* [submit new issue](https://github.com/PhilippSalvisberg/docker-oddgendemo/issues/new)

## Credits
This Dockerfile is based on the following work:

- Maksym Bilenko's GitHub project [sath89/docker-oracle-12c](https://github.com/MaksymBilenko/docker-oracle-12c)
- Frits Hoogland's blog post [Installing the Oracle database in docker](https://fritshoogland.wordpress.com/2015/08/11/installing-the-oracle-database-in-docker/)

## License

docker-oddgendemo is licensed under the Apache License, Version 2.0. You may obtain a copy of the License at <http://www.apache.org/licenses/LICENSE-2.0>.

See [OTN Developer License Terms](http://www.oracle.com/technetwork/licenses/standard-license-152015.html) and [Oracle Database Licensing Information User Manual](https://docs.oracle.com/database/122/DBLIC/Licensing-Information.htm#DBLIC-GUID-B6113390-9586-46D7-9008-DCC9EDA45AB4) regarding Oracle Database licenses.
