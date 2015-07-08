#!/bin/bash

#Configuration
ENDPOINT_URL="http://www.data.maudry.com:3030"
ENDPOINT_READ_URL=$ENDPOINT_URL"/datagouvfr/query"
ENDPOINT_WRITE_URL=$ENDPOINT_URL"/datagouvfr/data"
TARGET_GRAPH="urn%3Afiles%3Adata" #must be URL encoded, for instance at http://meyerweb.com/eric/tools/dencoder/

USER_NAME=
USER_PASSWORD=

HTTP_RESPONSE_PROP=":responseStatusCode"
COLNUM_PROP=":numberOfColumns"
ROWNUM_PROP=":numberOfRows"
CONTENT_TYPE_PROP="dcat:mediaType"
CONTENT_LENGTH_PROP="dcat:byteSize"
AVAILABILITY_PROP=":available"

#If you get many errors upon data upload to triple store  (encoding, malformed Turtle), set this to "true". It will make an upload every 5 distribution. Slower, but less data loss.
SMALL_BATCHES="false"




