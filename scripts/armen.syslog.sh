#!/bin/bash
#######
##   ___ _______ _  ___ ___       _______  _______
##  / _ `/ __/  ' \/ -_) _ \  _  / __/ _ \/ __/ -_)
##  \_,_/_/ /_/_/_/\__/_//_/ (_) \__/\___/_/  \__/
##
####### Ecosystème basé sur les microservices ##################### (c) 2018 losyme ####### @(°_°)@

tail -n 500 -f /var/log/armen/armen.log | mawk -Wi '
  /{INF}/ {print $0}
  /{DEB}/ {print "\033[36m" $0 "\033[39m"}
  /{NOT}/ {print "\033[32m" $0 "\033[39m"}
  /{WAR}/ {print "\033[33m" $0 "\033[39m"}
  /{ERR}/ {print "\033[31m" $0 "\033[39m"}
  /{CRI}/ {print "\033[41m\033[30m" $0 "\033[49m\033[39m"}
'

####### END
