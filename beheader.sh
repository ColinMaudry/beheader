#!/bin/bash

#Configuration
source ./config.sh

#Clear temp files
rm -rf temp

#Create temp dir
mkdir temp
cp data_template.ttl temp/all_data.ttl
cp data_template.ttl temp/data.ttl

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

sed -i '1d' temp/list.csv

if [[ -n $1 ]] ; then
echo "urn:test:file,$1,somedate" > temp/list.csv
fi
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
curl -skIL -X GET "$url" 2>&1 | less > temp/http_headers

#All upper case, remove final carriage return
http_response_code=`grep "HTTP/" temp/http_headers | tail -n 1 |tr [a-z] [A-Z] |tr -d '\r'`

echo " " >> temp/data.ttl
echo "#File: $url" >> temp/data.ttl
response_triple="<$uri> $HTTP_RESPONSE_PROP \"$http_response_code\" ."
echo "Response code: 		$http_response_code"
echo $response_triple >> temp/data.ttl

if [[ $http_response_code ==  *"200"* ]]
then

echo "<$uri> $AVAILABILITY_PROP true ." >> temp/data.ttl

#Fetch Content-Type returned by the server
full_content_type=`grep "Content-Type: " temp/http_headers | tail -n 1 |tr -d "\r" `
content_type=`echo "${full_content_type:14}"|tr -d '\r'`
content_type=`echo ${content_type%%;*}`
if [[ `echo "${url: -4}"` == ".csv"  ]] ; then
content_type="text/csv"
elif [[ `echo "${url: -4}"` == ".odt"  ]] ; then
content_type="application/vnd.oasis.opendocument.text"
elif [[ `echo "${url: -4}"` == ".ods"  ]] ; then
content_type="application/vnd.oasis.opendocument.spreadsheet"
fi

#Fetch Content-Length
full_content_length=`grep "Content-Length: " temp/http_headers | tail -n 1 |tr -d "\r" `
content_length=`echo "${full_content_length:16}"|tr -d '\r'`
echo "Content size: 		$content_length"

echo "Content type: 		$content_type"
if [[ $content_length -gt 1 ]] ; then
echo "<$uri> $CONTENT_LENGTH_PROP $content_length ." >> temp/data.ttl
fi
echo "<$uri> $CONTENT_TYPE_PROP \"$content_type\" ." >> temp/data.ttl

else #resource is not available
echo "<$uri> $AVAILABILITY_PROP false ." >> temp/data.ttl

fi #check if available

if [[ $SMALL_BATCHES == "true" ]] ; then
	if [[ `echo ${number: -1}` -eq 0 ]] || [[ `echo ${number: -1}` -eq 5 ]] ; then
	echo "Uploading batch $(($number - 4))-$number..."
	#iconv -c ignores encoding errors
	iconv -c -f US-ASCII -t UTF-8 temp/data.ttl > temp/data_utf8.ttl
	mv -f temp/data_utf8.ttl temp/data.ttl
	curl -s -X POST $full_endpoint_url\?graph=urn%3Afiles%3Adata --data-binary @"temp/data.ttl" -H "Content-type: text/turtle"
	tail -n +6 temp/data.ttl >> temp/all_data.ttl
	cp -f data_template.ttl temp/data.ttl
	fi #Is $number a multiple of 5?
fi

done < temp/list.csv #loop on CSV list entries

if [[ $SMALL_BATCHES != "true" ]] ; then 
        echo "Uploading all data in a single shot..."
        #iconv -c ignores encoding errors
        iconv -c -f US-ASCII -t UTF-8 temp/data.ttl > temp/data_utf8.ttl
        mv -f temp/data_utf8.ttl temp/data.ttl
        curl -s -X PUT "$full_endpoint_url?graph=$TARGET_GRAPH" --data-binary @"temp/data.ttl" -H "Content-type: text/turtle"
fi

date=`date`
echo "Finished at: $date"
