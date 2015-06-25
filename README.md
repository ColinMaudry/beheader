# beheader
Scripts to analyze data files, with particular care for  CSV files. The result is stored in RDF.

It's called the beheader for two reasons:

* it beheads CSV to have them dissected
* the data admins get beheaded when the script reports the number of unavailable files (errors 404, 500)

Sample Turtle:

```turtle
@prefix : <http://colin.maudry.com/ontologies/dgfr#>.
@prefix dcat: <http://www.w3.org/ns/dcat#> .

<https://www.data.maudry.com/fr/resources/e6660311-8d43-4165-8479-79e782a48a6c>  :responseStatusCode  "HTTP/1.1 404 NOT FOUND" .
<https://www.data.maudry.com/fr/resources/37e1533d-dcea-4a92-8bde-1c74e932450a>  :responseStatusCode  "HTTP/1.1 404 NOT FOUND" .
<https://www.data.maudry.com/fr/resources/8e088ffb-9354-4ff2-b7ac-99740a688a62>  :responseStatusCode  "HTTP/1.1 404 NOT FOUND" .
<https://www.data.maudry.com/fr/resources/4e12515d-3e79-49d9-bdfb-c4bc29c7a29b>  :responseStatusCode  "HTTP/1.1 404 NOT FOUND" .

<https://www.data.maudry.com/fr/resources/c2438eba-12be-4d0a-acca-2d67bc141a40>  :responseStatusCode  "HTTP/1.1 200 OK" .
<https://www.data.maudry.com/fr/resources/c2438eba-12be-4d0a-acca-2d67bc141a40> dcat:mediaType "application/x-gzip" .

<https://www.data.maudry.com/fr/resources/6dc0aec8-5cf6-41f3-bfd7-d7760e1a02d2>  :responseStatusCode  "HTTP/1.1 200 OK" .
<https://www.data.maudry.com/fr/resources/6dc0aec8-5cf6-41f3-bfd7-d7760e1a02d2> dcat:mediaType "text/csv; charset=utf8" .
<https://www.data.maudry.com/fr/resources/6dc0aec8-5cf6-41f3-bfd7-d7760e1a02d2> :numberOfColumns  15 .
<https://www.data.maudry.com/fr/resources/6dc0aec8-5cf6-41f3-bfd7-d7760e1a02d2> :numberOfRows  129 .
<https://www.data.maudry.com/fr/resources/6dc0aec8-5cf6-41f3-bfd7-d7760e1a02d2> :header "Gare","Commune","Type de gare","Présence abris","Nombre de stationnement vélo","Type d'appui","Nombre d'abris","Condition d'utilisation","Tarif d'utilisation","Adresse postale","Code postal","Code INSEE","_l","Nom du stationnement vélo","Code UIC" .

<https://www.data.maudry.com/fr/resources/5eaeebeb-5305-4c1e-b39c-85c42d5e5b38>  :responseStatusCode  "HTTP/1.1 200 OK" .
<https://www.data.maudry.com/fr/resources/5eaeebeb-5305-4c1e-b39c-85c42d5e5b38> dcat:mediaType "application/csv; charset=utf-8" .
<https://www.data.maudry.com/fr/resources/5eaeebeb-5305-4c1e-b39c-85c42d5e5b38> :numberOfColumns  13 .
<https://www.data.maudry.com/fr/resources/5eaeebeb-5305-4c1e-b39c-85c42d5e5b38> :numberOfRows  2327 .
<https://www.data.maudry.com/fr/resources/5eaeebeb-5305-4c1e-b39c-85c42d5e5b38> :header "type","nom","numero","voie","code_postal","remarques","handicap_moteur","handicap_visuel","handicap_auditif","lien","coordx_wgs","coordy_wgs","column_14" .

<https://www.data.maudry.com/fr/resources/6bf56d9c-1a98-487b-a9d5-4d1c1131a450>  :responseStatusCode  "HTTP/1.1 200 OK" .
<https://www.data.maudry.com/fr/resources/6bf56d9c-1a98-487b-a9d5-4d1c1131a450> dcat:mediaType "application/csv; charset=utf-8" .
<https://www.data.maudry.com/fr/resources/6bf56d9c-1a98-487b-a9d5-4d1c1131a450> :numberOfColumns  4 .
<https://www.data.maudry.com/fr/resources/6bf56d9c-1a98-487b-a9d5-4d1c1131a450> :numberOfRows  2327 .
<https://www.data.maudry.com/fr/resources/6bf56d9c-1a98-487b-a9d5-4d1c1131a450> :header "type","nom","numero","voie","code_postal","remarques","handicap_moteur","handicap_visuel","handicap_auditif","lien","coordx_wgs","coordy_wgs","column_14" .

<https://www.data.maudry.com/fr/resources/6fbb4ae4-247c-4c52-b0d6-aa92f39a11d3>  :responseStatusCode  "HTTP/1.1 404 NOT FOUND" .
```

## Requirements

This bash script is designed to work on Unix systems.

You need the following utilities

* curl
* csvkit
* csvtool

It's preconfigured to upload to http://www.data.maudry.com, but you need the credentials to write there. So to upload somewhere else you need to modify the target URL in beheader.sh, and provide your own credential as $1 and $2.

## To-do

* store sample data per column
* make an app to show the data (especially the unavailable files, dammit)

### v0.9

* Lists all dcat:Distribution referenced on data.gouv.fr, by ascending creation date
* For each file:
	1. checks availability and store HTTP response (200 OK, 400 Not found or 500 Server error)
	2. checks and store Content-Type returned by the server
	2. checks whether it's a CSV (or TSV or semi-colonSV)
	3. counts the columns and store the result
	4. counts the rows and stores the result
	5. extracts header row and link each header label to the CSV URI






