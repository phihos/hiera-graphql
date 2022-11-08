# hiera_graphql

A GraphQL backend for Hiera 5.

## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with hiera_graphql](#setup)
    * [What hiera_graphql affects](#what-hiera_graphql-affects)
    * [Setup requirements](#setup-requirements)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Description

Enables Hiera 5 to query GraphQL backends for data.
Its primary use-case is retrieving information from NetBox but the general nature of this module should be able to
retrieve data from any GraphQL backend.

## Setup

### What hiera_graphql affects

This hiera backend hooks into your hiera lookups. 
Since you have to statically set `confige_key` for a query it is very unlikely that a GraphQL query is being done by accident. 

### Setup Requirements

This module requires the [graphql](https://forge.puppet.com/modules/phihos/graphql) module which in turn requires 
the [graphql-client](https://github.com/github/graphql-client) gem to be installed on the puppetserver.

You can install it manually by running:

```bash
puppetserver gem install graphql-client
```

You can also automate this by applying the included class `graphql::puppetserver`:

```puppet
class { 'graphql::puppetserver':
  gem_ensure           => 'present',
  puppetserver_service => 'puppetserver',
}
```

The parameters above are the defaults.

## Usage

The hiera_graphql backend in meant to be used alongside the default YAML backend to retrieve options for the 
`graphql::graphql_query` function.
This is a basic example:

```yaml
# hiera.yaml
---
version: 5
defaults:
  datadir: data
  data_hash: yaml_data
hierarchy:
  - name: "Netbox lookup"
    lookup_key: hiera_graphql
    options:
      confine_to_key: netbox # will only do something when this exact key is looked up
      graphql_query_opts_lookup_key: '__hiera_graphql_netbox' # a hiera key containin query options
  - name: "Common"
    glob: "common.yaml"
```

```yaml
# data/common.yaml
__hiera_graphql_netbox:
   url: 'https://netbox.tls/graphql/'
   headers:
      # for auth try to fetch the credentials via backends lieke hiera_vault or hiera_eyaml
      Authorization: "Token %{lookup('vault_netbox.token')}"  
    # not that facts and variables can be interpolated into the query
   query: |
      {
        device_list(name: "%{::hostname}") {
          config_context
        }
        interface_list(device: "%{::hostname}") {
          name
          lag {
            name
          }
          ip_addresses {
            address
          }
        }
      }

# this key actually fetches the data
__netbox_graphql_data: "%{alias('netbox.data')}"

# this key just provides a shortcut to the fetched data
__netbox_graphql_config_context: "%{alias('__netbox_graphql_data.device_list.0.config_context')}"

# we can now parametrize a class like this
profile::dns::nameservers: "%{alias('__netbox_graphql_config_context.nameservers')}"
```

## Limitations

This hiera backend currently does not use caching. PRs welcome.

## Development

Pull requests welcome.

THis module is developed via PDK so the usual commands apply: 
```bash
pdk bundle install
pdk validate
pdk test unit
```
