FROM nulix/builder:os

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
