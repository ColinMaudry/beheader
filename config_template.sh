#!/bin/bash



#Configuration
ENDPOINT_URL="http://www.data.maudry.com:3030"
ENDPOINT_READ_URL=$ENDPOINT_URL"/datagouvfr/query"
ENDPOINT_WRITE_URL=$ENDPOINT_URL"/datagouvfr/data"
USER_NAME=
USER_PASSWORD=


HTTP_RESPONSE_PROP=":responseStatusCode"
COLNUM_PROP=":numberOfColumns"
ROWNUM_PROP=":numberOfRows"
CONTENT_TYPE_PROP="dcat:mediaType"
CONTENT_LENGTH_PROP="dcat:byteSize"

UPLOAD_GRAPH="urn:csv:data"

PARSE_CSV="true"
NUM_SAMPLE_VALUES=3



