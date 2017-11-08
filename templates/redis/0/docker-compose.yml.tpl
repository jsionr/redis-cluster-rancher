version: '2'

services:
  master:
    image: redis:${REDIS_VERSION}-alpine
    environment:
      REDIS_PASSWORD: '${REDIS_PASSWORD}'
    stdin_open: true
    volumes:
    - redis-master:/data
    tty: true
    command:
    - redis-server
    - --appendonly
    - 'yes'
    - --masterauth
    - '${REDIS_PASSWORD}'
    - --requirepass
    - '${REDIS_PASSWORD}'
    labels:
      io.rancher.container.pull_image: always
      io.rancher.scheduler.affinity:host_label: '${REDIS_MASTER_HOST_LABEL}'
      io.rancher.scheduler.affinity:container_label_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}

  slave:
    image: redis:${REDIS_VERSION}-alpine
    environment:
      REDIS_PASSWORD: '${REDIS_PASSWORD}'
    stdin_open: true
    volumes:
    - redis-slave:/data
    tty: true
    command:
    - redis-server
    - --appendonly
    - 'yes'
    - --slaveof
    - master
    - '6379'
    - --masterauth
    - '${REDIS_PASSWORD}'
    - --requirepass
    - '${REDIS_PASSWORD}'
    labels:
      io.rancher.container.pull_image: always
      io.rancher.scheduler.affinity:host_label: '${REDIS_SLAVE_HOST_LABEL}'
      io.rancher.scheduler.affinity:container_label_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}

  sentinel:
    image: lgatica/redis-sentinel:${REDIS_VERSION}
    environment:
      REDIS_PASSWORD: '${REDIS_PASSWORD}'
    stdin_open: true
    tty: true
    links:
    - master:master
    ports:
    - '${REDIS_SENTINEL_PORT}':26379/tcp
    labels:
      io.rancher.container.pull_image: always
      io.rancher.scheduler.affinity:host_label: '${REDIS_SENTINEL_HOST_LABEL}'
      io.rancher.scheduler.affinity:container_label_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}

  haproxy:
    image: rancher/lb-service-haproxy:v0.7.9
    ports:
    - '${REDIS_HAPROXY_PORT}':6379/tcp
    labels:
      io.rancher.scheduler.affinity:host_label: '${REDIS_SENTINEL_HOST_LABEL}'
      io.rancher.container.agent.role: environmentAdmin
      io.rancher.container.create_agent: 'true'

volumes:
  redis-master:
    external: true
    per_container: true
    driver: '${VOLUME_DRIVER}'
    driver_opts:
      size: '${VOLUME_DRIVER_SIZE}'
      volumeType: '${VOLUME_DRIVER_TYPE}'
      ec2_az: '${VOLUME_DRIVER_AZ}'
      iops: '${VOLUME_DRIVER_IOPS}'

  redis-slave:
    external: true
    per_container: true
    driver: '${VOLUME_DRIVER}'
    driver_opts:
      size: '${VOLUME_DRIVER_SIZE}'
      volumeType: '${VOLUME_DRIVER_TYPE}'
      ec2_az: '${VOLUME_DRIVER_AZ}'
      iops: '${VOLUME_DRIVER_IOPS}'