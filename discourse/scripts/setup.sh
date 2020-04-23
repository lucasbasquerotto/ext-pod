#!/usr/bin/env bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR

##
## Make sure only root can run our script
##
check_root() {
  echo "check_root started"

  if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Please sudo or log in as root first." 1>&2
    exit 1
  fi
  
  echo "check_root finished"
}

##
## Check whether a connection to HOSTNAME ($1) on PORT ($2) is possible
##
connect_to_port () {
  echo "connect_to_port started"
  
  HOST="$1"
  PORT="$2"
  VERIFY=`date +%s | sha256sum | base64 | head -c 20`
  echo -e "HTTP/1.1 200 OK\n\n $VERIFY" | nc -w 4 -l -p $PORT >/dev/null 2>&1 &
  if curl --proto =http -s $HOST:$PORT --connect-timeout 3 | grep $VERIFY >/dev/null 2>&1
  then
      return 0
  else
    curl --proto =http -s localhost:$PORT >/dev/null 2>&1
    return 1
  fi
  
  echo "connect_to_port finished"
}

check_IP_match () {
  echo "check_IP_match started"

  HOST="$1"
  echo
  echo Checking your domain name . . .

  if connect_to_port $HOST 443
  then
    echo
    echo "Connection to $HOST succeeded."
  else
    echo WARNING:: This server does not appear to be accessible at $HOST:443.
    echo

    if connect_to_port $HOST 80
    then
      echo A connection to port 80 succeeds, however.
      echo This suggests that your DNS settings are correct,
      echo but something is keeping traffic to port 443 from getting to your server.
      echo Check your networking configuration to see that connections to port 443 are allowed.
    else
      echo "A connection to http://$HOST (port 80) also fails."
      echo
      echo This suggests that $HOST resolves to the wrong IP address
      echo or that traffic is not being routed to your server.
    fi

    echo
    echo Google: \"open ports YOUR CLOUD SERVICE\" for information for resolving this problem.
    echo
    echo You should probably answer \"n\" at the next prompt and disable Let\'s Encrypt.
    echo
    echo This test might not work for all situations,
    echo so if you can access Discourse at http://$HOST, you might try anyway.
    sleep 3
  fi
  
  echo "check_IP_match finished"
}

##
## Do we have docker?
##
check_docker () {
  echo "check_docker started"

  docker_path=`which docker.io || which docker`

  if [ -z $docker_path ]; then
    echo "Error: Docker not installed." 1>&2
    exit 1
  fi
  
  echo "check_docker finished"
}

##
## What are we running on
##
check_OS() {
  echo `uname -s`
}

##
## OS X available memory
##
check_osx_memory() {
  echo `free -m | awk '/Mem:/ {print $2}'`
}

##
## Linux available memory
##
check_linux_memory() {
  echo `free -g --si | awk ' /Mem:/  {print $2} '`
}

##
## Do we have enough memory and disk space for Discourse?
##
check_disk_and_memory() {
  echo "check_disk_and_memory started"
	
  os_type=$(check_OS)
  avail_mem=0

  if [ "$os_type" == "Darwin" ]; then
    avail_mem=$(check_osx_memory)
  else
    avail_mem=$(check_linux_memory)
  fi

  if [ "$avail_mem" -lt 1 ]; then
    echo "WARNING: Discourse requires 1GB RAM to run. This system does not appear"
    echo "to have sufficient memory."
    echo
    echo "Your site may not work properly, or future upgrades of Discourse may not"
    echo "complete successfully."
    exit 1
  fi

  if [ "$avail_mem" -le 2 ]; then
    total_swap=`free -g --si | awk ' /Swap:/  {print $2} '`

    if [ "$total_swap" -lt 2 ]; then
      echo "WARNING: Discourse requires at least 2GB of swap when running with 2GB of RAM"
      echo "or less. This system does not appear to have sufficient swap space."
      echo
      echo "Without sufficient swap space, your site may not work properly, and future"
      echo "upgrades of Discourse may not complete successfully."
      echo
      echo "Ctrl+C to exit or wait 5 seconds to have a 2GB swapfile created."
      sleep 5

      ##
      ## derived from https://meta.discourse.org/t/13880
      ##
      install -o root -g root -m 0640 /dev/null /swapfile
      dd if=/dev/zero of=/swapfile bs=1k count=2048k
      mkswap /swapfile
      swapon /swapfile
      echo "/swapfile       swap    swap    auto      0       0" | tee -a /etc/fstab
      sysctl -w vm.swappiness=10
      echo 'vm.swappiness = 10' > /etc/sysctl.d/30-discourse-swap.conf

      total_swap=`free -g --si | awk ' /Swap:/ {print $2} '`

      if [ "$total_swap" -lt 2 ]; then
        echo "Failed to create swap: are you root? Are you running on real hardware, or a fully virtualized server?"
        exit 1
      fi
    fi
  fi

  free_disk="$(df /var | tail -n 1 | awk '{print $4}')"

  if [ "$free_disk" -lt 5000 ]; then
    echo "WARNING: Discourse requires at least 5GB free disk space. This system"
    echo "does not appear to have sufficient disk space."
    echo
    echo "Insufficient disk space may result in problems running your site, and"
    echo "may not even allow Discourse installation to complete successfully."
    echo
    echo "Please free up some space, or expand your disk, before continuing."
    echo
    echo "Run \`apt-get autoremove && apt-get autoclean\` to clean up unused"
    echo "packages and \`./launcher cleanup\` to remove stale Docker containers."
    exit 1
  fi
  
  echo "check_disk_and_memory finished"
}

##
## standard http / https ports must not be occupied
##
check_ports() {
  check_port "80"
  check_port "443"
  echo "Ports 80 and 443 are free for use"
}

##
## check a port to see if it is already in use
##
check_port() {
  echo "check_port started"

  local valid=$(netstat -tln | awk '{print $4}' | grep ":${1}\$")

  if [ -n "$valid" ]; then
    echo "Port ${1} appears to already be in use."
    echo
    echo "This will show you what command is using port ${1}"
    lsof -i tcp:${1} -s tcp:listen
    echo
    echo "If you are trying to run Discourse simultaneously with another web"
    echo "server like Apache or nginx, you will need to bind to a different port"
    echo
    echo "See https://meta.discourse.org/t/17247"
    echo
    echo "If you are reconfiguring an already-configured Discourse, use "
    echo
    echo "./launcher stop app"
    echo
    echo "to stop Discourse before you reconfigure it and try again."
    exit 1
  fi
  
  echo "check_port finished"
}

##
## Check requirements before creating a copy of a config file we won't edit
##
check_root
check_docker
check_disk_and_memory
