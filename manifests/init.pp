# Class: dnsupdate
#
# This module manages PTR, and A records in AD DNS
#
# Parameters: none
#
# Actions: 
# It makes sure bind-utils is installed which has the nsupdate binary.
# It makes a file /etc/nsupdate used for pushing updates and for
# verifying that updates need to be made by queuring DNS first.
#
# Requires: stdlib
#
# Sample Usage: include ::dnsupdate
#
class dnsupdate ($ipaddr             = $::ipaddress,
                 $dnsname            = $::fqdn,
                 $manage_bind_utils  = true,
                 $bind_utils_package = 'bind-utils') {
  
  if $manage_bind_utils { 
    # Package
    package {'bind-tools': 
      ensure => present,
      name   => $bind_utils_package
    }
  }
  
  # Update
  file { '/etc/nsupdate':
    ensure  => 'present',
    content => template('dnsupdate/nsupdate.erb')
  } ->
  exec { 'nsupdate':
    path     => ['/bin', '/usr/bin'],
    command  => 'nsupdate /etc/nsupdate',
    provider => 'shell',
    unless   => "grep $(nslookup $(hostname -f) |sed -n '/^Name/{n;s/.*: //p}') /etc/nsupdate && grep $(nslookup $(hostname -i)|egrep -o '^[0-9]+.[0-9]+.[0-9]+.[0-9]+') /etc/nsupdate",
    require  => Package['bind-tools'],
  }
}
