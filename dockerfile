FROM ubuntu
RUN apt-get update
RUN apt-get install nginx -y

#copy a file from the host directory to the container
COPY src/index.html /var/www/html

#expose my container to a port number
EXPOSE 82

#restart my nginx service
CMD ["nginx", "-g", "daemon off;"]
