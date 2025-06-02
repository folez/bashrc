# Source global definitions
if [ -f /etc/zshrc ]; then
	. /etc/zshrc
fi

# ========================= COLORS ========================= #

RED='\033[31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No color
# export PATH="$PATH:`pwd`/development/flutter/bin"

# ========================= HELPERS ========================= #
alias pint='./vendor/bin/pint'
alias phpunit='./vendor/bin/phpunit'

alias a='php artisan'
alias cl='truncate -s 0 ./storage/logs/**/**.log && truncate -s 0 ./storage/logs/*.log'
alias cc='php artisan optimize:clear && php artisan route:clear && php artisan config:cache && php artisan cache:clear && php artisan view:clear'
alias c='clear'


out() {
    printf "${!2}${1}${NC}";
}

permissions() {
	sudo chmod -R 644 $1
	sudo chown $(id -u):$(id -g) $1
}

folder() {
	sudo chmod -R 755 $1
}

# ========================= PHPSTORM ========================= #

alias p="phpstorm"

# ========================= PHPUNIT ========================= #

alias pu="cls && phpunit"
alias pf="cls && phpunit --filter"

# ========================= DOCKER ========================= #

alias d="docker"
alias dc="docker compose"
alias dcu="docker compose up"
alias dcub="docker compose up --build"
alias dps="docker ps"
alias ds="docker stop $(docker ps -qa)"

dbash() {
    printf "\nThrowing " YELLOW
    printf "[.bashrc]"
    printf " into each and every container...\n" YELLOW

    containers="$(docker ps -q -f name=php | tr '\n' ' ')"
    for container in $containers
    do
        printf "$container" RED
        docker cp ~/.bashrc_docker $container:/root/.bashrc
        printf "\r$container"
        printf " Done!\n" GREEN
    done
}

dx() {
	cls
    print "Filtering:"

	if [[ $1 == 'all' ]] ; then
	    printf "all\n ${GREEN}"
        getContainer
    elif [[ $1 == '' ]]; then
        printf "php-fpm\n ${GREEN}"
        getContainer name=php-fpm
        d cp ~/.bashrc_docker_container $container:~/.bashrc
    else
        printf "$1\n" GREEN
    fi

    cls
	d exec -it $container bash
}

dxa() {
    cls
    printf "Filtering: "
    printf "all\n" GREEN
    getContainer
    cls
    d exec -it $container bash
}

containerExists() {
    if [[ $(docker ps -a -q --filter "id=$1") == $1* ]] ; then
        return 0
    else
        return 1
    fi
}
getContainer() {
    gc_errors=0

    if [[ $1 != '' ]] ; then
        dps --filter $1
    else
        dps
    fi

    while true
    do
        printf "\nChoose a container: " YELLOW
        read -r container
        containerExists $container

        if [[ $? -eq 0 ]] ; then
            if [[ gc_errors -gt 0 ]] ; then
                printf "Finally, you got the right one :) " GREEN
            else
                printf "Success! " GREEN
            fi
            printf "Chosen [$container] container.\n" GREEN
            break
        fi

        printf "Container [$container] doesn't exist!\n" RED
        printf "Please try again and be attentive.\n"
        (( gc_errors += 1 ))
    done
}

extract() {
    e_errors=0

    cls
    getContainer
    printf "\n"

    from=$1
    to=$2

    while true
    do
        # paths are not present and no errors
        if [[ (( -z ${!1+x} || -z ${!2+x} )) && e_errors -eq 0 ]] ; then
            # if "FROM" is absent
            if [[ (( -z ${!1+x} ))  ]] ; then
                printf "Take from the container ${NC}[/src/vendor]${YELLOW}: " YELLOW
                read -r from
            fi

            # if "TO" is absent
            if [[ (( -z ${!2+x} )) ]] ; then
                printf "Where to put: " YELLOW
                read -r to
            fi
            printf "\n"
        fi

        # is there the given path inside of the container?
        if docker exec $container test -d "$from" ; then
            printf "Extracting [$from]...\n" YELLOW
            break
        fi

        printf "Nothing found at [$from] inside of [$container].\n" RED
        printf "Please enter other path: " YELLOW
        read -r from
        printf "\n"
        (( e_errors += 1 ))
    done

    d cp $container:$from $to
    printf "Extracted!\n" GREEN
}
vendor() {
    cls
    printf "Filtering: "
    printf "php-fpm\n" GREEN
  	getContainer name=php-fpm
  	printf "Extracting vendor...\n" YELLOW
  	d cp $container:./src/vendor ./
  	printf "Extracted!\n" GREEN
}
node_modules() {
    cls
    printf "Filtering: "
    printf "node_modules\n" GREEN
  	getContainer name=client
  	printf "Extracting node_modules...\n" YELLOW
  	d cp $container:./src/node_modules ./
  	printf "Extracted!\n" GREEN
}

tail () {
    cls
    printf "Filtering: "
    printf "$1" GREEN
    if [[ $1 == '' ]]; then
        printf "all" GREEN
    fi
    printf "\n"
    getContainer "name=$1"
    docker logs -f --tail 100 "$container"
}
