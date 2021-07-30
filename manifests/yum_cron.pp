# @summary Apply yum updates via cron
#
# @param enabled
#   Boolean of whether yum updates via cron are enabled
#
# @param exclude
#   String of list of packages to exclude from yum updates
#
# @param update_day_of_week
#   String containing day of week abbreviation for yum update cron
#   e.g. "Sun", "Mon", "Tue", etc.
#   If not defined day of week is calculated from hostname
#
# @param update_hour
#   Hour for yum update cron
#   There is a random delay of up to 30 minutes before the yum update occurs
#
# @param update_minute
#   Minute for yum update cron
#   There is a random delay of up to 30 minutes before the yum update occurs
#
# @param update_month
#   Array of strings containing months for yum update cron
#
# @param update_week_of_month
#   Strings containing week of the month for yum update cron, e.g. "1"-"5" or "any"
#   If not defined cron runs every week
#
# @example
#   include profile_update_os::yum_cron
class profile_update_os::yum_cron (
  Boolean       $enabled,
  String        $exclude,
  String        $update_day_of_week,
                $update_hour,
                $update_minute,
  Array[String] $update_month,
  String        $update_week_of_month,
) {

  if $enabled
  {
    if ( $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] <= '7' ) {
      package { 'yum-cron':
        ensure => installed,
      }
      file_line { 'yum_conf_installonly_limit':
        ensure   => 'present',
        path     => '/etc/yum.conf',
        line     => 'installonly_limit=2',
        match    => '^installonly_limit*',
        multiple => 'false',
        require  => Package['yum-cron'],
        notify   => Service['yum-cron'],
      }
      file_line { 'yum_conf_exclude':
        ensure   => 'present',
        path     => '/etc/yum.conf',
        line     => "exclude=${exclude}",
        match    => '^exclude*',
        multiple => 'false',
        require  => Package['yum-cron'],
        notify   => Service['yum-cron'],
      }
      if ( $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] >= '7' )
      {
        file_line { 'yum__cron_conf_apply_updates':
          ensure   => 'present',
          path     => '/etc/yum/yum-cron.conf',
          line     => 'apply_updates = yes',
          match    => '^apply_updates*',
          multiple => 'false',
          require  => Package['yum-cron'],
          notify   => Service['yum-cron'],
        }
        file_line { 'yum__cron_conf_random_sleep':
          ensure   => 'present',
          path     => '/etc/yum/yum-cron.conf',
          line     => 'random_sleep = 30',
          match    => '^random_sleep*',
          multiple => 'false',
          require  => Package['yum-cron'],
          notify   => Service['yum-cron'],
        }
      }
      service { 'yum-cron':
        ensure     => stopped,
        enable     => false,
        hasstatus  => true,
        hasrestart => true,
        require    => Package['yum-cron'],
      }

      $yum_cron_command='exec /usr/sbin/yum-cron'

    }
    else
    { ## dnf-automatic
      package { 'dnf-automatic':
        ensure => installed,
      }
      service { 'dnf-automatic':
        ensure     => stopped,
        enable     => false,
        hasstatus  => true,
        hasrestart => true,
        require    => Package['dnf-automatic'],
      }
      file_line { 'dnf_conf_installonly_limit':
        ensure   => 'present',
        path     => '/etc/dnf/dnf.conf',
        line     => 'installonly_limit=2',
        match    => '^installonly_limit*',
        multiple => 'false',
      }
      file_line { 'dnf_conf_exclude':
        ensure   => 'present',
        path     => '/etc/dnf/dnf.conf',
        ## https://access.redhat.com/solutions/5272311 2020-08-02 wglick
        line     => "exclude=${exclude}",
        match    => '^exclude*',
        multiple => 'false',
      }
      file_line { 'dnf-automatic_conf_apply_updates':
        ensure   => 'present',
        path     => '/etc/dnf/automatic.conf',
        line     => 'apply_updates = yes',
        match    => '^apply_updates*',
        multiple => 'false',
        require  => Package['dnf-automatic'],
      }
      file_line { 'dnf-automatic_conf_random_sleep':
        ensure   => 'present',
        path     => '/etc/dnf/automatic.conf',
        line     => 'random_sleep = 0',
        match    => '^random_sleep*',
        multiple => 'false',
        require  => Package['dnf-automatic'],
      }
      $yum_cron_command='( sleep $((RANDOM \% 30))m && /usr/bin/dnf-automatic )'
    }


    if ( ! empty($update_day_of_week) ) {
      $day_of_week = $update_day_of_week
    }
    else
    {
      $day_of_week = profile_update_os::calculate_day_of_week($facts['hostname'])
    }
    if ( ! empty($update_week_of_month) ) {
      $week_num = $update_week_of_month
    }
    else
    {
      $week_num = profile_update_os::calculate_week_of_month($facts['hostname'])
    }

    Cron {
      user     => 'root',
    }

    cron { 'yum-cron':
      command => "( /root/scripts/run-if-today.sh ${week_num} ${day_of_week} && ${yum_cron_command} )",
      hour    => $update_hour,
      minute  => $update_minute,
      month   => $update_month,
    }

  }
  else
  {
    cron { 'yum-cron':
      ensure => absent,
    }
  }

}
