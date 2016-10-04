# Rails 4 Starter Template

This Rails 4 Starter Template is meant as a foundation upon which Rails applications can be built quickly and sustainably. It uses the following technologies:

- Deploy: Mina
- HTML Server: Nginx
- Rails Server: Puma

## Usage

Copy and run in terminal (or see below for command explanations):

```
git remote add template git@github.com:JumpStartGeorgia/Starter-Template.git
git remote set-url template no_push --push
git fetch template
git merge template/master
```

1. Add the Starter Template to your Rails project as a remote repository called "template": `git remote add template git@github.com:JumpStartGeorgia/Starter-Template.git`
2. Disable push connection to template repository: `git remote set-url template no_push --push`
3. Run `git fetch template` to update local copy of template repository.
4. Run `git merge template/master` to merge in changes from the template repository into your current branch. If you have committed changes to your project since the last time you merged in the template repository (or if this is your first time merging in the repository), you may have to resolve merge conflicts in your code.
5. Repeat steps #3 and #4 every so often in order to incorporate changes in the template repository.

## Using Mina

### Setup

Add your stage-specific deploy variables to the files in config/deploy.

### Deploy

1. Run `mina setup`
  - The default stage is set to `staging`, so this command is equivalent to the command `mina staging setup`
2. Run `mina rails:edit_env` and add your project secrets
3. Run `mina deploy first_deploy=true --verbose`
  - If you get the error “Host key verification failed” when mina tries to clone the git repository, you may have to add your repository’s host to known_hosts on your server. You can run one of these two commands on the server to fix that (works for github):
    - `ssh-keyscan -H github.com >> ~/.ssh/known_hosts`
      - Adds github to user’s known hosts
    - `ssh-keyscan -H github.com >> etc/ssh/ssh_known_hosts`
      - Adds github to known hosts for all users
4. Run `mina post_setup sudo_user=<username>`, where `<username>` is a user with sudo permissions on your server. You will need to enter the user’s password a number of times to execute the sudo commands.
5. Deploy further changes with `mina deploy` or `mina deploy --verbose`
6. Repeat these steps for your other stages, simply by inserting the stage name into the command after `mina`. Examples:
  - `mina setup` --> `mina production setup`
  - `mina deploy precompile=true --verbose` --> `mina production deploy precompile=true --verbose`

#### Options (mina deploy <options>)

[precompile=true]  forces precompile assets
[verbose=true]            outputs more information (default is quieter and prettier)

### Commands

Run `mina -T` for a list of mina's commands.

### Precompile Assets Method

Unlike in the standard Mina deploy, assets are precompiled locally and rsynced up to the server in this starter-template. The method is as follows:

1. Determine whether to precompile the assets
   a. If the flag 'precompile=true' is set, then precompile assets
   b. Use git to view difference in the assets files between the commit on the server
      and the commit on the local machine. If there is a difference, precompile assets
   c. If cannot determine the commit on the server, show error and ask user to run deploy with 'precompile=true'
   d. If git diff gives an error, precompile assets
2. If not precompiling assets, skip to step 3. Otherwise...
   a. precompile assets locally
   b. sync tmp/assets on server with local precompiled assets
3. During deploy, copy assets from tmp/assets to current/public/assets

### Puma Jungle (Controlling Multiple Puma Apps)

Setting up the Puma Jungle on the server allows you to run commands such as start, stop, status, etc. for multiple puma apps at one time. You can also configure it to restart all apps whenever the server reboots.

In order to setup the jungle, follow [these steps](https://github.com/puma/puma/tree/master/tools/jungle/init.d). You may have to modify the default scripts to work on your server; if things don't work out of the box, try consulting [this guide](http://dev.mensfeld.pl/2014/02/puma-jungle-script-fully-working-with-rvm-and-pumactl/).

If your primary puma jungle script is stored at the default location `/etc/init.d/puma`, here are some commands you can use (you may have to run with sudo):
 - `/etc/init.d/puma start`
 - `/etc/init.d/puma stop`
 - `/etc/init.d/puma status`
 - `/etc/init.d/puma restart`

This starter template provides access to the puma jungle through mina commands, such as `mina puma:jungle:start`. Run `mina -T puma:jungle` to see all these commands.


### Notes
  * While uploading excel file make sure they have mime type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', as file was resaved in ubuntu its mime type is 'application/zip'
  * After seed call rake mongoid_slug:set
