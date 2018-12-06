#! /bin/bash
docker run -p 8080:8080 \
       hasura/graphql-engine:v1.0.0-alpha31 \
       graphql-engine \
       --database-url ${ILTICKETS_DB_URL} \
       serve --enable-console
