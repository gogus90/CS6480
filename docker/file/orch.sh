#! /bin/bash

# -h Help
# TODO write up help section
# -s Set up containers

init() {
    # TODO pull cs6480 repo from git
    echo git clone https://github.com/gogus90/CS6480
    # TODO run Dockerfile and name it lab1:0.2
    echo cd CS6480/docker/file
    echo sudo docker build . -t lab1:0.2
    # TODO run docker compose
    echo sudo docker compose up -d
}

# -1 Phase 1: 3 router topology
config() {
    # TODO start up hostA, hostB, router1, router2, router3
    case ${2,,} in
        all)
            for c in hostA hostB router1 router2 router3
                do
                    # TODO for each router, make conf files:
                    #   babeld.conf  bgpd.conf  isis.conf  ospf6d.conf  ripd.conf  ripngd.conf -- empty
                    echo sudo docker exec -it $c touch /etc/quagga/babeld.conf /etc/quagga/bgpd.conf /etc/quagga/isis.conf /etc/quagga/ospf6d.conf /etc/quagga/ripd.conf /etc/quagga/ripngd.conf
                done
            #   daemons  ospfd.conf  vtysh.conf  zebra.conf -- not empty
            #       └ everything should be identical, except for ospf weight for router2: router2 weight 5, router1/3 weight 10
            echo cat << EOF > daemons
            
            # TODO service zebra start, service ospfd start

            ;;
        r4 | router4)
            ;;
        *)
            echo choose between "all" and "r4."
            ;;
    esac
}
# -p [hostA | hostB] ping specified host
# TODO docker exec -it [otherhost] ping [hostIP],  hostA: 10.0.11.2 hostB: 10.0.13.2
# -t [router1 | router2 | router3 | router4] run tcpdump on specified router
# TODO docker exec -it [router] tcpdump
# -2 Phase 2: add router4 and change ospf weight
# TODO start up router4
# TODO make conf files:
#   babeld.conf  bgpd.conf  isis.conf  ospf6d.conf  ripd.conf  ripngd.conf -- empty
#   daemons  ospfd.conf  vtysh.conf  zebra.conf -- not empty
#       └ router4 weight 10
# TODO service zebra start, service ospfd start
# TODO change ospf weight on router2 and router4: router2 weight 5, router4 weight 10
# -3 Phase 3: remove router2
# TODO use docker to turn off router2