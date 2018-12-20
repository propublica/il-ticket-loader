#! /bin/bash
docker run -p 8080:8080 \
       hasura/graphql-engine:latest \
       graphql-engine \
       --database-url ${ILTICKETS_DB_URL} \
       serve --enable-console
