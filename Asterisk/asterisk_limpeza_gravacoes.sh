#!/bin/bash
# Remove gravacoes mais antigas que 365 dias
#  do diretorio $AsteriskGravacoesDir/
# v0.1 - Criacao do script - Raul Liborio, raul.liborio@solutis.com.br


# - Variaveis
Mail="raul.liborio@solutis.com.br"
#Mail="n3@solutis.com.br"

# -- Diretorio das gravacoes do Asterisk
AsteriskGravacoesDir="/opt/asterisk/monitor"

Data="$( date +%d-%m-%Y )"

Ontem="$( date --date="yesterday" "+%Y/%m/%d" )"
# -- Quantifica qtos arquivos foram gravados no dia anterior
ArquivosOntem="$( ls $AsteriskGravacoesDir/$Ontem | wc -l )"

AnteOntem="$( date --date="-2 days" "+%Y/%m/%d" )"
# -- Quantifica qtos arquivos foram gravados 2 dias antes
ArquivosAnteOntem="$( ls $AsteriskGravacoesDir/$AnteOntem | wc -l )"

# -- Arquivo de log
MailFile="/var/log/asterisk/gravacoes_removidas.log" 
# -- Log de arquivos removidos pelo cmd 'find'
RemovidosLog="$( mktemp )"
# -- Informacoes do servidor e outras informacoes coletadas
Status="$( mktemp )"
# -- Calcula o tamanho do diretorio antes da remocao
TamanhoAntes="$( du -sb $AsteriskGravacoesDir | cut -f1 )"

# - Exec
# --- Remove arquivos mais antigos que 365 dias
# ----- O parametro -mtime define a idade dos arquivos
find /opt/asterisk/monitor -mtime +365 -printf "%k KB\t %p \n" -delete >> $RemovidosLog

# --- Se o diretorio $AsteriskGravacoesDir/fop2 for removido, recrie
[[ ! -d $AsteriskGravacoesDir/fop2 ]] && \
mkdir $AsteriskGravacoesDir/fop2 && \
chown asterisk.asterisk $AsteriskGravacoesDir/fop2 && \
chmod 770 $AsteriskGravacoesDir/fop2

TamanhoDepois=$(du -sb $AsteriskGravacoesDir | cut -f1)
TamanhoFinal=$(( TamanhoAntes - TamanhoDepois ))

# --- Converte valor da variavel TamanhoFinal de bytes para Megabytes
TamanhoMB=$( echo "scale=2; $TamanhoFinal / 1048576" | bc -l )

# --- Crescimento em % comparado ao dia anterior
CrescimentoPorcentagem="$(echo "scale=2; ($ArquivosOntem - $ArquivosAnteOntem) * 100  / $ArquivosOntem" | bc -l )"

# --- corpo do email
echo -e '--------------------------------------------------------------------------------
Status de remocao de gravacoes mais antigas que 365 dias
--------------------------------------------------------------------------------
' > $Status

LANG="pt_BR"
echo -e "Host:\t\t$HOSTNAME
SO:\t\t$( cat /etc/redhat-release )\n
Execucao:\t$( date "+%d/%m/%Y %T (%A)" )
Diretorio:\t$AsteriskGravacoesDir
Removidos:\t$( wc -l < $RemovidosLog ) arquivos
Liberado:\t${TamanhoMB} MB

Status das gravacoes em $( date --date="yesterday" "+%d/%m/%Y (%A)" )
Novos:\t\t$( ls $AsteriskGravacoesDir/$Ontem | wc -l ) arquivos
Crescimento:\t$( du -sh $AsteriskGravacoesDir/$Ontem | cut -f1 )
Porcentagem:\t$CrescimentoPorcentagem% em relacao a $(date --date="-2 days" "+%d/%m/%Y (%A)") 

Uso de disco:
$( df -hP | awk /mapper/'{print $5"\t"$NF}' )
--------------------------------------------------------------------------------

Arquivos removidos:
" >> $Status

# --- Condensando as informacoes em um unico arquivo 
cat $Status $RemovidosLog > $MailFile

# - envio de relatorio
mail -s "Remocao de gravacoes do host $HOSTNAME" $Mail < $MailFile

# --- remocao dos arquivos temporarios
sleep 2 && rm -f $Status $RemovidosLog
exit 0
