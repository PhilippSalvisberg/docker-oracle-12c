FROM phsalvisberg/oracle12ee:v2.2.3

MAINTAINER philipp.salvisberg@gmail.com

# environment variables (defaults for DBCA and entrypoint.sh)
ENV MULTITENANT=false \
    DBEXPRESS=true \
    APEX=true \
    ORDS=true \
    DBCA_TOTAL_MEMORY=2048 \
    GDBNAME=odb.docker \
    ORACLE_SID=odb \
    SERVICE_NAME=odb.docker \
    PDB_NAME=opdb1 \
    PDB_SERVICE_NAME=opdb1.docker \
    PASS=oracle \
    APEX_PASS=Oracle12c!

# copy all scripts
ADD assets /assets/

# image setup via shell script to reduce layers and optimize final disk usage
RUN /assets/image_setup.sh

# database port, Enterprise Manager Database Express port, ORDS port
EXPOSE 1521 8080 8081

# use ${ORACLE_BASE} without product subdirectory as data volume
# /u01/app/oracle/product is a symbolic link and not part of the volume
VOLUME ["/u01/app/oracle"]

# entrypoint for database creation, startup and graceful shutdown
ENTRYPOINT ["/assets/entrypoint.sh"]
CMD [""]
