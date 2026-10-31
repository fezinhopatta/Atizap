#!/bin/bash

BKP_FONTE="/home/nethunter/atizap/logs/sucesso.log"
BKP_DESTINO="/home/nethunter/BACKUP_ATIZAP/"
DATA=$(date +%Y%m%d%H%M%S)
NOME_BKP="sucesso_$DATA.tar.gz"

#compactar e mandar pro ~/BACKUP_ATIZAP
tar -czf "$BKP_DESTINO/$NOME_BKP" "$BKP_FONTE"

if [ $? -eq 0 ]; then
	echo "BACKUP CRIADO COM SUCESSO"
else
	echo "BACKUP COM FALHA"
fi
