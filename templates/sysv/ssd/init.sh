#!/bin/bash

### BEGIN INIT INFO
# Provides:          {{{ name }}}
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: {{{ one_line_description }}}
# Description:       {{{ description }}}
### END INIT INFO

SSD="/usr/sbin/start-stop-daemon";
PATH="/sbin:/usr/sbin:/bin:/usr/bin"
export PATH

[ -r /etc/default/$name ] && . /etc/default/$name
[ -r /etc/sysconfig/$name ] && . /etc/sysconfig/$name


name={{#escaped}}{{#safe_filename}}{{{ name }}}{{/safe_filename}}{{/escaped}}
program={{#escaped}}{{{ program }}}{{/escaped}}
args={{{ escaped_args }}}
pidfile="/var/run/$name.pid"
logfile="/var/log/$name.log";
stdout="/var/log/$name.stdout.log";
stderr="/var/log/$name.stderr.log";

usage() {
  echo "Usage: /etc/init.d/$0 {start|stop|restart|console}"
}

start() {
  touch $stderr && chown $user.$user $stderr
  touch $stdout && chown $user.$user $stdout
  touch $log    && chown $user.$user $log
  $SSD --start -v -c $user -g $user -p $pidfile -b -a $program -- $args >>$stdout 2>>$stderr
}

stop() {
  $SSD --stop -v -c $user -g $user -p $pidfile -s TERM;
}

force-stop() {
 $SSD --stop -v -c $user -g $user -p $pidfile -s KILL;
}

status() {
  $SSD --status -v -c $user -g $user -p $pidfile;
  retval="$?";
  [[ "$retval" == "0" ]] && echo "{{{ one_line_description }}} Running ($(cat $pidfile))";
  [[ "$retval" == "0" ]] || echo "{{{ one_line_description }}} Stopped";
  exit $retval;
}

console() {
  tail -f $log;
}

case "$1" in
  "start")    start   ;;
  "stop")     stop    ;;
  "restart")  stop && sleep 1 && start ;;
  "status")   status  ;;
  "console")  console ;;
  *)          usage   ;;
esac;
