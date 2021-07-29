# @summary Apply yum updates via cron
#
# @param enabled
#   Boolean of whether yum updates via cron are enabled
#
# @param exclude
#   String of list of packages to exclude from yum updates
#
# @param update_day_of_week
#   Array of strings containing days of week for yum cron
#   If not defined days are colculated from hostname
#
# @param update_month
#   Array of strings containing months for yum cron
#
# @param update_week_of_month
#   Array of strings containing week of the month for yum cron, e.g. "1"-"5"
#   If not defined cron runs every week
#
# @example
#   include profile_update_os::yum_cron
class profile_update_os::yum_cron (
  Boolean       $enabled,
  String        $exclude,
  Array[String] $update_day_of_week,
  Array[String] $update_month,
  Array[String] $update_week_of_month,
) {

  ## IMPROVEMENT IDEAS
  ## - MOVE DEFAULT DAY/WEEK LOGIC TO FUNCTION THAT CAN BE REFERENCED BY BOTH yum_cron & kernel_update
  ##   SO SAME LOGIC IN A SINGLE PLACE
  ##   - UPDATE TO CHECK FOR '-test' ANYWHERE IN HOSTNAME
  ##   - HOSTS ENDING IN A NUMBER SHOULD RUN ON MOD 4 WEEK
  ##   - MAP HOSTS ENDING IN '-a' OR DIGIT & CHARACTER TO MAP TO NUMBER WITH MOD 4 FOR THE WEEK
  ## - MOVE OS SPECIFIC IMPLEMENTATION TO HIERA OS DATA
  ##   - PACKAGES, SERVICE, COMMAND, COMMAND OPTIONS, ETC.
  ## - CRON ENTRIES MIGHT BENEFIT FROM function OR defined type
  ##   - ESPECIALLY TO SHARE THE CODE FOR CALCULATING HOW TO DO WEEK OF MONTH IN CRON
  ## - SWITCH TO 'run-if-today' SCRIPT FOR CRONS
  ## - ADD WALL MESSAGE WARNINGS FOR X DAYS BEFORE REBOOT
  ## - ADD motd.d NOTICE WITH CALCULATED LANGUAGE (FOR kernel_update)
  ## - ADD EXCLUDE OPTIONS FOR
  ##   - PACKAGES TO IGNORE
  ##   - REPOS TO IGNORE
  ##   - CONVERT EXCLUDES TO ARRAY

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
      $weekday = $update_day_of_week
    }
    else
    {
      case $facts['hostname'] {
        /[13579]$/: { $weekday = 'wed'  }
        /test$/:    { $weekday = 'odd'  }
        default:    { $weekday = 'tue'  }
      }
    }
    case $update_week_of_month {
      1, '1':       { $day_of_month = '1-7' }
      2, '2':       { $day_of_month = '8-14' }
      3, '3':       { $day_of_month = '15-21' }
      4, '4':       { $day_of_month = '22-28' }
      5, '5':       { $day_of_month = '29-31' }
      default: { $day_of_month = '*' }
    }
    Cron {
      user     => 'root',
      hour     => 5,
      minute   => 0,
      monthday => $day_of_month,
      month    => $update_month,
    }
    case $weekday {
      'odd':   { $cron_day = [1,3,5] }
      'even':  { $cron_day = [2,4] }
      'tue':   {
        $cron_day = '*'
        $weekday_command = "( test \$(date +\\%w) = 2 ) &&"
      }
      'wed':   {
        $cron_day = '*'
        $weekday_command = "( test \$(date +\\%w) = 3 ) &&"
      }
      default: {
        $cron_day = '*'
        $weekday_command = "( test \$(date +\\%w) = ${weekday} ) &&"
      }
    }
    if $weekday != false {
      cron { 'yum-cron':
        command => "( ${weekday_command} yum clean all -q && ${yum_cron_command} )",
        weekday => $cron_day,
      }
    }
  }
  else
  {
    cron { 'yum-cron':
      ensure => absent,
    }
  }

}
