ARG IMAGE
ARG VERSION

FROM $IMAGE:$VERSION

COPY /shared/containers/python3/logrotate.py /bin/

CMD [ "python3", "/bin/logrotate.py" ]