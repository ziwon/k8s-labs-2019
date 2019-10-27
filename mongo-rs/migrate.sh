#!/bin/bash

set -eo

MONGO_SRC_HOST=src-primary.mongo-splash.default.svc.cluster.local
MONGO_SRC_PORT=27017
MONGO_SRC_USER=root
MONGO_SRC_PASS=
MONGO_SRC_DB=

MONGO_DST_HOST=dst-primary.mongo-splash.default.svc.cluster.local
MONGO_DST_PORT=27017
MONGO_DST_USER=root
MONGO_DST_PASS=
MONGO_DST_DB=

AUTH_DB=admin

DUMP_HOME="./data/dump"
NS_INCLUDE="$MONGO_SRC_DB.*"

echo "> Cleaning dump.."
[ -d $DUMP_HOME ] && rm -rf $DUMP_HOME

echo "> Exporting dump.."
mongodump --host $MONGO_SRC_HOST:$MONGO_SRC_PORT -u $MONGO_SRC_USER -p $MONGO_SRC_PASS --authenticationDatabase $AUTH_DB -d $MONGO_SRC_DB -o $DUMP_HOME

echo "> Droping database the old db at the destination db server"
mongo $MONGO_DST_HOST:$MONGO_DST_PORT/$MONGO_DST_DB -u $MONGO_DST_USER -p $MONGO_DST_PASS --authenticationDatabase $AUTH_DB --quiet --eval "db.dropDatabase();"

echo "> Importing dump.."
mongorestore --host $MONGO_DST_HOST:$MONGO_DST_PORT -u $MONGO_DST_USER -p $MONGO_DST_PASS --authenticationDatabase $AUTH_DB --nsInclude $NS_INCLUDE $DUMP_HOME

#echo "> Changing the database name.."
#mongo $MONGO_DST_HOST:$MONGO_DST_PORT/$MONGO_DST_DB -u $MONGO_DST_USER -p $MONGO_DST_PASS --authenticationDatabase $AUTH_DB --quiet --eval "db.copyDatabase('$MONGO_SRC_DB', '$MONGO_DST_DB');"

#echo "> Droping the previous db at the destination db server.."
#mongo $MONGO_DST_HOST:$MONGO_DST_PORT/$MONGO_SRC_DB -u $MONGO_DST_USER -p $MONGO_DST_PASS --authenticationDatabase $AUTH_DB --quiet --eval "db.dropDatabase();"

# Clean up
[ -d $DUMP_HOME ] && rm -rf $DUMP_HOME
