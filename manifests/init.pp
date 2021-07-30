# @summary configure functionality for upgrading OS packages
#
# @example
#   include profile_update_os
class profile_update_os {

  ## IMPROVEMENT IDEAS
  ## - MOVE OS SPECIFIC IMPLEMENTATION TO HIERA OS DATA
  ##   - PACKAGES, SERVICE, COMMAND, COMMAND OPTIONS, ETC.
  ## - ADD WALL MESSAGE WARNINGS FOR X DAYS BEFORE REBOOT
  ## - ADD EXCLUDE OPTIONS FOR
  ##   - PACKAGES TO IGNORE (ALREADY THERE FOR yum_cron)
  ##   - REPOS TO IGNORE
  ##   - CONVERT EXCLUDES TO ARRAY
  ## - MERGE IN IMPROVEMENTS/FEATURES FROM lsst-pup MAINTENANCE CLASSES

  include profile_update_os::common
  include profile_update_os::kernel_upgrade
  include profile_update_os::yum_cron

}
