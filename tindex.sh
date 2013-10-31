#!/bin/bash

JRUBY="/htsolr/catalog/bin/jruby-1.7.6/bin/jruby"


filename=$1
filebase=`basename "$filename"`

if [ ! -z $2 ]
then
  LOGFILE_DIRECTIVE="-s log.file=$2"
else
  LOGFILE_DIRECTIVE=""
fi

host=`hostname -s`

if [ $host = "alamo" ]
then
  TDIR="/htsolr/catalog-dev/bin/ht_traject"
else
  TDIR="/htsolr/catalog/bin/ht_traject"
fi


$JRUBY --server -S traject \
  -c $TDIR/readers/ndj.rb\
  -c $TDIR/writers/localhost.rb\
  -c $TDIR/indexers/ht.rb \
  $LOGFILE_DIRECTIVE \
  $filename

