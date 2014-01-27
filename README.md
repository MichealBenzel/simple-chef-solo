# Simple chef-solo wrapper

This repository provides a very simple wrapper around chef solo. OmniTI also
provides https://github.com/omniti-labs/chef-solo-helper, but this script is
designed for a simpler case where a single git repository is in use and chef is
run via cron (or manually).


* Runs chef once, pulling from git first.
* The run list is a single role, based on the HOSTNAME environment variable.
  The applied is 'node-$HOSTNAME'. If the hostname has dots in (e.g. $HOSTNAME
  returns a fully qualified domain name), then they are replaced with dashes
  in the role. All other recipes and roles for the node should be provided in
  this role.
* Provides a '-j' option to apply a random delay (jitter), reducing the impact
  of every chef client connecting at once to the git server.
* Any extra arguments after -- are passed directly to chef-solo.
* All output is logged to /var/log/chef/solo.log.
* Log files are automatically rotated.

# Setup Notes/Procedure

* Install Chef

        curl -L https://www.opscode.com/chef/install.sh | sudo bash

* Clone the chef repository to `/var/chef`

        cd /var
        sudo git clone https://github.com/example/my-chef-repo.git chef

* Configure Root access to the git repository. If github is in use:
    * Put the private key in /root/.ssh/id_rsa_chef
    * If you don't have a private key, generate one (`ssh-keygen -t rsa -b
      2048 -f id_rsa_chef`), store it in a secure location, and add the public
      key as a deploy key to the github repository.
    * Edit /root/.ssh/config and add the following:

            Host github.com
            IdentityFile ~/.ssh/id_rsa_chef

* Put run_chef.sh in `/var/chef`
  * This should most likely be done by adding `run_chef.sh` to the git
    repository and having it be checked out along with the rest of the chef
    configuration.

## Running via cron

Add the following to your crontab:

    0,30 * * * * /var/chef/run_chef.sh -j >/dev/null 2>&1

## Running manually

Just run the command via sudo:

    sudo /var/chef/run_chef.sh

Optionally, in why-run mode:

    sudo /var/chef/run_chef.sh -- --why-run
