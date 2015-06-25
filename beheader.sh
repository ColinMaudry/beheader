#!/bin/bash

#Configuration
source ./config.sh

#Clear temp files
rm -rf temp

#Create temp dir
mkdir temp
cp data_template.ttl temp/all_data.ttl
cp data_template.ttl temp/all_csvdata.ttl
cp data_template.ttl temp/data.ttl
cp data_template.ttl temp/csvdata.ttl

if [[ "$USER_NAME" != "" ]]
then
echo "There is a user name: $USER_NAME"
full_endpoint_url=${ENDPOINT_WRITE_URL/"://"/"://$USER_NAME:$USER_PASSWORD@"}
else
full_endpoint_url=$ENDPOINT_WRITE_URL
fi #check whether credentials are provided

echo "Clearing target graphs..."
curl -s -X DELETE $full_endpoint_url\?graph=urn%3Afiles%3Adata
curl -s -X DELETE $full_endpoint_url\?graph=urn%3Acsv%3Adata

date=`date`
echo "Started at: $date"

#The list of CSVs, sorted per dcterms created
echo "Getting list of files..."
curl -s $ENDPOINT_READ_URL -H "Accept: text/csv"  --data-urlencode query@sparql/list.rq --output temp/list.csv

sed -i '1d' temp/list.csv

if [[ -n $1 ]] ; then
echo "urn:test:csv,$1,somedate" > temp/list.csv
fi
filenum=`csvtool height temp/list.csv`
echo "$filenum files to process"

number=0
while read -r line
do
	IFS=","
        read -r csv url issued  <<< "$line"

((number++))
echo " "
echo "$number) $url"

#Get headers using URL to check the HTTP response code (200, 404, 500, etc.) and content type
#-skL = silent, ignore SSL certif, follow redirects
curl -X HEAD -skL -m 1 ${url/&/\\&} -D temp/http_headers

#All upper case, remove final carriage return
http_response_code=`grep "HTTP/" temp/http_headers | tail -n 1 |tr [a-z] [A-Z] |tr -d '\r'`
echo " " >> temp/data.ttl
echo "#File: $url" >> temp/data.ttl
response_triple="<$csv>  $HTTP_RESPONSE_PROP  \"$http_response_code\" ."
echo "Response code: 		$http_response_code"
echo $response_triple >> temp/data.ttl

if [[ $http_response_code ==  *"200"* ]]
then

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
echo "Size: $content_length"

echo "Content type: 		$content_type"
if [[ $content_length -gt 1 ]] ; then
echo "<$csv> $CONTENT_LENGTH_PROP $content_length ." >> temp/data.ttl
fi
echo "<$csv> $CONTENT_TYPE_PROP \"$content_type\" ." >> temp/data.ttl

fi #check if available

if [[ `echo ${number: -1}` -eq 0 ]] || [[ `echo ${number: -1}` -eq 5 ]] ; then
echo "Uploading batch $(($number - 4))-$number..."
if [[ -s temp/csvdata.ttl ]] ; then
curl -s -X POST $full_endpoint_url\?graph=urn%3Acsv%3Adata --data-binary @"temp/csvdata.ttl" -H "Content-type: text/turtle"
#Remove the first lines with prefixes
tail -n +6 temp/csvdata.ttl >> temp/all_csvdata.ttl
cp -f data_template.ttl temp/csvdata.ttl
fi #Does temp/csvdata.ttl exist?

curl -s -X POST $full_endpoint_url\?graph=urn%3Afiles%3Adata --data-binary @"temp/data.ttl" -H "Content-type: text/turtle"
tail -n +6 temp/data.ttl >> temp/all_data.ttl
cp -f data_template.ttl temp/data.ttl
fi #Is $number a multiple of 5?

done < temp/list.csv #loop on CSV list entries

date=`date`
echo "Finished at: $date"
