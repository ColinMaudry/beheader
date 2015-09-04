# beheader 0.14.6

[DCAT](http://www.w3.org/TR/vocab-dcat) is a vocabulary used to describe published data. It's consequently metadata for this published data. A typical way to manage this DCAT metadata is as [RDF](https://en.wikipedia.org/wiki/Resource_Description_Framework), in a triple store, and to expose this data via a SPARQL endpoint to query it.

Beheader is a script that retrieves all [dcat:Distribution](http://www.w3.org/TR/vocab-dcat/#Class:_Distribution) (file metadata) from a SPARQL endpoint and uses the file URL (`dcat:downloadUrl`) to retrieve some information about it:

* size
* media type
* availability
* server response time in seconds

The information is stored as RDF and uploaded to the same triple store as for the DCAT metadata, but in a different graph. The result of this script is enriched metadata about the published files.

It's called the beheader because the data admins get beheaded when the script reports the number of unavailable files (errors 404, 500).

Sample Turtle RDF output:

```turtle
@prefix : <http://colin.maudry.com/ontologies/dgfr#>.
@prefix dcat: <http://www.w3.org/ns/dcat#> .
@prefix xs: <http://www.w3.org/2001/XMLSchema#> .

<https://www.data.maudry.com/fr/resources/a6eda5aa-2741-4cfd-a2b3-e8ae6277937b> :responseStatusCode "HTTP/1.1 200 OK" ;
:responseTime 0.227 ;
:availabilityCheckedOn "2015-08-04T18:32:38+0200"^^xs:dateTime .
<https://www.data.maudry.com/fr/resources/a6eda5aa-2741-4cfd-a2b3-e8ae6277937b> :available true .
<https://www.data.maudry.com/fr/resources/a6eda5aa-2741-4cfd-a2b3-e8ae6277937b> dcat:byteSize 29 .
<https://www.data.maudry.com/fr/resources/a6eda5aa-2741-4cfd-a2b3-e8ae6277937b> dcat:mediaType "text/html" .
 
<https://www.data.maudry.com/fr/resources/164932c5-19ec-444b-9695-5e914a4dce22> :responseStatusCode "HTTP/1.1 404 NOT FOUND" ;
:responseTime 0.282 ;
:availabilityCheckedOn "2015-08-04T18-32-39+0200"^^xs:dateTime .
<https://www.data.maudry.com/fr/resources/164932c5-19ec-444b-9695-5e914a4dce22> :available false .
```

## Requirements

This bash script is designed to work on Unix systems.

You need the following utilities installed

* curl
* iconv

## Configuration

1. Make a copy of `config_template.sh`
2. Rename it `config.sh`
3. Configure as you please

`config.sh` is the default configuration file that is used if no parameter is passed to the script. You can create other configuration files. The name of congiguration files shouldn't contain "http".

It's preconfigured to upload to http://www.data.maudry.com, but you need the credentials to write there. So to upload somewhere else you need to modify `ENDPOINT_URL` to match the base URL of your RDF repository.

Tell me if you struggle with the configuration.

## Run

To run beheader with the default config.sh you created in **Configuration**:

```bash
./beheader.sh
```

If you get an error, you may need to make the file executable first, this way:

```
chmod u+x beheader.sh
```

In order to save the logs, you can run instead:

```bash
./beheader.sh > beheader.log &
```

To run beheader with a alternate configuration file (you can run beheader on different configurations in parallel)

```bash
./beheader.sh configurationfile
```

To run beheader on a single URL with the default configuration (`config.sh`)

```bash
./beheader.sh http://example.com
```

##### 0.14.6

* Fixed the datetime format for dgfr:availabilityCheckedOn (for real)

##### 0.14.5

* Fixed the datetime format for dgfr:availabilityCheckedOn 

##### 0.14.4

* Disabled suppression of temp directory

##### 0.14.3

* Temporary file names (also) contain the config ID (duh)

##### 0.14.2

* Data file name now contains the config ID (enables parallel processing)

##### 0.14.1

* If the content type is "application/zip" and the URL of the resource contains `=shp` or `.shp` (or `SHP`), the content type is set to "application/shp+zip". I made it up to add it this standard and easy to use format in [the list of machine readable formats](https://github.com/ColinMaudry/datagouvfr-rdf/issues/37).

#### 0.14.0

*  Forcing LF (and not DOS/CRLF) line breaks on SPARQL CSV query results
* Configuration can now be selected as a parameter (#5)
* SPARQL query now also includes dcat:Distribution in the main graph (#5)

##### 0.13.2

* Fixed the datetime format for dgfr:availabilityCheckedOn (the time part used dashed instead of colons)

##### 0.13.1

* Fixed response time in case HEAD isn't supported and beheader falls back to using GET

#### 0.13.0

* Added server response time, in seconds, for each file (`dgfr:responseTime`)
* Added the date and time of the last time the availability of the file was checked (`dgfr:availabilityCheckedOn`)
* The Turtle data file name is now dynamic in order not to erase previous data

#### 0.12.0

* 2xx and 3xx codes assume the file is available
* Switched back to HEAD to enable certain servers to have adequate response. If unsupported, automatic switch to GET
* Configurable timeout (waiting time after which you consider the resource is not available)

#### 0.11.0

* Switched to `curl -X GET -I` since it doesn't download the file and has better support from servers
* Added inference of availability. If status is not `200 OK` then `dgfr:available false`

##### 0.10.1

* Improved cURL command for faster and more robust retrieval of HTTP headers (removed Inspire URL hack)
* Possibility to specify the name of the target graph

#### 0.10

* `iconv` -c Serializes the resulting TTL files to UTF-8 to remove encoding errors (loss of data :( )
* & signs in URLs are better supported
* Either upload data by small batches of 5 distributions, or a single shot at the end
* Inspire URL have a more flexible timeout...

#### 0.9

* Lists all dcat:Distribution referenced on data.gouv.fr, by ascending creation date
* For each file:
	1. checks availability and store HTTP response (200 OK, 400 Not found or 500 Server error)
	2. checks and store Content-Type returned by the server
	3. checks and store Content-length returned by the server





