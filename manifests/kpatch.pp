# @summary Install kpatch
#
# @param enabled
#   Install kpatch package and start service, noop if set to false (no clean-up)
#
# @param install_kpatch_patches
#   Install the kpatch-patch package for the current kernel
#
# @param kpatch_patch_version
#   Specify the exact kpatch-patch to install (default is to go to latest)
#   
#   Example locking kpatch-patch to version+release 0-0 under the 4.18.0-372.41.1 kernel:
#   ```
#   profile_update_os::kpatch::kpatch_patch_version: "4_18_0-372_41_1-0-0.el8_6"
#   ```
#
# @example
#   include profile_update_os::kpatch
class profile_update_os::kpatch (
  Boolean $enabled,
  Boolean $install_kpatch_patches,
  String  $kpatch_patch_version,
) {
  if $enabled {
    ensure_packages( 'kpatch', { notify => Service['kpatch'] })

    service { 'kpatch':
      ensure => running,
    }

    if $install_kpatch_patches {
      ensure_packages('kpatch-patch', { require => Service['kpatch'], ensure => $kpatch_patch_version })
    }
  }
}
