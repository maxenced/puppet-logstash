# == Class: logstash_legacy::service
#
# This class exists to coordinate all service management related actions,
# functionality and logical units in a central place.
#
# <b>Note:</b> "service" is the Puppet term and type for background processes
# in general and is used in a platform-independent way. E.g. "service" means
# "daemon" in relation to Unix-like systems.
#
#
# === Parameters
#
# This class does not provide any parameters.
#
#
# === Examples
#
# This class may be imported by other classes to use its functionality:
#   class { 'logstash_legacy::service': }
#
# It is not intended to be used directly by external resources like node
# definitions or other modules.
#
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard.pijnenburg@elasticsearch.com>
#
class logstash_legacy::service {

  case $logstash_legacy::service_provider {

    'init': {
      logstash_legacy::service::init { $logstash::params::service_name: }
    }

    default: {
      fail("Unknown service provider ${logstash_legacy::service_provider}")
    }

  }

}
