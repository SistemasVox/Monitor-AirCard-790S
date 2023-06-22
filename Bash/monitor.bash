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
  # Definir um tempo limite de 2 segundos para a solicitação
  response=$(curl -sf -m 2 -L "$url")
  curl_exit_status=$?

  if [ $curl_exit_status -eq 0 ] && [ -n "$response" ]; then
    clean_response=$(echo "$response" | tr -d '\n' | tr -c '[:print:]\n' ' ')
    formatted_response=$(echo "$clean_response" | jq '.')
    echo "$formatted_response"
	return 0
  else
    echo "Request timed out or response is empty" >&2
    # Marcar a solicitação como falha
    return 1
  fi
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
  if [ -n "$public_ip" ]; then
    echo "$public_ip"
  else
    echo "0.0.0.0"
  fi
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

# Função para imprimir informações de conexão
print_connection_info() {
  # Chama a função calculate_average_speeds
  calculate_average_speeds "$sess_duration" "$data_transferred" "$data_transferred_rx" "$data_transferred_tx"

  echo "---- Conexão ---------------"
  echo "Conexão: $connection_text."
  echo "Tipo de Conexão: $current_ps_service_type."
  echo "Operadora: $register_network_display."
  echo "PING: $(verificar_conexao)."
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

# Função para imprimir informações da operadora
print_operator_info() {
  echo "------- Torre -------------"
  echo "Rede: $operadora."
  print_band_info
  echo "radioQuality: $radio_quality dBm."
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

verificar_conexao() {
  # Executa o comando ping com os parâmetros desejados
  ping -c 1 -W 1 8.8.8.8 > /dev/null 2>&1

  # Verifica o status de saída do comando ping
  if [ $? -eq 0 ]; then
    echo "Conectado"
  else
    echo -e "Sem internet\a"
  fi
}

print_band_info() {
  if [ -n "$cur_band" ]; then
    if [[ "$cur_band" != *"LTE"* ]]; then
      echo "Banda: $cur_band."
    else
      trimmed_band="${cur_band#"LTE "}"  # Remover "LTE " do início da string

      case $trimmed_band in
        "B1")
          echo "Banda: $cur_band (2100 MHz)."
          ;;
        "B2")
          echo "Banda: $cur_band (1900 MHz)."
          ;;
        "B3")
          echo "Banda: $cur_band (1800 MHz)."
          ;;
        "B4")
          echo "Banda: $cur_band (1700 MHz)."
          ;;
        "B5" | "B6" | "B26" | "B27")
          echo "Banda: $cur_band (850 MHz)."
          ;;
        "B7" | "B65")
          echo "Banda: $cur_band (2600 MHz)."
          ;;
        "B8" | "B18" | "B19")
          echo "Banda: $cur_band (900 MHz)."
          ;;
        "B9" | "B21")
          echo "Banda: $cur_band (1800 MHz)."
          ;;
        "B10" | "B11" | "B71")
          echo "Banda: $cur_band (1500 MHz)."
          ;;
        "B12" | "B13" | "B14" | "B17" | "B28" | "B29" | "B67" | "B68" | "B85")
          echo "Banda: $cur_band (700 MHz)."
          ;;
        "B15" | "B26" | "B30" | "B32" | "B66" | "B70" | "B74")
          echo "Banda: $cur_band (800 MHz)."
          ;;
        "B20")
          echo "Banda: $cur_band (800 MHz)."
          ;;
        "B22")
          echo "Banda: $cur_band (3500 MHz)."
          ;;
        "B23")
          echo "Banda: $cur_band (2000 MHz)."
          ;;
        "B24")
          echo "Banda: $cur_band (1600 MHz)."
          ;;
        "B25")
          echo "Banda: $cur_band (1900 MHz)."
          ;;
        "B31" | "B72" | "B73")
          echo "Banda: $cur_band (450 MHz)."
          ;;
        "B252" | "B255")
          echo "Banda: $cur_band (Suppl. DL)."
          ;;
        *)
          echo "Banda: $cur_band (Frequência desconhecida)."
          ;;
      esac
    fi
  else
    echo "Banda não disponível!"
  fi
}

print_umts_band_info() {
  if [ -n "$cur_umts_band" ]; then
    case "$cur_umts_band" in
      "B1")
        echo "Banda UMTS: $cur_umts_band (2100 MHz)"
        ;;
      "B8")
        echo "Banda UMTS: $cur_umts_band (900 MHz)"
        ;;
      "B5")
        echo "Banda UMTS: $cur_umts_band (850 MHz)"
        ;;
      "B2")
        echo "Banda UMTS: $cur_umts_band (1900 MHz)"
        ;;
      "B4")
        echo "Banda UMTS: $cur_umts_band (1700 MHz)"
        ;;
      "B20")
        echo "Banda UMTS: $cur_umts_band (800 MHz)"
        ;;
      "B34")
        echo "Banda UMTS: $cur_umts_band (2100 MHz)"
        ;;
      *)
        echo "Banda UMTS: $cur_umts_band (Frequência desconhecida)"
        ;;
    esac
  else
    echo "Banda UMTS não disponível"
  fi
}

print_bars_info() {
  case "$bars" in
    ("") echo "Barras: Valor nulo." ;;
    (0) echo "Barras: Sem sinal." ;;
    (1) echo "Barras: $bars (sinal muito fraco)." ;;
    (2) echo "Barras: $bars (sinal fraco)." ;;
    (3) echo "Barras: $bars (sinal moderado)." ;;
    (4) echo "Barras: $bars (sinal bom)." ;;
    (5) echo "Barras: $bars (sinal excelente)." ;;
    (*) echo "Barras: Valor inválido." ;;
  esac
}

print_rsrp_info() {
  if [ -z "$rsrp" ]; then
    echo "RSRP: Valor nulo."
  elif [ "$rsrp" -ge -80 ]; then
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
  if [ -z "$rsrq" ]; then
    echo "RSRQ: Valor nulo."
  elif [ "$rsrq" -gt -10 ]; then
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
  if [ -z "$sinr" ]; then
    echo "SINR: Valor nulo."
  elif [ "$sinr" -ge 20 ]; then
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

  device_name=$(echo "$json" | jq -r '.general.deviceName' 2>/dev/null)
  curr_time=$(echo "$json" | jq -r '.general.currTime' 2>/dev/null)
  dev_temperature=$(echo "$json" | jq -r '.general.devTemperature' 2>/dev/null)
  ver_major=$(echo "$json" | jq -r '.general.verMajor' 2>/dev/null)

  pm_state=$(echo "$json" | jq -r '.power.PMState // null' 2>/dev/null)
  battery_temperature=$(echo "$json" | jq -r '.power.batteryTemperature' 2>/dev/null)
  battery_voltage=$(echo "$json" | jq -r '.power.batteryVoltage' 2>/dev/null)
  batt_charge_level=$(echo "$json" | jq -r '.power.battChargeLevel' 2>/dev/null)
  batt_charge_source=$(echo "$json" | jq -r '.power.battChargeSource // null' 2>/dev/null)
  battery_state=$(echo "$json" | jq -r '.power.batteryState // null' 2>/dev/null)

  connection_text=$(echo "$json" | jq -r '.wwan.connectionText' 2>/dev/null)
  connection_status=$(echo "$json" | jq -r '.wwan.connection' 2>/dev/null)
  current_ps_service_type=$(echo "$json" | jq -r '.wwan.currentPSserviceType' 2>/dev/null)
  cur_band=$(echo "$json" | jq -r '.wwanadv.curBand' 2>/dev/null)
  bars=$(echo "$json" | jq -r '.wwan.signalStrength.bars // null' 2>/dev/null)
  rsrp=$(echo "$json" | jq -r '.wwan.signalStrength.rsrp // null' 2>/dev/null)
  rssi=$(echo "$json" | jq -r '.wwan.signalStrength.rssi // null' 2>/dev/null)
  rsrq=$(echo "$json" | jq -r '.wwan.signalStrength.rsrq // null' 2>/dev/null)
  sinr=$(echo "$json" | jq -r '.wwan.signalStrength.sinr // null' 2>/dev/null)

  register_network_display=$(echo "$json" | jq -r '.wwan.registerNetworkDisplay // null' 2>/dev/null)
  cell_id=$(echo "$json" | jq -r '.wwanadv.cellId // null' 2>/dev/null)
  radio_quality=$(echo "$json" | jq -r '.wwanadv.radioQuality // null' 2>/dev/null)
  LAC=$(echo "$json" | jq -r '.wwanadv.LAC // null' 2>/dev/null)
  MCC=$(echo "$json" | jq -r '.wwanadv.MCC // null' 2>/dev/null)
  MNC=$(echo "$json" | jq -r '.wwanadv.MNC // null' 2>/dev/null)
  operadora=$(map_mnc_to_operadora "$MNC")

  cg=$(echo "$json" | jq -r '.wwan.IP // null' 2>/dev/null)
  sess_duration=$(echo "$json" | jq -r '.wwan.sessDuration' 2>/dev/null)
  sess_start_time=$(echo "$json" | jq -r '.wwan.sessStartTime' 2>/dev/null)
  data_transferred=$(echo "$json" | jq -r '.wwan.dataTransferred' 2>/dev/null)
  data_transferred_rx=$(echo "$json" | jq -r '.wwan.dataTransferredRx' 2>/dev/null)
  data_transferred_tx=$(echo "$json" | jq -r '.wwan.dataTransferredTx' 2>/dev/null)

  # Atribuir valores padrão null caso ocorra erro na extração do JSON
  device_name=${device_name:-null}
  curr_time=${curr_time:-null}
  dev_temperature=${dev_temperature:-null}
  ver_major=${ver_major:-null}
  pm_state=${pm_state:-null}
  battery_temperature=${battery_temperature:-null}
  battery_voltage=${battery_voltage:-null}
  batt_charge_level=${batt_charge_level:-null}
  batt_charge_source=${batt_charge_source:-null}
  battery_state=${battery_state:-null}
  connection_text=${connection_text:-null}
  current_ps_service_type=${current_ps_service_type:-null}
  cur_band=${cur_band:-null}
  bars=${bars:-null}
  rsrp=${rsrp:-null}
  rssi=${rssi:-null}
  rsrq=${rsrq:-null}
  sinr=${sinr:-null}
  register_network_display=${register_network_display:-null}
  cell_id=${cell_id:-null}
  radio_quality=${radio_quality:-null}
  LAC=${LAC:-null}
  MCC=${MCC:-null}
  MNC=${MNC:-null}
  operadora=${operadora:-null}
  cg=${cg:-null}
  sess_duration=${sess_duration:-null}
  sess_start_time=${sess_start_time:-null}
  data_transferred=${data_transferred:-null}
  data_transferred_rx=${data_transferred_rx:-null}
  data_transferred_tx=${data_transferred_tx:-null}
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
      echo "N/A - $1"
      ;;
  esac
}

print_qualidade_sinal() {
  if [ -n "$rssi" ] && [ -n "$sinr" ] && [ -n "$rsrp" ] && [ -n "$rsrq" ]; then
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
  request_succeeded=$?

  # Debug: Exibe o valor de request_succeeded
  echo "request_succeeded value is: $request_succeeded" >&2

  # Se a solicitação foi bem-sucedida, mantém o intervalo original e processa os dados
  if [ $request_succeeded -eq 0 ]; then
    interval=5

    # Extrai as informações relevantes usando a função extract_info
    extract_info "$json"

    # Exibe as informações formatadas
    clear
    print_device_info
    print_battery_info
    print_operator_info

    # Se não estiver desconectado, exibe o status da conexão e a informação da conexão
    if [ "$connection_status" != "Disconnected" ]; then
      echo "Connection status: $connection_status"
      print_connection_info
    fi

    # Calcula e imprime as velocidades, se prev_data e prev_time estão definidos
    if [[ -n "$prev_data" && -n "$prev_time" && "$connection_status" != "Disconnected" ]]; then
      calculate_and_format_speeds "$curr_time" "$prev_time" "$json" "$prev_data"
      print_speed_info
    fi

    # Define prev_data e prev_time para a próxima iteração
    prev_data="$json"
    prev_time="$curr_time"

    # Verifica se o novo valor de $cg é diferente do valor anterior e atualiza o IP público, se necessário
    if [ "$cg" != "$prev_cg" ]; then
      echo "Consultando novo IP público." >&2
      public_ip=$(get_public_ip)
    fi

    # Atualiza o valor de prev_cg para a próxima iteração
    prev_cg="$cg"

  else
    # Se a solicitação falhou, redefine o intervalo para 1 segundos e exibe uma mensagem de erro
    interval=1
    clear
    echo "A solicitação falhou. Tentando novamente em 1 segundos..."
  fi

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
