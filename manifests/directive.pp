/*

== Definition: apache::directive

Convenient wrapper around File[] resources to add random configuration
snippets to an apache virtualhost.

Parameters:
- *ensure*: present/absent.
- *directive*: apache directive(s) to be applied in the corresponding
  <VirtualHost> section.
- *vhost*: the virtualhost to which this directive will apply. Mandatory.
- *filename*: basename of the file in which the directive(s) will be put.
  Useful in the case directive order matters: apache reads the files in conf/
  in alphabetical order.

Requires:
- Class["apache"]
- matching Apache::Vhost[] instance

Example usage:

  apache::directive { "example 1":
    ensure    => present,
    directive => "
      RewriteEngine on
      RewriteRule ^/?$ https://www.example.com/
    ",
    vhost     => "www.example.com",
  }

  apache::directive { "example 2":
    ensure    => present,
    directive => content("example/snippet.erb"),
    vhost     => "www.example.com",
  }

*/
define apache::directive ($vhost, $ensure='present', $source=undef, $content=undef, $filename='') {

  include apache

  $fname = regsubst($name, '\s', '_', 'G')

  # cant proceed with source and content # thanks to ryancoleman and Volcane, from #puppet IRC Channel
  if $source and $content {
    fail('source and content parameters are both defined. Only one can be applied.')
  }

  $seltype = $::operatingsystem ? {
    'RedHat' => 'httpd_config_t',
    'CentOS' => 'httpd_config_t',
    default  => undef,
  }

  $vhost_file_name = $filename ? {
    ''      => "${apache::params::root}/${vhost}/conf/directive-${fname}.conf",
    default => "${apache::params::root}/${vhost}/conf/${filename}",
  }

  file{ "${name} directive on ${vhost}":
    ensure  => $ensure,
    source  => $source,
    content => $content,
    seltype => $seltype,
    name    => $vhost_file_name,
    notify  => Service['apache'],
    require => Apache::Vhost[$vhost],
  }
}
