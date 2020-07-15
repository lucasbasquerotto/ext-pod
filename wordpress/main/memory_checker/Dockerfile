ARG IMAGE
ARG VERSION

FROM $IMAGE:$VERSION

COPY /main/memory_checker/ps_mem.py /bin/

CMD [ "python3", "/bin/ps_mem.py" ]