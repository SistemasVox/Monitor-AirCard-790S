#!/bin/bash

# Instale o "jq" antes de executar este script
# sudo apt-get install jq -y (para sistemas baseados em Debian/Ubuntu)
# sudo yum install jq -y (para sistemas baseados em RHEL/CentOS/Fedora)

# Funções para formatar as informações
format_datetime() {
  if [ -n "$1" ]; then
    date -d "@$1" +"%I:%M:%S %p"
  else
    echo "Data e hora não disponíveis"
  fi
}


format_temperature() {
  printf "%.1f°C" "$1"
}

format_voltage() {
  voltage=$(echo "scale=4; $1 / 1000" | bc -l)
  voltage=$(echo "$voltage")
  printf "%0.2fV" "$voltage"
  # voltage=$(echo "$voltage" | tr '.' ',')
  # LC_NUMERIC="pt_BR.UTF-8" printf "%0.2fV" "$voltage" | tr ',' '.'
}

format_battery() {
  printf "%.0f%%" "$1"
}

format_duration() {
  if [ -z "$1" ] || [ "$1" -eq 0 ]; then
    echo "00h 00m 00s"
  else
    printf "%02dh %02dm %02ds" $(($1/3600)) $(($1%3600/60)) $(($1%60))
  fi
}

format_bytes() {
  if [ -n "$1" ]; then
    numfmt --to=iec-i --suffix=B --padding=7 "$1"
  else
    echo "Valor de bytes não disponível"
  fi
}


# Função para fazer requisições GET
fetch_data() {
  random_x=$((10000 + RANDOM % 99999))
  url="http://192.168.1.1/api/model.json?internalapi=1&x=$random_x"
  response=$(curl -s -L "$url")
  # Substituir caracteres de controle por espaços em branco
  clean_response=$(echo "$response" | tr -d '\n' | tr -c '[:print:]\n' ' ')
  # Formatar JSON com jq
  formatted_response=$(echo "$clean_response" | jq '.')
  # Imprimir saída formatada
  echo "$formatted_response"
}

# Função para formatar bytes
format_bytes() {
  if [ -n "$1" ]; then
    value=$1
    units=("B" "KB" "MB" "GB" "TB")
    for unit in "${units[@]}"; do
      if (( $(echo "$value < 1024" | bc -l) )); then
        break
      fi
      value=$(echo "scale=2; $value / 1024" | bc)
    done
    echo "${value} ${unit}"
  else
    echo "Valor de bytes não disponível"
  fi
}

# Função para formatar bytes por segundo para Mbps
format_mbps() {
  value=$1
  value=$(echo "scale=2; $value * 8 / 1000000" | bc)
  printf "%0.2f Mbps\n" "${value:-0}"
  # value=$(echo "$value" | tr '.' ',')
  # LC_NUMERIC="pt_BR.UTF-8" printf "%0.2f Mbps\n" ${value:-0} | tr ',' '.'
}

# Função para calcular velocidades de conexão
calculate_speeds() {
  curr_time=$1
  prev_time=$2
  curr_data_transferred=$3
  prev_data_transferred=$4
  curr_data_transferred_rx=$5
  prev_data_transferred_rx=$6
  curr_data_transferred_tx=$7
  prev_data_transferred_tx=$8

  time_diff=$(echo "$curr_time - $prev_time" | bc)

  # Inicializa as velocidades com zero
  total_speed=0
  download_speed=0
  upload_speed=0

  # Calcula as velocidades se o tempo anterior e a quantidade anterior estiverem definidos
  if [[ -n "$prev_data_transferred" && -n "$prev_time" && $time_diff -ne 0 ]]; then
    total_speed=$(echo "scale=2; ($curr_data_transferred - $prev_data_transferred) / $time_diff" | bc -l)
    download_speed=$(echo "scale=2; ($curr_data_transferred_rx - $prev_data_transferred_rx) / $time_diff" | bc -l)
    upload_speed=$(echo "scale=2; ($curr_data_transferred_tx - $prev_data_transferred_tx) / $time_diff" | bc -l)
  fi

  echo "$total_speed $download_speed $upload_speed"
}

function calculate_average_speed() {
  duration=$1
  total_data=$2

  # Calcula a velocidade média
  if [[ -n "$duration" && $duration -ne 0 ]]; then
    avg_speed=$(echo "scale=2; $total_data / $duration" | bc -l)
  fi

  echo "$avg_speed"
}

# Intervalo de tempo entre as atualizações (em segundos)
interval=5

# Função para obter o IP local
function get_local_ip() {
  local_ip=$(hostname -I | awk '{print $1}')
  echo "$local_ip"
}

# Função para obter o gateway
function get_gateway() {
  gateway=$(ip route | awk '/via/ {print $4}')
  if [ -z "$gateway" ]; then
    echo "Erro: Gateway não encontrado."
    return 1
  fi

  echo "$gateway"
  return 0
}

# Função para obter o IP público
function get_public_ip() {
  public_ip=$(curl -s https://api.ipify.org)
  echo "$public_ip"
}

# Obtendo informações de IP
local_ip=$(get_local_ip)
gateway=$(get_gateway)
public_ip=$(get_public_ip)

# Função para imprimir informações do dispositivo
print_device_info() {
  echo "---- Dispositivo -----------"
  echo "Nome: $device_name."
  echo "Hora: $(format_datetime "$curr_time")."
  echo "Temperatura: $(format_temperature "$dev_temperature")."
  echo "Temperatura MAX: $(format_temperature "$ver_major")."
  echo "----------------------------"
}

# Função para imprimir informações da bateria
print_battery_info() {
  echo "---- Bateria ---------------"
  echo "Status: $pm_state"
  echo "Temperatura: $(format_temperature "$battery_temperature")."
  echo "Voltagem: $(format_voltage "$battery_voltage")."
  echo "Carga: $(format_battery "$batt_charge_level")."
  echo "Fonte: $batt_charge_source."
  echo "Estado: $battery_state."
  echo "----------------------------"
}

# Função para imprimir informações da operadora
print_operator_info() {
  echo "------- Torre -------------"
  echo "Banda: $cur_band"
  echo "radioQuality: $radio_quality dBm."
  echo "Rede: $operadora."
  print_bars_info
  echo "Torre: $cell_id."
  echo "LAC: $LAC."
  echo "MCC: $MCC."
  echo "MNC: $MNC."
  print_rsrp_info
  print_rsrq_info
  print_sinr_info
  print_qualidade_sinal
  echo "----------------------------"
}

print_bars_info() {
  if [ "$bars" -eq 0 ]; then
    echo "Barras: Sem sinal."
  elif [ "$bars" -eq 1 ]; then
    echo "Barras: $bars (sinal muito fraco)."
  elif [ "$bars" -eq 2 ]; then
    echo "Barras: $bars (sinal fraco)."
  elif [ "$bars" -eq 3 ]; then
    echo "Barras: $bars (sinal moderado.)"
  elif [ "$bars" -eq 4 ]; then
    echo "Barras: $bars (sinal bom)."
  elif [ "$bars" -eq 5 ]; then
    echo "Barras: $bars (sinal excelente)."
  else
    echo "Barras: Valor inválido."
  fi
}

# print_rsrp_info() {
  # if [ "$rsrp" -gt -65 ]; then
    # echo "RSRP: $rsrp dBm (sinal excelente)."
  # elif [ "$rsrp" -gt -75 ]; then
    # echo "RSRP: $rsrp dBm (sinal bom)."
  # elif [ "$rsrp" -gt -85 ]; then
    # echo "RSRP: $rsrp dBm (sinal médio)."
  # elif [ "$rsrp" -gt -95 ]; then
    # echo "RSRP: $rsrp dBm (sinal fraco)."
  # else
    # echo "RSRP: $rsrp dBm (sem sinal)."
  # fi
# }

print_rsrp_info() {
  if [ "$rsrp" -ge -80 ]; then
    echo "RSRP: $rsrp dBm (sinal excelente)."
  elif [ "$rsrp" -ge -90 ]; then
    echo "RSRP: $rsrp dBm (sinal bom)."
  elif [ "$rsrp" -ge -100 ]; then
    echo "RSRP: $rsrp dBm (sinal regular a fraco)."
  else
    echo "RSRP: $rsrp dBm (sem sinal)."
  fi
}
print_rsrq_info() {
  if [ "$rsrq" -gt -10 ]; then
    echo "RSRQ: $rsrq dB (sinal excelente)."
  elif [ "$rsrq" -gt -15 ]; then
    echo "RSRQ: $rsrq dB (sinal bom)."
  elif [ "$rsrq" -gt -20 ]; then
    echo "RSRQ: $rsrq dB (sinal ruim)."
  else
    echo "RSRQ: $rsrq dB (sinal fraco)."
  fi
}

print_sinr_info() {
  if [ "$sinr" -ge 20 ]; then
    echo "SINR: $sinr dB (sinal excelente)."
  elif [ "$sinr" -ge 13 ]; then
    echo "SINR: $sinr dB (sinal bom)."
  elif [ "$sinr" -ge 0 ]; then
    echo "SINR: $sinr dB (sinal ruim)."
  else
    echo "SINR: $sinr dB (sinal fraco)."
  fi
}

# Função para calcular as velocidades médias
calculate_average_speeds() {
  local duration="$1"
  local data_total="$2"
  local data_download="$3"
  local data_upload="$4"

  # Verifica se os campos necessários estão presentes e não são nulos
  if [ "$duration" != "null" ] && [ "$data_total" != "null" ] && [ "$data_download" != "null" ] && [ "$data_upload" != "null" ]; then
    average_speed=$(calculate_average_speed "$duration" "$data_total")
    average_speed_formatted=$(format_bytes "$average_speed")
    average_speed_mbps=$(format_mbps "$average_speed")

    average_download_speed=$(calculate_average_speed "$duration" "$data_download")
    average_download_speed_formatted=$(format_bytes "$average_download_speed")
    average_download_speed_mbps=$(format_mbps "$average_download_speed")

    average_upload_speed=$(calculate_average_speed "$duration" "$data_upload")
    average_upload_speed_formatted=$(format_bytes "$average_upload_speed")
    average_upload_speed_mbps=$(format_mbps "$average_upload_speed")
  else
    average_speed=0
    average_speed_formatted="0 B"
    average_speed_mbps="0 Mbps"

    average_download_speed=0
    average_download_speed_formatted="0 B"
    average_download_speed_mbps="0 Mbps"

    average_upload_speed=0
    average_upload_speed_formatted="0 B"
    average_upload_speed_mbps="0 Mbps"
  fi
}

# Função para imprimir informações de conexão
print_connection_info() {
  # Chama a função calculate_average_speeds
  calculate_average_speeds "$sess_duration" "$data_transferred" "$data_transferred_rx" "$data_transferred_tx"

  echo "---- Conexão ---------------"
  echo "Conexão: $connection_text."
  echo "Tipo de Conexão: $current_ps_service_type."
  echo "Operadora: $register_network_display."
  echo "GW: $gateway."
  echo "LI: $local_ip."
  echo "GW: $cg."
  echo "IP: $public_ip."
  echo "-------- Sessão -----------"
  echo "Duração: $(format_duration "$sess_duration")."
  echo "Início: $(format_datetime "$sess_start_time")."
  echo "Dados total: $(format_bytes "$data_transferred")."
  echo "Download total: $(format_bytes "$data_transferred_rx")."
  echo "Upload total: $(format_bytes "$data_transferred_tx")."
  echo "FULL: $average_speed_formatted/s. $average_speed_mbps."
  echo "UP: $average_download_speed_formatted/s. $average_download_speed_mbps."
  echo "Down: $average_upload_speed_formatted/s. $average_upload_speed_mbps."
  echo "----------------------------"
}

# Função para imprimir informações de velocidade de conexão
print_speed_info() {
  echo "---- Velocidade ----"
  echo "Total: $total_speed_formatted/s. $total_speed_mbps."
  echo "Download: $download_speed_formatted/s. $download_speed_mbps."
  echo "Upload: $upload_speed_formatted/s. $upload_speed_mbps."
  echo "----------------------------"
}

# Função para extrair informações do JSON
extract_info() {
  local json="$1"

  device_name=$(echo "$json" | jq -r '.general.deviceName')
  curr_time=$(echo "$json" | jq -r '.general.currTime')
  dev_temperature=$(echo "$json" | jq -r '.general.devTemperature')
  ver_major=$(echo "$json" | jq -r '.general.verMajor')

  pm_state=$(echo "$json" | jq -r '.power.PMState // "N/A"')
  battery_temperature=$(echo "$json" | jq -r '.power.batteryTemperature')
  battery_voltage=$(echo "$json" | jq -r '.power.batteryVoltage')
  batt_charge_level=$(echo "$json" | jq -r '.power.battChargeLevel')
  batt_charge_source=$(echo "$json" | jq -r '.power.battChargeSource // "N/A"')
  battery_state=$(echo "$json" | jq -r '.power.batteryState // "N/A"')

  connection_text=$(echo "$json" | jq -r '.wwan.connectionText')
  current_ps_service_type=$(echo "$json" | jq -r '.wwan.currentPSserviceType')
  cur_band=$(echo "$json" | jq -r '.wwanadv.curBand')
  bars=$(echo "$json" | jq -r '.wwan.signalStrength.bars // "N/A"')
  rsrp=$(echo "$json" | jq -r '.wwan.signalStrength.rsrp // "N/A"')
  rssi=$(echo "$json" | jq -r '.wwan.signalStrength.rssi // "N/A"')
  rsrq=$(echo "$json" | jq -r '.wwan.signalStrength.rsrq // "N/A"')
  sinr=$(echo "$json" | jq -r '.wwan.signalStrength.sinr // "N/A"')  
  
  register_network_display=$(echo "$json" | jq -r '.wwan.registerNetworkDisplay // "N/A"')
  cell_id=$(echo "$json" | jq -r '.wwanadv.cellId // "N/A"')
  radio_quality=$(echo "$json" | jq -r '.wwanadv.radioQuality // "N/A"')
  LAC=$(echo "$json" | jq -r '.wwanadv.LAC // "N/A"')
  MCC=$(echo "$json" | jq -r '.wwanadv.MCC // "N/A"')
  MNC=$(echo "$json" | jq -r '.wwanadv.MNC // "N/A"')
  operadora=$(map_mnc_to_operadora "$MNC")

  cg=$(echo "$json" | jq -r '.wwan.IP // "N/A"')
  sess_duration=$(echo "$json" | jq -r '.wwan.sessDuration')
  sess_start_time=$(echo "$json" | jq -r '.wwan.sessStartTime')
  data_transferred=$(echo "$json" | jq -r '.wwan.dataTransferred')
  data_transferred_rx=$(echo "$json" | jq -r '.wwan.dataTransferredRx')
  data_transferred_tx=$(echo "$json" | jq -r '.wwan.dataTransferredTx')
}

map_mnc_to_operadora() {
  case "$1" in
    "00")
      echo "Nextel"
      ;;
    "02" | "03" | "04")
      echo "TIM"
      ;;
    "05")
      echo "Claro"
      ;;
    "06" | "10" | "11" | "12")
      echo "Vivo"
      ;;
    "15")
      echo "Sercomtel"
      ;;
    "16")
      echo "Brasil Telecom GSM"
      ;;
    "17")
      echo "Surf Telecom"
      ;;
    "18")
      echo "datora"
      ;;
    "21")
      echo "LIGUE"
      ;;
    "23")
      echo "Vivo"
      ;;
    "28")
      echo "No name"
      ;;
    "29")
      echo "Unifique"
      ;;
    "30" | "31")
      echo "Oi"
      ;;
    "32" | "33" | "34")
      echo "Algar Telecom"
      ;;
    "38")
      echo "Claro"
      ;;
    "39")
      echo "Nextel"
      ;;
    "54")
      echo "Conecta"
      ;;
    "99")
      echo "Local"
      ;;
    *)
      echo "N/A"
      ;;
  esac
}

print_qualidade_sinal() {
  if [ "$rssi" != "N/A" ] && [ "$sinr" != "N/A" ] && [ "$rsrp" != "N/A" ] && [ "$rsrq" != "N/A" ]; then
    if [ "$rssi" -ge -65 ] && [ "$sinr" -ge 20 ] && [ "$rsrp" -ge -80 ] && [ "$rsrq" -ge -10 ]; then
      echo "Qualidade total: Excelente!"
    elif [ "$rssi" -ge -75 ] && [ "$sinr" -ge 13 ] && [ "$rsrp" -ge -90 ] && [ "$rsrq" -ge -15 ]; then
      echo "Qualidade total: Bom!"
    elif [ "$rssi" -ge -85 ] && [ "$sinr" -ge 0 ] && [ "$rsrp" -ge -100 ] && [ "$rsrq" -ge -20 ]; then
      echo "Qualidade total: Médio!"
    elif [ "$rssi" -ge -95 ] && [ "$sinr" -ge 0 ] && [ "$rsrp" -ge -100 ] && [ "$rsrq" -ge -20 ]; then
      echo "Qualidade total: Fraco!"
    else
      echo "Sem sinal!"
    fi
  else
    echo "Não foi possível obter a qualidade do sinal!"
  fi
}


# Função para calcular e formatar as velocidades
calculate_and_format_speeds() {
  local curr_time="$1"
  local prev_time="$2"
  local json="$3"
  local prev_data="$4"

  prev_total_data_transferred=$(echo "$prev_data" | jq -r '.wwan.dataTransferred')
  prev_total_data_transferred_rx=$(echo "$prev_data" | jq -r '.wwan.dataTransferredRx')
  prev_total_data_transferred_tx=$(echo "$prev_data" | jq -r '.wwan.dataTransferredTx')

  # Calcula as velocidades
  speeds=$(calculate_speeds "$curr_time" "$prev_time" "$data_transferred" "$prev_total_data_transferred" "$data_transferred_rx" "$prev_total_data_transferred_rx" "$data_transferred_tx" "$prev_total_data_transferred_tx")
  total_speed=$(echo "$speeds" | awk '{print $1}')
  download_speed=$(echo "$speeds" | awk '{print $2}')
  upload_speed=$(echo "$speeds" | awk '{print $3}')

  # Formata as velocidades
  total_speed_formatted=$(format_bytes "$total_speed")
  download_speed_formatted=$(format_bytes "$download_speed")
  upload_speed_formatted=$(format_bytes "$upload_speed")
  total_speed_mbps=$(format_mbps "$total_speed")
  download_speed_mbps=$(format_mbps "$download_speed")
  upload_speed_mbps=$(format_mbps "$upload_speed")
}

# Define o intervalo em segundos entre cada atualização
interval=5

# Loop infinito para coletar e exibir informações
while true; do
  # Coleta os dados em formato JSON
  json=$(fetch_data)

  # Extrai as informações relevantes usando a função extract_info
  extract_info "$json"

  # Exibe as informações formatadas
  clear
  print_device_info
  print_battery_info
  print_operator_info
  print_connection_info

  # Calcula e imprime as velocidades, se prev_data e prev_time estão definidos
  if [[ -n "$prev_data" && -n "$prev_time" ]]; then
    calculate_and_format_speeds "$curr_time" "$prev_time" "$json" "$prev_data"
    # Imprime as velocidades formatadas
    print_speed_info
  fi

  # Define prev_data e prev_time para a próxima iteração
  prev_data="$json"
  prev_time="$curr_time"

  # Aguarda o intervalo especificado antes de atualizar as informações
  sleep $interval
done


# operadora.txt
# 02:TIM
# 05:Claro
# 23:VIVO
# 31:Oi
# 34:Algar Telecom
# 99:Local

# operadora=$(grep -E "^$MNC:" operadora.txt | cut -d ':' -f 2)

# if [ -z "$operadora" ]; then
  # operadora="N/A"
# fi

# --- Segundo exemplo de uso ----
# operadora.txt:
# 0,Nextel
# 2,TIM
# 3,TIM
# 4,TIM
# 5,Claro
# 6,Vivo
# 10,Vivo
# 11,Vivo
# 12,Claro
# 15,Sercomtel
# 16,Brasil Telecom GSM
# 17,Surf Telecom
# 18,datora
# 21,LIGUE
# 23,Vivo
# 24,
# 28,No name
# 29,Unifique
# 30,Oi
# 31,Oi
# 32,Algar Telecom
# 33,Algar Telecom
# 34,Algar Telecom
# 35,
# 36,
# 37,aeiou
# 38,Claro
# 39,Nextel
# 54,Conecta
# 99,Local


# map_mnc_to_operadora() {
  # local mnc=$1
  # local operadora="N/A"

#  Lê o arquivo operadora.txt linha por linha
  # while IFS=, read -r code name; do
    # if [ "$mnc" = "$code" ]; then
      # operadora="$name"
      # break
    # fi
  # done < operadora.txt

  # echo "$operadora"
# }
