#!/bin/bash
# Script: liberabloqueia.sh
# Revisao: 0.3
# Desc: Ativa e detativa diretorio web via url, necessário o uso de SSL.
# Autor: Alan Victor, alanvictorjp gmail com
# Criado: 08/06/2019
# Modificado: 23/08/2019

# Locais
################################################################################
# url para liberar [ https://eae.com/qwert123 ]
open='farsaon'

# url para bloquear [ https://eae.com/qwert321 ]
close='farsaoff'

# Arquivo de log do apache referente ao vhost
log="/var/log/apache/eae.com.log"

# Arquivo conf do apache referente ao vhost
conf="/etc/apache2/sites-available/eae.com-ssl.conf"

# Ips locais permitidos
whitelist="192.168.200.2 192.168.200.3"

################################################################################
# Constantes
named=$(basename $0)
logfile=/var/log/$named
null=/dev/null
pidfile=/var/run/$(basename $0).pid
# Cores
codigo="\033["
vermelhoClaro="1;31m";
verdeClaro="1;32m";
finall="\033[0m"

# testes
################################################################################
[ ! -f $logfile ] && { touch $logfile ; }
################################################################################

# funcoes
################################################################################
eco_verde_claro() {	echo -ne "${codigo}${verdeClaro}$*${finall}";		}
eco_vermelho_claro() {	echo -ne "${codigo}${vermelhoClaro}$*${finall}";	}

_help() {		eco_verde_claro "\n ajuda!\n\n";			}
_is_running() {		[[ -f $pidfile ]] && { return 0 ; } || { return 1 ; }	}
_restart() {		_stop ; _start;						}

_stop() {
	_is_running && {
		kill -9 $(cat $pidfile) &> $null;
		sleep 0.5
		rm -rf $pidfile &> $null && {
			eco_verde_claro "\n $named parado!\n\n";
			return 0;
		} || {
			eco_vermelho_claro "\n PIDfile nao encontrado!\n\n"
			return 1;
		}
	} || {
		eco_vermelho_claro "\n $named nao estava rodando!\n\n";
		return 1;
	}
}

_start() {
	_is_running && {
		eco_vermelho_claro "\n $named estava rodando!\n\n";
		return 1;
	} || {
		_daemon;
		sleep 0.5
		eco_verde_claro "\n $named iniciado!\n\n";
		return 0;
	}
}


_status() {
	_is_running && {
		eco_verde_claro "\n $named esta rodando!\n";
		eco_verde_claro " PID: $(cat $pidfile)\n\n";
	} || {
		eco_vermelho_claro "\n $named nao esta rodando!\n\n";
	}
}
################################################################################

# daemon
################################################################################
_daemon() {

	export LC_ALL=C
	while : ; do

	        atual0=$(date "+%d/%b/%Y:%H:%M")
	        seg=$(date "+%S" | sed 's/.$//')
	        atual="$atual0:$seg"

	        ip_libera=$(tail -n2 $log | grep -i "${atual}.*${open}" | sed 's/ - - .*//' | head -n1)
	        if [[ $ip_libera ]] ; then
	                cat $conf | grep -q "^Require ip $whitelist ${ip_libera}$" || {
	                        sed -i "s/\(Require ip $whitelist\)/\1 $ip_libera/" $conf ;
	                        service apache2 restart ;
	                }
	        fi

	        ip_bloqueia=$(tail -n2 $log | grep -i "${atual}.*${close}" | sed 's/ - - .*//' | head -n1)
	        if [[ $ip_bloqueia ]] ; then
	                cat $conf | grep -q "^Require ip $whitelist ${ip_bloqueia}$" && {
	                        sed -i "s/\(Require ip $whitelist\).*/\1/" $conf ;
	                        service apache2 restart ;
	                }
	        fi
	        sleep 2

	done &
	echo $! > $pidfile
}

################################################################################
case $1 in
	start)		_start ;;
	stop)		_stop ;;
	restart)	_restart ;;
	status)		_status ;;
	*)		_help ;;
esac
################################################################################
