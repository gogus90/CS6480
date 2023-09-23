#! /bin/bash

# -h Help
# TODO write up help section
# -s Set up containers

init() {
    # TODO pull cs6480 repo from git
    git clone https://github.com/gogus90/CS6480
    # TODO run Dockerfile and name it lab1:0.2
    cd CS6480/docker/file
    sudo docker build . -t lab1:0.2
    # TODO run docker compose
    sudo docker compose up -d
}

empty_files() {
    sudo docker exec -w /etc/quagga -it $1 touch babeld.conf bgpd.conf isis.conf ospf6d.conf ripd.conf ripngd.conf
    sudo docker exec -it $1 touch /var/log/ospfd.log
    sudo docker exec -it $1 chown quagga:quagga /var/log/ospfd.log
}

identical_files() {
    sudo docker exec -w /etc/quagga -it $1 sh -c "cat >daemon <<EOF
zebra=yes
bgpd=no
ospfd=yes
ospf6d=no
ripd=no
ripngd=no
isisd=no
babeld=no
EOF"

    sudo docker exec -w /etc/quagga -it $1 sh -c "cat >vtysh.conf <<EOF
hostname $1
username root nopassword
EOF"
}

conf_r1() {
    sudo docker exec -w /etc/quagga -it router1 sh -c "cat >ospfd.conf <<EOF
hostname ospfd
password zebra
log file /var/log/ospfd.log
interface eth0
  ip ospf cost 10
interface eth1
  ip ospf cost 10
interface eth2
  ip ospf cost 10
interface lo
router ospf
  ospf router-id 1.1.1.1
  network 10.0.11.0/24 area 0.0.0.0
  network 10.0.12.0/26 area 0.0.0.0
  network 10.0.12.192/26 area 0.0.0.0
  line vty
EOF"

    sudo docker exec -w /etc/quagga -it router1 sh -c "cat >zebra.conf <<EOF
hostname Router1
password zebra
interface eth0
  ip address 10.0.11.1/24
interface eth1
  ip address 10.0.12.195/26
interface eth2
  ip address 10.0.12.3/26
interface lo
  ip address 127.0.0.1/8
line vty
EOF"
}

conf_r2() {
    sudo docker exec -w /etc/quagga -it router2 sh -c "cat >ospfd.conf <<EOF
hostname ospfd
password zebra
log file /var/log/ospfd.log
interface eth0
  ip ospf cost 5
interface eth1
  ip ospf cost 5
router ospf
  ospf router-id 2.2.2.2
  network 10.0.12.0/26 area 0.0.0.0
  network 10.0.12.64/26 area 0.0.0.0
  line vty
EOF"

    sudo docker exec -w /etc/quagga -it router2 sh -c "cat >zebra.conf <<EOF
hostname Router2
password zebra
enable password zebra
interface eth0
  ip address 10.0.12.2/26
interface eth1
  ip address 10.0.12.66/26
line vty
EOF"
}

conf_r3() {
    sudo docker exec -w /etc/quagga -it router3 sh -c "cat >ospfd.conf <<EOF
hostname ospfd
password zebra
log file /var/log/ospfd.log
interface eth0
  ip ospf cost 10
interface eth1
  ip ospf cost 10
interface eth2
  ip ospf cost 10
router ospf
  ospf router-id 3.3.3.3
  network 10.0.12.64/26 area 0.0.0.0
  network 10.0.12.128/26 area 0.0.0.0
  network 10.0.13.0/24 area 0.0.0.0
  line vty
EOF"

    sudo docker exec -w /etc/quagga -it router3 sh -c "cat >zebra.conf <<EOF
hostname Router3
password zebra
enable password zebra
interface eth0
  ip address 10.0.12.67/26
interface eth1
  ip address 10.0.12.131/26
interface eth2
  ip address 10.0.13.1/24
line vty
EOF"
}

conf_r4() {
    sudo docker exec -w /etc/quagga -it router4 sh -c "cat >ospfd.conf <<EOF
hostname ospfd
password zebra
log file /var/log/ospfd.log
interface eth0
  ip ospf cost 10
interface eth1
  ip ospf cost 10
router ospf
  ospf router-id 4.4.4.4
  network 10.0.12.192/26 area 0.0.0.0
  network 10.0.12.128/26 area 0.0.0.0
  line vty
EOF"

    sudo docker exec -w /etc/quagga -it router4 sh -c "cat >zebra.conf <<EOF
hostname Router4
password zebra
enable password zebra
interface eth0
  ip address 10.0.12.194/26
interface eth1
  ip address 10.0.12.130/26
line vty
EOF"
}

start_service(){
    sudo docker exec -it $1 service zebra start
    sudo docker exec -it $1 service ospfd start
}

add_routes(){    
    # add routes
    sudo docker exec -it hostA route add -net 10.0.13.0/24 gw 10.0.11.3
    sudo docker exec -it hostB route add -net 10.0.11.0/24 gw 10.0.13.3
}

# -1 Phase 1: 3 router topology
config() {
    # TODO start up hostA, hostB, router1, router2, router3
    case $1 in
        all)
            # TODO for each router, make conf files:
            #   babeld.conf  bgpd.conf  isis.conf  ospf6d.conf  ripd.conf  ripngd.conf -- empty
            empty_files router1
            empty_files router2
            empty_files router3            
            #   daemons  vtysh.conf  ospfd.conf  zebra.conf -- not empty
            identical_files router1
            identical_files router2
            identical_files router3
            conf_r1
            conf_r2
            conf_r3
            # TODO service zebra start, service ospfd start
            start_service router1
            start_service router2
            start_service router3
            add_routes
            ;;
    # -2 Phase 2: add router4 and change ospf weight
    # TODO start up router4
    # TODO make conf files:
    #   babeld.conf  bgpd.conf  isis.conf  ospf6d.conf  ripd.conf  ripngd.conf -- empty
    #   daemons  ospfd.conf  vtysh.conf  zebra.conf -- not empty
    #       └ router4 weight 10
    # TODO service zebra start, service ospfd start
        r4 | router4)
            empty_files router4  
            identical_files router4
            conf_r4
            start_service router4
            ;;
        *)
            echo choose between "all" and "r4."
            ;;
    esac
}

# -p [hostA | hostB] ping specified host
# TODO docker exec -it [otherhost] ping [hostIP],  hostA: 10.0.11.2 hostB: 10.0.13.2
ping() {
    case $1 in
        hostA)
            sudo docker exec -it hostB ping 10.0.11.2
            ;;
        hostB)
            sudo docker exec -it hostA ping 10.0.13.2
            ;;
        *)
            echo choose between "hostA" and "hostB."
            ;;
    esac
}
# -t [router1 | router2 | router3 | router4] run tcpdump on specified router
# TODO docker exec -it [router] tcpdump
tcpdump() {
    case $1 in
        router2 | r2)
            sudo docker exec -it router2 tcpdump
            ;;
        router4 | r4)
            sudo docker exec -it router4 tcpdump
            ;;
        *)
            echo choose between "router2" and "router4."
            ;;
    esac
}

# TODO change ospf weight on router2 and router4: router2 weight 5, router4 weight 10
change_path(){
    case $1 in
        north)
            sudo docker exec -it router2 sh -c "(echo conf t; echo int eth0; echo ospf cost 5; echo int eth1; echo ospf cost 5; echo end; echo exit) | vtysh"
            sudo docker exec -it router4 sh -c "(echo conf t; echo int eth0; echo ospf cost 10; echo int eth1; echo ospf cost 10; echo end; echo exit) | vtysh"
            ;;
        south)
            sudo docker exec -it router4 sh -c "(echo conf t; echo int eth0; echo ospf cost 5; echo int eth1; echo ospf cost 5; echo end; echo exit) | vtysh"
            sudo docker exec -it router2 sh -c "(echo conf t; echo int eth0; echo ospf cost 10; echo int eth1; echo ospf cost 10; echo end; echo exit) | vtysh"
            ;;
    esac
}

# -3 Phase 3: remove router2
# TODO use docker to turn off router2
remove_container() {
    sudo docker stop $1
}

main() {
    case $1 in
        -i | --init)
        init
        ;;
        -c | --config)
        config $2
        ;;
        -p | --ping)
        ping $2
        ;;
        -t | --tcpdump)
        tcpdump $2
        ;;
        -o | --ospf)
        change_path $2
        ;;
        -r | --remove)
        remove_container $2
        ;;
        *)        
        # Display Help
        echo
        echo "Orchestrator script for CS6480 lab 1. Creates containers and sets up OSPF in a 4"
        echo "router topology."
        echo
        echo "      Topology:"
        echo "                                  -  router2 -                                  "
        echo "            hostA  --  router1  <              >  router3  --  hostB            "
        echo "                                  -  router4 -                                  "
        echo 
        echo "Syntax: ./orch [-h --help|-i --init|-c --config|-p --ping|-t --tcpdump|-o --ospf"
        echo "               |-r --remove] [container]"
        echo "options:"
        echo "[-h | --help]                       Prints help page."
        echo "[-i | --init]                       Builds and composes docker containers.      "
        echo "[-c | --config] [all|router4]       Configures the containers for networking.   "
        echo "[-p | --ping] [hostA|B]             Pings to specified host. Ping hostA to ping "
        echo "                                    from hostB to A."
        echo "[-t | --tcpdump] [router1|2|3|4]    Runs tcpdump on specified router."
        echo "[-o | --ospf] [north|south]         Sets up ospf cost to move packets in the    "
        echo "                                    north(r2) or south(r4) path."
        echo "[-r | --remove] [container name]    Stops the container from running, thus      "
        echo "                                    removing it from the network.               "
        echo
    esac
}

main $1 $2