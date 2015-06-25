# beheader
Scripts to analyze data files and get information about them:

* size
* media type
* availability

It's called the beheader because the data admins get beheaded when the script reports the number of unavailable files (errors 404, 500)

Sample Turtle:

```turtle
@prefix : <http://colin.maudry.com/ontologies/dgfr#>.
@prefix dcat: <http://www.w3.org/ns/dcat#> .

<https://www.data.maudry.com/fr/resources/ff91442b-4916-4567-ab87-e5a6fe6254b6>
        dgfr:responseStatusCode "HTTP/1.1 200 OK" ;
        dcat:byteSize 29 ;
        dcat:mediaType "text/html" .
```

## Requirements

This bash script is designed to work on Unix systems.

You need the following utilities

* curl

It's preconfigured to upload to http://www.data.maudry.com, but you need the credentials to write there. So to upload somewhere else you need to modify the target URL in beheader.sh, and provide your own credential as $1 and $2.

### v0.9

* Lists all dcat:Distribution referenced on data.gouv.fr, by ascending creation date
* For each file:
	1. checks availability and store HTTP response (200 OK, 400 Not found or 500 Server error)
	2. checks and store Content-Type returned by the server
	3. checks and store Content-length returned by the server





