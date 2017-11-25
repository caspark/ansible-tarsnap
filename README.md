

# Ansible-tarsnap (tweaked)

This is a ansible role for automating tarsnap backups on Ubuntu (tested on 14.04); it downloads sources for,
verifies the gpg-encrypted sha signature, compiles, and installs [Tarsnap].

**Batteries included**: [tarsnapper], cron job, shell wrapper, and [logrotate] policy.

It's a tweaked version of [pmbauer's ansible-tarsnap](https://github.com/pmbauer/ansible-tarsnap):

 * Provide tarsnap key in a variable instead of having to use a separate play/role to set up the tarsnap key
 * Support for backups using write-only tarsnap keys (you'll need to handle expiry yourself then)
 * Support for placing an alternate tarsnap key on the system (e.g. a passphrase-protected key with read and delete permissions so that it can be used to expire jobs)
 * Allow locations of most installed files to be customized
 * Expects tarsnapper's [`include-jobs` directive](https://github.com/miracle2k/tarsnapper/issues/2) to be used
 * Locked down file permissions
 * Install tarsnap via the official debian repo rather than building from source
 * Install tarsnapper to its own python virtualenv rather than installing it system-wide

## Requirements
- [Tarsnap] account
- [Tarsnap] machine key file
    - instructions to generate one are in the [standalone](#standalone) section
    - **important** this role assumes you are responsible for copying this key to `tarsnap_keyfile`.  See [role variables](#role variables)

## Using

Here's a sample configuration which installs tarsnap with a write-only tarsnap key (which is used for actually making
the backups), and another tarsnap key which has full permissions (you should create this key with a passphrase - see
below) but isn't actually used (you'll need to manually expire backups), and then runs the cron job to trigger
tarsnapper once a week on Sunday at 5am:

```
- hosts: all
  remote_user: ansibler
  vars:
    # in a real playbook, you'd make these unique per host, since only 1 host should be writing using a tarsnap key
    tarsnap_key_content_write_only: |
      # START OF TARSNAP KEY FILE
      <replace with contents of your tarsnap write-only key>
      # END OF TARSNAP KEY FILE
    tarsnap_key_content_full_permissions: |
      # START OF TARSNAP KEY FILE
      <replace with contents of your passphrase-protected tarsnap key which has full permissions>
      # END OF TARSNAP KEY FILE
  roles:
  - role: ansible-tarsnap
    tarsnap_key_file: "/root/tarsnap-write-only.key"
    tarsnap_key_content: "{{ tarsnap_key_content_write_only }}"
    tarsnap_key_alternate_file: "/root/tarsnap-full-perms.key"
    tarsnap_key_alternate_content: "{{ tarsnap_key_content_full_permissions }}"
    # run at 5am every Sunday - see http://crontab.guru/#0_5_*_*_0
    tarsnapper_cron_minute: "0"
    tarsnapper_cron_hour: "5"
    tarsnapper_cron_day: "*"
    tarsnapper_cron_month: "*"
    tarsnapper_cron_weekday: "0"
    tarsnapper_default_target: "{{ inventory_hostname }}/$name-$date"
    tarsnapper_default_deltas: "7d 30d 365d"
    tarsnapper_job_command: "-v make --no-expire" # because tarsnap has a key that doesn't have read or delete permissions
```

This prevents an attacker who gains access to your write key from being able to read or delete your backups.

If you're less paranoid, you can create a configuration which only defines 1 key:

```
- hosts: all
  remote_user: ansibler
  vars:
    tarsnap_key_content: |
      # START OF TARSNAP KEY FILE
      <replace with contents of your tarsnap key with full permissions, without a passphrase>
      # END OF TARSNAP KEY FILE
  roles:
  - role: ansible-tarsnap
    # (you actually don't need the line below because it's the default location for the key)
    tarsnap_key_file: "/root/tarsnap.key"
    # (you actually don't need the line below because tarsnap_key_content is already in scope, but we're being explicit)
    tarsnap_key_content: "{{ tarsnap_key_content }}"
    # run at 5am every Sunday - see http://crontab.guru/#0_5_*_*_0
    tarsnapper_cron_minute: "0"
    tarsnapper_cron_hour: "5"
    tarsnapper_cron_day: "*"
    tarsnapper_cron_month: "*"
    tarsnapper_cron_weekday: "0"
    tarsnapper_default_target: "{{ inventory_hostname }}/$name-$date"
    tarsnapper_default_deltas: "7d 30d 365d"
    tarsnapper_job_command: "-v make --no-expire" # because tarsnap has a key that doesn't have read or delete permissions
```

You can customize the role further by overriding defined variables in `defaults/main.yml` and `vars/main.yml`

## Generating tarsnap keys

See `man tarsnap-keymgmt` for info on how to create a key with write-only permissions or add a passphrase to an existing
key.

## license
Source Copyright © 2014 Paul Bauer. Distributed under the GNU General Public License v3, the same as Ansible uses.
See the file COPYING.

[Ansible]:http://www.ansible.com/home
[ansible-pull]:http://linux.die.net/man/1/ansible-pull
[ansible cron module]:http://docs.ansible.com/cron_module.html
[logrotate]:http://linuxcommand.org/man_pages/logrotate8.html
[Tarsnap]:https://www.tarsnap.com/
[sovereign]:https://github.com/al3x/sovereign
[tarsnapper]:https://github.com/miracle2k/tarsnapper
[tarsnapper.default.conf]:https://github.com/pmbauer/ansible-tarsnap/tree/master/files/tarsnapper.default.conf
