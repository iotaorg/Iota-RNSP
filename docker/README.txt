docker build -t iota/togeojson .

docker run --rm -v `path-to-kml`:/tmp/arqs:ro iota/togeojson togeojson /tmp/arqs/KML.filename


