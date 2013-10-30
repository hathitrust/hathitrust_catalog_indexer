#!/bin/bash

JRUBY="/htsolr/catalog/bin/jruby-1.7.6/bin/jruby"
TDIR="/htsolr/catalog/bin/ht_traject"

filename=$1
filebase=`basename "$filename"`

$JRUBY --server --fast -S traject \
  -c $TDIR/readers/ndj.rb\
  -c $TDIR/writers/localhost.rb\
  -c $TDIR/indexers/ht.rb \
  -s log.file="$TDIR/logs/$filebase.log" \
  -s log.level=debug \
  $filename

