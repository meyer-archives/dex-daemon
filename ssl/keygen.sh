#!/usr/bin/env bash
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr
openssl x509 -req -days 25815 -in server.csr -signkey server.key -out server.crt

# Failed attempt:
# openssl genrsa -out server.key 2048
# openssl req -new -key server.key -out server.csr
# openssl ca -startdate 000000000000Z -enddate 690000000000Z -out server.crt -infiles server.csr
# openssl req -new -x509 -key server.key -out server.crt