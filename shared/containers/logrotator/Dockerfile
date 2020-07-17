ARG IMAGE
ARG VERSION

FROM $IMAGE:$VERSION

COPY /shared/containers/logrotator/logrotate.py /bin/

CMD [ "python3", "/bin/logrotate.py" ]