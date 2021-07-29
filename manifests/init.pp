# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include profile_update_os
class profile_update_os {

  include profile_update_os::yum_cron
  include profile_update_os::kernel_upgrade

}
