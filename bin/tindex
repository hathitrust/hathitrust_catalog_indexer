#!/bin/bash

JRUBY="/htsolr/catalog/bin/jruby-1.7.6/bin/jruby"

host=`hostname -s`

if [ $host = "alamo" ]
then
  TDIR="/htsolr/catalog-dev/bin/ht_traject"
else
  TDIR="/htsolr/catalog/bin/ht_traject"
fi

filename=$1
filebase=`basename "$filename"`

$JRUBY --server --fast -S traject \
  -c $TDIR/readers/ndj.rb\
  -c $TDIR/writers/localhost.rb\
  -c $TDIR/indexers/ht.rb \
  -s log.file=STDOUT\
  $filename

