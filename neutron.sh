#!/usr/bin/env bash

# --------------------------------------------------------------------------------------
# install neutron
# --------------------------------------------------------------------------------------
function allinone_neutron_setup() {
    # install packages
    install_package neutron-server neutron-plugin-openvswitch neutron-plugin-openvswitch-agent dnsmasq neutron-dhcp-agent neutron-l3-agent neutron-lbaas-agent

    # create database for neutron
    mysql -u root -p${MYSQL_PASS} -e "CREATE DATABASE neutron;"
    mysql -u root -p${MYSQL_PASS} -e "GRANT ALL ON neutron.* TO '${DB_QUANTUM_USER}'@'%' IDENTIFIED BY '${DB_QUANTUM_PASS}';"

    # set configuration files
    setconf infile:$BASE_DIR/conf/etc.neutron/metadata_agent.ini \
        outfile:/etc/neutron/metadata_agent.ini \
        "<CONTROLLER_IP>:127.0.0.1" "<KEYSTONE_IP>:${KEYSTONE_IP}" \
        "<SERVICE_TENANT_NAME>:${SERVICE_TENANT_NAME}" \
        "<SERVICE_PASSWORD>:${SERVICE_PASSWORD}"
    setconf infile:$BASE_DIR/conf/etc.neutron/api-paste.ini \
        outfile:/etc/neutron/api-paste.ini \
        "<KEYSTONE_IP>:${KEYSTONE_IP}" \
        "<SERVICE_TENANT_NAME>:${SERVICE_TENANT_NAME}" \
        "<SERVICE_PASSWORD>:${SERVICE_PASSWORD}"
    setconf infile:$BASE_DIR/conf/etc.neutron/l3_agent.ini \
        outfile:/etc/neutron/l3_agent.ini \
        "<KEYSTONE_IP>:${KEYSTONE_IP}" \
        "<CONTROLLER_NODE_PUB_IP>:${CONTROLLER_NODE_PUB_IP}" \
        "<SERVICE_TENANT_NAME>:${SERVICE_TENANT_NAME}" \
        "<SERVICE_PASSWORD>:${SERVICE_PASSWORD}"

    if [[ "${NETWORK_TYPE}" = 'gre' ]]; then
        setconf infile:$BASE_DIR/conf/etc.neutron.plugins.openvswitch/ovs_neutron_plugin.ini.gre \
            outfile:/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini \
            "<DB_IP>:${DB_IP}" "<QUANTUM_IP>:${QUANUTM_IP}"
    elif [[ "${NETWORK_TYPE}" = 'vlan' ]]; then
        setconf infile:$BASE_DIR/conf/etc.neutron.plugins.openvswitch/ovs_neutron_plugin.ini.vlan \
            outfile:/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini \
            "<DB_IP>:${DB_IP}"
    else
        echo "NETWORK_TYPE must be 'vlan' or 'gre'."
        exit 1
    fi
        
    # see BUG https://lists.launchpad.net/openstack/msg23198.html
    # this treat includes secirity problem, but unfortunatly it is needed for neutron now.
    # when you noticed that it is not needed, please comment out these 2 lines.
    cp $BASE_DIR/conf/etc.sudoers.d/neutron_sudoers /etc/sudoers.d/neutron_sudoers
    chmod 440 /etc/sudoers.d/neutron_sudoers

    # restart processes
    restart_service neutron-server
    restart_service neutron-plugin-openvswitch-agent
    restart_service neutron-dhcp-agent
    restart_service neutron-l3-agent
}

# --------------------------------------------------------------------------------------
# install neutron for controller node
# --------------------------------------------------------------------------------------
function controller_neutron_setup() {
    # install packages
    install_package neutron-server neutron-plugin-openvswitch
    # create database for neutron
    mysql -u root -p${MYSQL_PASS} -e "CREATE DATABASE neutron;"
    mysql -u root -p${MYSQL_PASS} -e "GRANT ALL ON neutron.* TO '${DB_QUANTUM_USER}'@'%' IDENTIFIED BY '${DB_QUANTUM_PASS}';"

    # set configuration files
    if [[ "${NETWORK_TYPE}" = 'gre' ]]; then
        setconf infile:$BASE_DIR/conf/etc.neutron.plugins.openvswitch/ovs_neutron_plugin.ini.gre.controller \
            outfile:/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini \
            "<DB_IP>:${DB_IP}"
    elif [[ "${NETWORK_TYPE}" = 'vlan' ]]; then
        setconf infile:$BASE_DIR/conf/etc.neutron.plugins.openvswitch/ovs_neutron_plugin.ini.vlan \
            outfile:/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini \
            "<DB_IP>:${DB_IP}"
    else
        echo "NETWORK_TYPE must be 'vlan' or 'gre'."
        exit 1
    fi
    
    setconf infile:$BASE_DIR/conf/etc.neutron/api-paste.ini \
        outfile:/etc/neutron/api-paste.ini \
        "<KEYSTONE_IP>:${KEYSTONE_IP}" \
        "<SERVICE_TENANT_NAME>:${SERVICE_TENANT_NAME}" \
        "<SERVICE_PASSWORD>:${SERVICE_PASSWORD}"
    setconf infile:$BASE_DIR/conf/etc.neutron/neutron.conf \
        outfile:/etc/neutron/neutron.conf \
        "<CONTROLLER_IP>:localhost"
    
    # restart process
    restart_service neutron-server
}

# --------------------------------------------------------------------------------------
# install neutron for network node
# --------------------------------------------------------------------------------------
function network_neutron_setup() {
    # install packages
    install_package mysql-client
    install_package neutron-plugin-openvswitch-agent neutron-dhcp-agent neutron-l3-agent neutron-metadata-agent neutron-lbaas-agent

    # set configuration files
    setconf infile:$BASE_DIR/conf/etc.neutron/metadata_agent.ini \
        outfile:/etc/neutron/metadata_agent.ini \
        "<CONTROLLER_IP>:${CONTROLLER_NODE_IP}" \
        "<KEYSTONE_IP>:${KEYSTONE_IP}" \
        "<SERVICE_TENANT_NAME>:${SERVICE_TENANT_NAME}" \
        "<SERVICE_PASSWORD>:${SERVICE_PASSWORD}#"
    setconf infile:$BASE_DIR/conf/etc.neutron/api-paste.ini \
        outfile:/etc/neutron/api-paste.ini \
        "<KEYSTONE_IP>:${KEYSTONE_IP}" \
        "<SERVICE_TENANT_NAME>:${SERVICE_TENANT_NAME}" \
        "<SERVICE_PASSWORD>:${SERVICE_PASSWORD}"
    setconf infile:$BASE_DIR/conf/etc.neutron/l3_agent.ini \
        outfile:/etc/neutron/l3_agent.ini \
        "<KEYSTONE_IP>:${KEYSTONE_IP}" \
        "<CONTROLLER_NODE_PUB_IP>:${CONTROLLER_NODE_PUB_IP}" \
        "<SERVICE_TENANT_NAME>:${SERVICE_TENANT_NAME}" \
        "<SERVICE_PASSWORD>:${SERVICE_PASSWORD}"
    setconf infile:$BASE_DIR/conf/etc.neutron/neutron.conf \
        outfile:/etc/neutron/neutron.conf \
        "<CONTROLLER_IP>:${CONTROLLER_NODE_IP}"
    
    if [[ "${NETWORK_TYPE}" = 'gre' ]]; then
        setconf infile:$BASE_DIR/conf/etc.neutron.plugins.openvswitch/ovs_neutron_plugin.ini.gre \
            outfile:/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini \
            "<DB_IP>:${DB_IP}" "<QUANTUM_IP>:${NETWORK_NODE_IP}"
    elif [[ "${NETWORK_TYPE}" = 'vlan' ]]; then
        setconf infile:$BASE_DIR/conf/etc.neutron.plugins.openvswitch/ovs_neutron_plugin.ini.vlan \
            outfile:/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini \
            "<DB_IP>:${DB_IP}"
    else
        echo "NETWORK_TYPE must be 'vlan' or 'gre'."
        exit 1
    fi

    # see BUG https://lists.launchpad.net/openstack/msg23198.html
    # this treat includes secirity problem, but unfortunatly it is needed for neutron now.
    # when you noticed that it is not needed, please comment out these 2 lines.
    cp $BASE_DIR/conf/etc.sudoers.d/neutron_sudoers /etc/sudoers.d/neutron_sudoers
    chmod 440 /etc/sudoers.d/neutron_sudoers

    # restart processes
    cd /etc/init.d/; for i in $( ls neutron-* ); do sudo service $i restart; done
}

# --------------------------------------------------------------------------------------
# create network via neutron
# --------------------------------------------------------------------------------------
function create_network() {

    # check exist 'router-demo'
    ROUTER_CHECK=$(neutron router-list | grep "router-demo" | get_field 1)
    if [[ "$ROUTER_CHECK" == "" ]]; then
        echo "router does not exist." 
        # create internal network
        TENANT_ID=$(keystone tenant-list | grep " service " | get_field 1)
        INT_NET_ID=$(neutron net-create --tenant-id ${TENANT_ID} int_net | grep ' id ' | get_field 2)
        # create internal sub network
        INT_SUBNET_ID=$(neutron subnet-create --tenant-id ${TENANT_ID} --name int_subnet --ip_version 4 --gateway ${INT_NET_GATEWAY} ${INT_NET_ID} ${INT_NET_RANGE} | grep ' id ' | get_field 2)
        neutron subnet-update ${INT_SUBNET_ID} list=true --dns_nameservers 8.8.8.8 8.8.4.4
        # create internal router
        INT_ROUTER_ID=$(neutron router-create --tenant-id ${TENANT_ID} router-demo | grep ' id ' | get_field 2)
        INT_L3_AGENT_ID=$(neutron agent-list | grep ' L3 agent ' | get_field 1)
        while [[ "$INT_L3_AGENT_ID" = "" ]]
        do
            echo "waiting for L3 / DHCP agents..."
            sleep 3
            INT_L3_AGENT_ID=$(neutron agent-list | grep ' L3 agent ' | get_field 1)
        done
        #neutron l3-agent-router-add ${INT_L3_AGENT_ID} router-demo
        neutron router-interface-add ${INT_ROUTER_ID} ${INT_SUBNET_ID}
        # create external network
        EXT_NET_ID=$(neutron net-create --tenant-id ${TENANT_ID} ext_net -- --router:external=True | grep ' id ' | get_field 2)
        # create external sub network
        neutron subnet-create --tenant-id ${TENANT_ID} --name ext_subnet --gateway=${EXT_NET_GATEWAY} --allocation-pool start=${EXT_NET_START},end=${EXT_NET_END} ${EXT_NET_ID} ${EXT_NET_RANGE} -- --enable_dhcp=False
        # set external network to demo router
        neutron router-gateway-set ${INT_ROUTER_ID} ${EXT_NET_ID}
    else
        echo "router exist. You don't need to create network."
    fi
}

