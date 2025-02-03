#!/usr/bin/env bash

set -eu

# Paths to output files
ENV_FILE_PATH="./.env"
API_ENV_FILE_PATH="./api/docker/api.env"
DB_ENV_FILE_PATH="./db/docker/db.env"
WEB_ENV_FILE_PATH="./web/docker/web.env"

# Via these arrays, the order of iteration of the associative array is guaranteed
paths=(
  $ENV_FILE_PATH
  $API_ENV_FILE_PATH
  $DB_ENV_FILE_PATH
  $WEB_ENV_FILE_PATH
)
keys=(
  # common
  PROJECT_NAME
  USER_ID GROUP_ID USER_NAME GROUP_NAME
  # api
  RUBY_VER RAILS_VER API_PORT BUNDLE_PATH BUNDLE_BIN
  # db
  POSTGRES_HOST POSTGRES_PORT POSTGRES_USER POSTGRES_PASSWORD
  # web
  WEB_USER_NAME NODE_VER NPM_VER YARN_VER WEB_PORT VITE_API_SERVER
)

# Default values
script_dir=$(cd $(dirname $0); pwd)
script_dir_name=$(basename $script_dir)
API_PORT=8080
declare -A defaults=(
  # common
  [PROJECT_NAME]=$script_dir_name
  [USER_ID]=$(id -u)
  [GROUP_ID]=$(id -g)
  [USER_NAME]=$(id -un)
  [GROUP_NAME]=$(id -gn)
  # api
  [RUBY_VER]=3.3.5
  [RAILS_VER]=7.2.2
  [API_PORT]=$API_PORT
  [BUNDLE_PATH]=/usr/local/bundle
  [BUNDLE_BIN]=/usr/local/bundle/bin
  # db
  [POSTGRES_HOST]=db
  [POSTGRES_PORT]=5432
  [POSTGRES_USER]=myuser
  [POSTGRES_PASSWORD]=mypassword
  # web
  [WEB_USER_NAME]=node
  [NODE_VER]=22.11.0
  [NPM_VER]=10.9.0
  [YARN_VER]=1.22.22
  [WEB_PORT]=5173
  [VITE_API_SERVER]=http://localhost:${API_PORT}/api/v1
)
# pronmpts
declare -A prompts=(
  # common
  [PROJECT_NAME]="Enter your PROJECT_NAME"
  [USER_ID]="Enter your USER_ID"
  [GROUP_ID]="Enter your GROUP_ID"
  [USER_NAME]="Enter your USER_NAME"
  [GROUP_NAME]="Enter your GROUP_NAME"
  # api
  [RUBY_VER]="Enter RUBY_VER"
  [RAILS_VER]="Enter RAILS_VER"
  [API_PORT]="Enter API_PORT"
  [BUNDLE_PATH]="Enter BUNDLE_PATH"
  [BUNDLE_BIN]="Enter BUNDLE_BIN"
  # db
  [POSTGRES_HOST]="Enter Postgres host"
  [POSTGRES_PORT]="Enter POSTGRES_PORT"
  [POSTGRES_USER]="Enter Postgres user"
  [POSTGRES_PASSWORD]="Enter Postgres password"
  # web
  [WEB_USER_NAME]="Enter WEB_USER_NAME"
  [NODE_VER]="Enter NODE_VER"
  [NPM_VER]="Enter NPM_VER"
  [YARN_VER]="Enter YARN_VER"
  [WEB_PORT]="Enter WEB_PORT"
  [VITE_API_SERVER]="Enter VITE_API_SERVER"
)

# Writer functions
# Write the .env file
write_env_file() {
  cat <<EOF > $ENV_FILE_PATH
# common
PROJECT_NAME=$PROJECT_NAME
USER_ID=$USER_ID
GROUP_ID=$GROUP_ID
USER_NAME=$USER_NAME
GROUP_NAME=$GROUP_NAME
# api
RUBY_VER=$RUBY_VER
RAILS_VER=$RAILS_VER
API_PORT=$API_PORT
BUNDLE_PATH=$BUNDLE_PATH
BUNDLE_BIN=$BUNDLE_BIN
# db
# web
WEB_USER_NAME=$WEB_USER_NAME
NODE_VER=$NODE_VER
NPM_VER=$NPM_VER
YARN_VER=$YARN_VER
WEB_PORT=$WEB_PORT
EOF
}
# Write the api.env file
write_api_env_file() {
  cat <<EOF > $API_ENV_FILE_PATH
POSTGRES_HOST=$POSTGRES_HOST
POSTGRES_PORT=$POSTGRES_PORT
POSTGRES_USER=$POSTGRES_USER
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
EOF
}
# Write the db.env file
write_db_env_file() {
  cat <<EOF > $DB_ENV_FILE_PATH
POSTGRES_USER=$POSTGRES_USER
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
EOF
}
# Write the web.env file
write_web_env_file() {
  cat <<EOF > $WEB_ENV_FILE_PATH
VITE_API_SERVER=$VITE_API_SERVER
CHOKIDAR_USEPOLLING=true
EOF
}

# Function that call the proper writer according to the target
write_file() {
  local target=$1
  case $target in
    $ENV_FILE_PATH)     write_env_file ;;
    $API_ENV_FILE_PATH) write_api_env_file ;;
    $DB_ENV_FILE_PATH)  write_db_env_file ;;
    $WEB_ENV_FILE_PATH) write_web_env_file ;;
    *)                  echo "An unexpected error occurred." && exit 1 ;;
  esac
}

# Function that print the preview of the file
print_preview() {
  local path=$1
  cat -n $path
  printf "%s\n\n\n" "------------------------------------------------------------------------------"
}

# Function that gets user input
get_user_input() {
  # number of keys
  len=${#keys[@]}
  # initailze index
  i=0
  for key in "${keys[@]}"; do
    read -p "[$((len - i))] ${prompts[$key]}: " -ei "${defaults[$key]}" input
    declare -g "$key=$input"
    i=$((i+1)) # increment with arithmetic expansion（算術式展開）
  done
  printf "\n\n\n"
}

# main function
main() {
  get_user_input
  for path in "${paths[@]}"; do
    if [ -e $path ]; then
      echo "[!] \"$path\" already exists. Do you want to overwrite it? (yes/no)"
      read answer
      if [[ "$answer" =~ ^(Y|y|YES|yes|Yes|YEs|YeS|yEs|yeS)$ ]]; then
        write_file $path
        printf "\n>> Overwrote the file: \"$path\"\n"
        print_preview $path
      else
        echo ">> Canceled. Keeping the existing *.env file."
        print_preview $path
      fi
    else
      echo "$path does not exist."
      write_file $path
      printf "\n>> Created a file: \"$path\"\n"
      print_preview $path
    fi
  done
}

# Main process
arg=${1:-}  # $1が未定義の場合、argに空文字列を設定
if [ "$arg" == "--help" ] || [ "$arg" == "-h" ]; then
  echo "Now preparing..."
else
  echo "You can use the following command to check how each environment variable is used."
  printf "1. \`./generate-env.sh --help[-h]\`\n"
  printf "2. \`g-env --help[-h]\` (if activated aliases)\n\n"
  main
fi