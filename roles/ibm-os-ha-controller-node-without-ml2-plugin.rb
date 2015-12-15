# =================================================================
# Licensed Materials - Property of IBM
#
# (c) Copyright IBM Corp. 2014, 2015 All Rights Reserved
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
# =================================================================

name 'ibm-os-ha-controller-node-without-ml2-plugin'
description 'IBM OpenStack HA Controller Node role'
run_list(
  'recipe[ibm-openstack-roles::ha-controller-node-without-ml2-plugin]'
)
