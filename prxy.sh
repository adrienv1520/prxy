#!/bin/bash
#
#prxy: a proxy manager
#
#init
#set-port port_number
#set-host hostname
#set-username username
#set
#unset
#credentials | -c
#show
#aliases
#on aliasname | all
#off aliasname | all
#help
{

# main function to be called, all other internal functions are not intended to be sourced
function prxy() {
  ##
  ## INIT local variables and current directory
  ##

  #first of all get dir project of this script
  local current_dir

  if [[ -n $PRXY_DIR ]]; then
    current_dir="$PRXY_DIR"
  else
    if [[ -L "$0" ]]; then
      current_dir=$(readlink "$0")
    else
      current_dir=$(cd $(dirname "$0") && pwd)
    fi
  fi

  #constants to be used in this script
  declare -r CREDENTIALS_FILE="$current_dir/.credentials"
  declare -r ALIASES_FILE="$current_dir/.aliases"

  #declare host, port and username in this scope
  local host port username

  #declare aliases command to be used with proxy settings
  local apt wget curl

  ##
  ## INIT functions
  ##

  # prxy_echo() {
  #   command printf %s\\n "$*" 2>/dev/null || {
  #     prxy_echo() {
  #       \printf %s\\n "$*" # on zsh, `command printf` sometimes fails
  #     }
  #     prxy_echo "$@"
  #   }
  # }

  function has_command() {
    type "$1" > /dev/null 2>&1
  }

  #function write_credentials
  function write_credentials() {
    echo -e "host=$host\nport=$port\nusername=$username" > $CREDENTIALS_FILE
  }

  #function load_credentials
  function load_credentials() {
    if [[ -f $CREDENTIALS_FILE ]]; then
      while read line; do
        if [[ "$line" =~ ^host ]]; then
          host=$(echo $line | sed -E 's/host=//')
        elif [[ "$line" =~ ^port ]]; then
          port=$(echo $line | sed -E 's/port=//')
        elif [[ "$line" =~ ^username ]]; then
          username=$(echo $line | sed -E 's/username=//')
        fi
      done < $CREDENTIALS_FILE
    else
      write_credentials
    fi
  }

  #function read_credential (host, port or username)
  function read_credential() {
    local is_correct=false
    local credential
    local prompt="$1: "

    if [[ "$1" == "port" ]]; then
      prompt="$1 (must be a number): "
    fi

    while [[ $is_correct == false ]]; do
      read -p "$prompt" credential

      if [[ -n $credential ]]; then
        if [[ "$1" != "port" ]]; then
          is_correct=true
        elif let $credential; then
          is_correct=true
        fi
      fi
    done

    echo $credential
  }

  #function show_proxy
  function show_credentials() {
    cat $CREDENTIALS_FILE
  }

  function read_proxy_password() {
    read -p "Proxy password :" -s proxy_password
    echo $proxy_password
  }

  #function setproxy
  function set_proxy() {
    password=$(read_proxy_password) && echo

    if [[ -n $password ]] && [[ -n $host ]] && [[ -n $port ]] && [[ -n $username ]]; then
      export {http,https,ftp}_proxy="http://$username:$password@$host:$port"
      export {HTTP,HTTPS,FTP}_PROXY="http://$username:$password@$host:$port"
      return 0
    else
      echo -e "\n\033[0;31mNo proxy environment variables exported: one or more credentials are empty."
      echo -e "\033[00mhost:$host\nport:$port\nusername:$username\npass:${#password} characters"
      return 1
    fi
  }

  #function unset_proxy
  function unset_proxy() {
    unset {http,https,ftp}_proxy
    unset {HTTP,HTTPS,FTP}_PROXY
  }

  #function show_proxy
  function show_proxy() {
    declare -r show_proxy_env="env | grep -E '^(http|https|ftp|HTTP|HTTPS|FTP)_(proxy|PROXY)'"
    echo -e "Proxy environment variables:\n$(eval $show_proxy_env)"
  }

  #function prxy_aptget
  function prxy_aptget() {
    set_proxy && sudo apt-get "$@" && unset_proxy
  }

  #function prxy_wget
  function prxy_wget() {
    set_proxy && wget "$@" && unset_proxy
  }

  #function prxy_curl
  function prxy_curl() {
    password=$(read_proxy_password) && echo
    curl -U "$username:$password" -x "http://$host:$port" "$@"
  }

  #function set_alias
  function set_alias() {
    #TODO try this: alias "$1"="prxy_$1" instead of case block
    case $1 in
      "apt-get")
        alias 'apt-get'='prxy_aptget'
        ;;
      "wget")
        alias 'wget'='prxy_wget'
        ;;
      "curl")
        alias 'curl'='prxy_curl'
        ;;
    esac
  }

  # function unset_alias
  function unset_alias() {
    unalias "$1" 2>/dev/null
  }

  #function write_aliases
  function write_aliases() {
    echo -e "apt=$apt\nwget=$wget\ncurl=$curl" > $ALIASES_FILE
  }

  #function load_aliases
  function load_aliases() {
    #first load in local vars
    if [[ -f $ALIASES_FILE ]]; then
      while read line; do
        if [[ "$line" =~ ^apt ]]; then
          apt=$(echo $line | sed -E 's/apt=//')
        elif [[ "$line" =~ ^wget ]]; then
          wget=$(echo $line | sed -E 's/wget=//')
        elif [[ "$line" =~ ^curl ]]; then
          curl=$(echo $line | sed -E 's/curl=//')
        fi
      done < $ALIASES_FILE
    else
      write_aliases
    fi

    #now export aliases that are set to 'on'
    if [[ $apt == "on" ]]; then
      set_alias "apt"
    fi

    if [[ $wget == "on" ]]; then
      set_alias "wget"
    fi

    if [[ $curl == "on" ]]; then
      set_alias "curl"
    fi
  }

  #function show_aliases
  function show_aliases() {
    cat $ALIASES_FILE
  }

  ##
  ##START
  ##

  #load aliases to local vars and current shell if they're set to 'on'
  load_aliases

  #apply action command contains in $1
  case $1 in
    "init")
      host=$(read_credential "host")
      port=$(read_credential "port")
      username=$(read_credential "username")
      write_credentials
      ;;
    "set-host")
      load_credentials
      host=$(read_credential "host")
      write_credentials
      ;;
    "set-port")
      load_credentials
      port=$(read_credential "port")
      write_credentials
      ;;
    "set-username")
      load_credentials
      username=$(read_credential "username")
      write_credentials
      ;;
    "set")
      load_credentials
      set_proxy
      ;;
    "unset")
      unset_proxy
      ;;
    "credentials" | "-c")
      show_credentials
      ;;
    "show")
      show_proxy
      ;;
    "aliases")
      show_aliases
      ;;
    "on")
      case $2 in
        "apt")
          if [[ $apt != "on" ]]; then
            apt="on"
            set_alias "apt-get"
            write_aliases
          fi
          ;;
        "wget")
          if [[ $apt != "on" ]]; then
            wget="on"
            set_alias "wget"
            write_aliases
          fi
          ;;
        "curl")
          if [[ $apt != "on" ]]; then
            curl="on"
            set_alias "curl"
            write_aliases
          fi
          ;;
        "all" | *)
          if [[ $apt != "on" ]] || [[ $wget != "on" ]] || [[ $curl != "on" ]]; then
            apt="on"
            wget="on"
            curl="on"
            set_alias "apt"
            set_alias "wget"
            set_alias "curl"
            write_aliases
          fi
          ;;
      esac
      ;;
    "off")
      case $2 in
        "apt")
          if [[ $apt != "off" ]]; then
            apt="off"
            unset_alias "apt-get"
            write_aliases
          fi
          ;;
        "wget")
          if [[ $wget != "off" ]]; then
            wget="off"
            unset_alias "wget"
            write_aliases
          fi
          ;;
        "curl")
          if [[ $curl != "off" ]]; then
            curl="off"
            unset_alias "curl"
            write_aliases
          fi
          ;;
        "all" | *)
          if [[ $apt != "off" ]] || [[ $wget != "off" ]] || [[ $curl != "off" ]]; then
            apt="off"
            wget="off"
            curl="off"
            unset_alias "apt"
            unset_alias "wget"
            unset_alias "curl"
            write_aliases
          fi
          ;;
        esac
      ;;
    "help" | *)
      echo -e "#prxy: a proxy manager\n"
      echo -e "##Init host, port and username to use for proxy:\n$ prxy init\n"
      echo -e "##Set/update host to use:\n$ prxy set-host hostname\n"
      echo -e "##Set/update port to use:\n$ prxy set-port port_number\n"
      echo -e "##Set/update username to use:\n$ prxy set-username username\n"
      echo -e "##Export proxy environment variables to the current shell:\n$ prxy set\n"
      echo -e "##Unset proxy environment variables to the current shell:\n$ prxy unset\n"
      echo -e "##Show credentials used for proxy:\n$ prxy credentials | -c\n"
      echo -e "##Show proxy environment variables:\n$ prxy show\n"
      echo -e "##Show aliases configuration:\n$ prxy aliases\n"
      echo -e "##Activate a proxy alias (eg. apt-get). By default all aliases are activated:\n$ prxy on aliasname | all\n"
      echo -e "##Deactivate a proxy alias (eg. apt-get). Let you manually set and unset proxy environment variables when running a specific command that needs proxy credentials and vars:\n$ prxy off aliasname | all\n"
      echo -e "##Help:\n$ prxy help | ''"
      ;;
  esac

  #sed -iE 's/\(username=\).*/\1adrien/' .credentials
}

}
