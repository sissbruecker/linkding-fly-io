FROM sissbruecker/linkding:latest

COPY bootstrap-with-user-init.sh bootstrap-with-user-init.sh
RUN ["chmod", "+x", "bootstrap-with-user-init.sh"]

CMD ["./bootstrap-with-user-init.sh"]
