ARG IMAGE
ARG VERSION

FROM $IMAGE:$VERSION

COPY /main/logrotator/logrotate.py /bin/

CMD [ "python3", "/bin/logrotate.py" ]