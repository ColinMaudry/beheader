#!/bin/bash

#Configuration
if [[ -n $1 ]] ; then
source $1
else
source ./config.sh
fi

shortdate=`date +%F`
datafile="temp/${shortdate}_data.ttl"

#Clear temp files
rm -rf temp

#Create temp dir
mkdir temp
cp data_template.ttl temp/all_data.ttl
cp data_template.ttl $datafile

if [[ "$USER_NAME" != "" ]]
then
echo "There is a user name: $USER_NAME"
full_endpoint_url=${ENDPOINT_WRITE_URL/"://"/"://$USER_NAME:$USER_PASSWORD@"}
else
full_endpoint_url=$ENDPOINT_WRITE_URL
fi #check whether credentials are provided

if [[ $SMALL_BATCHES == "true" ]] ; then
echo "Clearing target graphs..."
curl -s -X DELETE $full_endpoint_url --data-urlencode "graph=$TARGET_GRAPH"
fi

date=`date`
echo "Started at: $date"

#The list of files, sorted per dcterms created
echo "Getting list of files..."
curl -s $ENDPOINT_READ_URL -H "Accept: text/csv"  --data-urlencode query@sparql/list.rq --output temp/list.csv

#I sometimes get DOS line breaks (CRLF) from the endpoint. So I force LF (Unix) line breaks
sed -i 's/\r//g' temp/list.csv

#Removing header row
sed -i '1d' temp/list.csv

filenum=`csvtool height temp/list.csv`
echo "$filenum files to process"

number=0
while read -r line
do
	IFS=","
        read -r uri url issued  <<< "$line"

((number++))

echo " "
echo "$number) $url"
#Get headers using URL to check the HTTP response code (200, 404, 500, etc.) and content type
#-skIL = silent, ignore SSL certif, only print headers, follow redirects
#...and I print the result in a file
datetime=`date +%FT%H:%M:%S%z`
curl -skIL -X HEAD -w @"curl-format" -m $TIMEOUT "$url" 2>&1 | less > temp/http_headers

if  [[ -s temp/http_headers  ]] ; then

#All upper case, remove final carriage return
http_response_code=`grep "HTTP/" temp/http_headers | tail -n 1 |tr [a-z] [A-Z] |tr -d '\r'`
full_http_response_time=`grep "Total-time" temp/http_headers | tr -d '\r' | sed s/,/./g`
http_response_time=`cut -d " " -f 2  <<< "$full_http_response_time"`
if [[ $http_response_code =~ 40[0,5] ]] ; then #if HEAD isn't supported (400 or 405)
echo "...fall back to GET!"
datetime=`date +%FT%H:%M:%S%z`
curl -skIL -X GET -w @"curl-format" -m $TIMEOUT "$url" 2>&1 | less > temp/http_headers
http_response_code=`grep "HTTP/" temp/http_headers | tail -n 1 |tr [a-z] [A-Z] |tr -d '\r'`
full_http_response_time=`grep "Total-time" temp/http_headers | tr -d '\r' | sed s/,/./g`
http_response_time=`cut -d " " -f 2  <<< "$full_http_response_time"`
fi

echo " " >> $datafile
echo "# $number" >> $datafile
echo "<$uri> $HTTP_RESPONSE_PROP \"$http_response_code\" ;" >> $datafile
echo "$HTTP_RESPONSE_TIME_PROP $http_response_time ;" >> $datafile
echo "$DATETIMECHECKED_PROP \"$datetime\"^^xs:dateTime ." >> $datafile
echo "Response code: 		$http_response_code"

if [[ $http_response_code =~ [2,3][0-9][0-9] ]] ; then #2xx and 3xx HTTP response codes are considered OK

echo "<$uri> $AVAILABILITY_PROP true ." >> $datafile

#Fetch Content-Type returned by the server
full_content_type=`grep "Content-Type: " temp/http_headers | tail -n 1 |tr -d "\r" `
content_type=`echo "${full_content_type:14}"|tr -d '\r'`
content_type=`echo ${content_type%%;*}`
shp_regex='[=\.]shp|SHP'
if [[ `echo "${url: -4}"` == ".csv"  ]] ; then
content_type="text/csv"
elif [[ `echo "${url: -4}"` == ".odt"  ]] ; then
content_type="application/vnd.oasis.opendocument.text"
elif [[ `echo "${url: -4}"` == ".ods"  ]] ; then
content_type="application/vnd.oasis.opendocument.spreadsheet"
elif [[ "$content_type" == "application/zip" && "$url" =~ [=\.]shp|SHP ]] ; then
content_type="application/shp+zip"
fi

#Fetch Content-Length
full_content_length=`grep "Content-Length: " temp/http_headers | tail -n 1 |tr -d "\r" `
content_length=`echo "${full_content_length:16}"|tr -d '\r'`

echo "Content size: 		$content_length"
echo "Content type: 		$content_type"

if [[ $content_length -gt 1 ]] ; then
echo "<$uri> $CONTENT_LENGTH_PROP $content_length ." >> $datafile
fi
echo "<$uri> $CONTENT_TYPE_PROP \"$content_type\" ." >> $datafile

else #resource is not available
echo "<$uri> $AVAILABILITY_PROP false ." >> $datafile

fi #check if available

else #The server timed out
http_response_code="Timed out after $TIMEOUT seconds"
echo "<$uri> $AVAILABILITY_PROP false ;" >> $datafile
echo "$HTTP_RESPONSE_PROP \"$http_response_code\" ." >> $datafile
echo "Response code:            $http_response_code"

fi #check if timed out

if [[ $SMALL_BATCHES == "true" ]] ; then
	if [[ `echo ${number: -1}` -eq 0 ]] || [[ `echo ${number: -1}` -eq 5 ]] ; then
	echo "Uploading batch $(($number - 4))-$number..."
	#iconv -c ignores encoding errors
	iconv -c -f US-ASCII -t UTF-8 $datafile > temp/data_utf8.ttl
	mv -f temp/data_utf8.ttl $datafile
	curl -s -X POST $full_endpoint_url\?graph=urn%3Afiles%3Adata --data-binary @"$datafile" -H "Content-type: text/turtle"
	tail -n +6 $datafile >> temp/all_data.ttl
	cp -f data_template.ttl $datafile
	fi #Is $number a multiple of 5?
fi

done < temp/list.csv #loop on CSV list entries

if [[ $SMALL_BATCHES != "true" ]] ; then 
        echo "Uploading all data in a single shot..."
        #iconv -c ignores encoding errors
        iconv -c -f US-ASCII -t UTF-8 $datafile > temp/data_utf8.ttl
        mv -f temp/data_utf8.ttl $datafile
        curl -s -X PUT "$full_endpoint_url?graph=$TARGET_GRAPH" --data-binary @"$datafile" -H "Content-type: text/turtle"
fi

date=`date`
echo "Finished at: $date"
