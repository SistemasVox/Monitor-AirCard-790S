#!/bin/bash

# Instale o "jq" antes de executar este script
# sudo apt-get install jq -y (para sistemas baseados em Debian/Ubuntu)
# sudo yum install jq -y (para sistemas baseados em RHEL/CentOS/Fedora)

# Funções para formatar as informações
format_datetime() {
  date -d "@$1" +"%I:%M:%S %p"
}

format_temperature() {
  printf "%.1f°C" "$1"
}

format_voltage() {
  voltage=$(echo "scale=4; $1 / 1000" | bc -l)
  printf "%.2fV" "$voltage"
}

format_battery() {
  printf "%.0f%%" "$1"
}

format_duration() {
  printf "%02dh %02dm %02ds" $(($1/3600)) $(($1%3600/60)) $(($1%60))
}

format_bytes() {
  numfmt --to=iec-i --suffix=B --padding=7 "$1"
}

# Função para fazer requisições GET
function fetch_data() {
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
function format_bytes() {
  value=$1
  units=("B" "KB" "MB" "GB" "TB")
  for unit in "${units[@]}"; do
    if (( $(echo "$value < 1024" | bc -l) )); then
      break
    fi
    value=$(echo "scale=2; $value / 1024" | bc)
  done
  echo "${value} ${unit}"
}

# Função para formatar bytes por segundo para Mbps
function format_mbps() {
  value=$1
  value=$(echo "scale=2; $value * 8 / 1000000" | bc)
  printf "%.2f Mbps\n" ${value:-0}
}

# Função para calcular velocidades de conexão
function calculate_speeds() {
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
  if [[ -n "$prev_data_transferred" && -n "$prev_time" ]]; then
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
  avg_speed=$(echo "scale=2; $total_data / $duration" | bc -l)

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
  echo "---- Operadora -------------"
  echo "Conexão: $connection_text."
  echo "Tipo de Conexão: $current_ps_service_type."
  echo "Banda: $cur_band"
  echo "Barras: $bars."
  echo "RSRP: $rsrp dBm."
  echo "RSRQ: $rsrq dB."
  echo "SINR: $sinr dB."
  echo "Operadora: $register_network_display."
  echo "Torre: $cell_id."
  echo "radioQuality: $radio_quality dBm."
  echo "----------------------------"
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
  echo "GW: $gateway."
  echo "LI: $local_ip."
  echo "GW: $cg."
  echo "IP: $public_ip."
  echo "Duração: $(format_duration "$sess_duration")."
  echo "Início: $(format_datetime "$sess_start_time")."
  echo "Dados total: $(format_bytes "$data_transferred")."
  echo "Download total: $(format_bytes "$data_transferred_rx")."
  echo "Upload total: $(format_bytes "$data_transferred_tx")."
  echo "Velocidade média total: $average_speed_formatted/s. $average_speed_mbps."
  echo "Velocidade média de download: $average_download_speed_formatted/s. $average_download_speed_mbps."
  echo "Velocidade média de upload: $average_upload_speed_formatted/s. $average_upload_speed_mbps."
  echo "----------------------------"
}

# Função para imprimir informações de velocidade de conexão
print_speed_info() {
  echo "---- Velocidade Conexão dos últimos ${interval}s ----"
  echo "Total: $total_speed_formatted/s. $total_speed_mbps."
  echo "Download: $download_speed_formatted/s. $download_speed_mbps."
  echo "Upload: $upload_speed_formatted/s. $upload_speed_mbps."
  echo "----------------------------"
}

# Função para extrair informações do JSON
function extract_info() {
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
  rsrq=$(echo "$json" | jq -r '.wwan.signalStrength.rsrq // "N/A"')
  sinr=$(echo "$json" | jq -r '.wwan.signalStrength.sinr // "N/A"')
  register_network_display=$(echo "$json" | jq -r '.wwan.registerNetworkDisplay // "N/A"')
  cell_id=$(echo "$json" | jq -r '.wwanadv.cellId // "N/A"')
  radio_quality=$(echo "$json" | jq -r '.wwanadv.radioQuality // "N/A"')

  cg=$(echo "$json" | jq -r '.wwan.IP // "N/A"')
  sess_duration=$(echo "$json" | jq -r '.wwan.sessDuration')
  sess_start_time=$(echo "$json" | jq -r '.wwan.sessStartTime')
  data_transferred=$(echo "$json" | jq -r '.wwan.dataTransferred')
  data_transferred_rx=$(echo "$json" | jq -r '.wwan.dataTransferredRx')
  data_transferred_tx=$(echo "$json" | jq -r '.wwan.dataTransferredTx')
}

# Função para calcular e formatar as velocidades
function calculate_and_format_speeds() {
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
