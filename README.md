# Ansible Best Practises

If infrastructures are to be treated as a code than projects that manage them must be treated as software projects.
As your infrastructure code gets bigger and bigger you have more problems to deal with it.
Code layout, variable precedence, small hacks here and there.
Therefore, organization of your code is very important, and in this repository you can find some of the best practices (in our opinion) to manage your infrastructure code.

Problems that are addressed are:

* Overall organization
* How to manage external roles
* Usage of variables
* Naming
* Staging
* Complexity of plays
* Encryption of data (e.g. passwords, certificates)
* Installation of ansible and module dependencies
* Simplifying contributing for new team members

## 0. Guideline

* Do not manage external roles in your repository manually, use git submodule (it has stronger versioning than ansible-galaxy)
* Do not use pre_task, task or post_tasks in your play, use roles to reuse the code
* Keep all your variables in one place, if possible
* Do not use variables in your play
* Use variables in the roles instead of hard-coding
* Keep the names consistent between groups, plays, variables, and roles
* Different environments (development, test, production) must be close as possible, if not equal
* Do not put your password or certificates as plain text in your git repo, use ansible-vault/git-crypt for encrypting
* Use tags in your play
* Keep all your ansible dependencies in a single place and make the installation dead-simple

## 1. Directory Layout

This is the directory layout of this repository with explanation.

    production.ini                         # inventory file for production stage
    development.ini                        # inventory file for development stage
    test.ini                               # inventory file for test stage
    .vpass                                 # ansible-vault password file
                                           # This file should not be committed into the repository
                                           # therefore this file is ignored by git
    .ssh.vpass                             # SSH Private key for ci pipeline, supplied by GitLab and .gitlab-ci.yml
                                           # This file is therefore ignored by git, it should not be created in .gitlab-ci
                                           # Instead view the example inside of .gitlab-ci.yml to use ssh-agent instead
    .ssh.pub.vpass                         # Associated public key for .ssh.vpass, if .ssh.vpass is required for deployment
    .gitlab-ci.yml                         # GitLab CI Pipeline configuration for automized deployment and unit tests
    .gitmodules                            # Git Submodules file, list of all associated submodules + version
    .gitignore                             # List of files ignored by git.
    .gitattributes                         # Register *.vault.* for automated de/encryption if hook is present
    group_vars/                            # Contains all your play variables, grouped by hostgroups
        all/                               # variables under this directory belongs all the groups
            apt.yml                        # ansible-apt role variable file for all groups
        webservers/                        # here we assign variables to webservers groups
            apt.yml                        # Each file will correspond to a role i.e. apt.yml
            nginx.yml                      # Variables for nginx for all hosts inside the webservers hostgroup
        postgresql/                        # here we assign variables to postgresql groups
            postgresql.yml                 # Each file will correspond to a role i.e. postgresql
            postgresql-password.yml        # Encrypted password file
    host_vars/                             # Contains all your host dependent play variables
        <hostname>.<domain>.yml            # e.g. Networking settings or other host specific variables
                                           # where possible use group_vars instead.
    plays/                                 # Contains the playbook and scripts for simplified deployment
        ansible.cfg                        # Ansible.cfg file that holds all ansible config
        play.yml                           # playbook for your infrastructure
        debug-play.sh                      # Warper for stepping through the tasks in the playbook (debugging only)
        play.sh                            # Warper for applying the role (also updates external roles) also used by CI
        testing-play.sh                    # Verbosly applies the role to the hosts specified in testing.ini
    roles/
        external/                          # All external rules included as git submodule (use `git submodule` to manage)
        internal/                          # Tasks that are part of this playbook and not within separate git repos (only common should inside here)
            common/                        # Specifies a list of generic pretasks (by using dependencies), for simplified writing of the mailflow.yml file
    extension/
        git/                               # Contains git hooks and filters
            pre-commit                     # Git pre commit hook for updating external roles automatically
            vault-clean.sh                 # Git clean filter for encrypting all .*\.vault((\..*)|$) files
            vault-diff.sh                  # Git diff filter, to diff the decrypted version of the vault-files
                                           # instead of there cipher text
            vault-smudge.sh                # Git smudge filter, to decrypt all vault-files by using the .vpass file
        setup/                             # All the setup files for updating roles and ansible dependencies
            install_git_hook.sh            # Shellscript to install the git hooks and git-lfs
            required_packages_arch.txt     # All required packages for the playbook host to run this play, if it is archlinux based
            required_packages_deb.txt      # All required packages for the playbook host to run this play, if it is debian based
            required_pip_packages_deb.txt  # All packages that need to be fetched using pip on debian based systems
                                           # (where possible use `required_packages_deb.txt` instead)
            required_pip_packages_arch.txt # All packages that need to be fetched using pip on archlinux based systems
                                           # (where possible use `required_packagees_arch.txt` instead)
            role_update.sh                 # Shellscript to pull latest version of submodules
            setup.sh                       # Shellscript to initialize this repository (install git hooks), and install required packages

## 2. How to Manage Roles

It is a bad habit to manage the roles that are developed by other developers, in your git repository manually.
It is also important to separate them so that you can distinguish those that are external and can be updated vs those that are internal.
Therefore, you can use git submodules for installing the roles you need, at the location you need, by simply defining them in the roles_requirements.yml:

```yaml
---
- src: ANXS.build-essential
  version: "v1.0.1"
```

Roles can be downloaded/updated manually with this command, or by performing a commit:

```bash
./extensions/setup/role_update.sh
```

This command will delete all external roles and download everything from scratch.
This is a good practice, as this will not allow you to make untracked changes in the roles.

## 3. Keep your plays simple

If you want to take the advantage of the roles, you have to keep your plays simple.
Therefore do not add any tasks in your main play.
Your play should only consist of the list of roles that it depends on.
Here is an example:

```yaml
---

- name: postgresql.yml | All roles
  hosts: postgresql
  sudo: True

  roles:
    - { role: common,                   tags: ["common"] }
    - { role: ANXS.postgresql,          tags: ["postgresql"] }
```

As you can see there are also no variables in this play, you can use variables in many different ways in ansible, and to keep it simple and easier to maintain do not use variables in plays.
Furthermore, use tags, they give wonderful control over role execution.

## 4. Stages

Most likely you will need different stages (e.g. test, development, production) for the product you are either developing or helping to develop.
A good way to manage different stages is to have multiple inventory files.
As you can see in this repository, there are three inventory files.
Each stage you have must be as identical as possible, that also means, you should try to use as few as possible host variables.
It is best to not use them at all.
But you may still require them for setting up network interfaces or hostnames.

## 5. Variables

Variables are wonderful, that allows you to use all this existing code by just setting some values.
Ansible offers many different ways to use variables.
It is good practice to keep all your variables in one place, and this place happen to be group_vars.
They are not host dependent, so it will help you to have a better staging environment as well.
That group_vars is the only place is not quite true, there is also host_vars, for host specific variables.
You shouldn't use host_vars except if necessary e.g. for setting up network interfaces or assigning the hostname.

## 6. Name consistency

If you want to maintain your code, keep the name consistency between your plays, inventories, roles and group variables.
Use the name of the roles to separate different variables in each group.
For instance, if you are using the role nginx under webservers play, variables that belong to nginx should be located under *group_vars/webservers/nginx.yml*.
What this effectively means is that  group_vars supports directory and every file inside the group will be loaded.
You can, of course, put all of them in a single file as well, but this is messy, therefore don't do it.

## 7. Encrypting Passwords and Certificates

It is most likely that you will have a password or certificates in your repository.
It is not a good practise to put them in a repository as plain text. You can use [ansible-vault](http://docs.ansible.com/playbooks_vault.html) to encrypt sensitive data.
You can refer to [postgresql-password.yml](https://github.com/enginyoyen/ansible-best-practises/blob/master/group_vars/postgresql/postgresql-password.yml) in group variables to see the encrypted file and [postgresql-password-plain.yml](https://github.com/enginyoyen/ansible-best-practises/blob/master/group_vars/postgresql/postgresql-password-plain.yml) to see the plain text file, commented out.
To decrypt the file, you need the vault password, which you can place in your root directory but it MUST NOT be committed to your git repository. You should share the password with you coworkers with some other method than committing to git a repo.

En-/Decrypting is done automatically using a git filter for this project, if the .vpass file is present in the project root.

There is also [git-crypt](https://github.com/AGWA/git-crypt) that allow you to work with a key or GPG.
Its more transparent on daily work than `ansible-vault`

## 8. Project Setup

As it should be very easy to set-up the work environment, all required packages that ansible needs, as well as ansible should be installed automatically (or use the docker image).
This will allow newcomers or developers to start using this ansible project very fast and easy, and also allow simplified Ci deployment.
The requirements files are located at extensions/setup/required_*.txt:

This structure will help you to keep your dependencies in a single place, as well as making it easier to install everything including ansible. All you have to do is to execute the setup file:

```bash
./extensions/setup/setup.sh
```

## 9. Add additonal external Roles

```bash
git submodule add -b master ../../ansible-roles-voffice/projectName.git ./roles/external/projectName
```

This strange submodule syntax is required in order for gitlab ci to properly clone the repossitory.
It looks like that because we need to provide a relative path instead of an absolute one.
Infact it depends on the git repository url of this playbook.

Ansible-galaxy may look nice at the first look, but it has some limitations in combination with gitlab and automated deployment.
Also git submodules give us better versioning (exactly the commit that was tested/checked in is fetched by default).
This allows for simplified rolback and reexecuting of an older version at a later point in time.

## 10. Running the Code

Code in this repo is functional and tested.
To run it, you need to install ansible and all the dependencies.

You can do this simply by executing:

```bash
echo "PASSWORD" > .vpass
./extensions/setup/setup.sh
./play/play.sh
```

* If you don't have any encrypted configuration, create a dummy .vpass file with content '123456' or a strong passphrase for later use.
* As you don't need to type the content of the .vpass file, you should use a very long passphrase at least 120 characters
* To manually install dependent roles execute the role_update.sh which will download all the roles

```bash
./extensions/setup/role_update.sh
```

## 11. License

MIT License.

## 12. Adopting for your own playbook

You need to change the following after copying this into your new playbook repository:

* `plays/play.sh`: You need to include your hosts ssh public keys (View comments inside there for more details)
* `development.ini`: Update with your development hosts and hostgroups
* `production.ini`: Update with your production hosts and hostgroups
* `test.ini`: Update with your testing hosts and hostgroups
* `.vpass`: Create this file with a strong and unique passphrase (you don't need to remember it, but you should save it somewhere secury, like inside a password manager)
* `extensions/setup/required_*`: Add the packages you need on the host that executes your playbook (not the clients), if any
* `git submodules`: You should fork all referenced gitmodules (also thouse from ansible-galaxy) into your own gitlab instance/space and configure the mirroring feature to mirror the remote/original repository. This protects you from breaking all your playbooks because the maintainer of the role decided to delete the git repository. And also allows you to diverge from the original one and implement your own changes and/or skip changes made in the future (turn off the mirroring feature for this)
* `group_vars`: Remove the examples and insert your own code
* `host_vars`: Remove the examples and insert your own code
* `plays/play.yml`: Write your playbook inside here
* `roles/internal/common`: Consider moving this into it's own git repository and reference it from all your playbooks as common task (path would become `roles/external/common` of course). You will still have to include the submodules into each project, but that allows simplified change tracking and also enables you to keep your "common" tasks in sync across all your playbooks. If you don't want to have to add another submodule to all your playbooks if you add a new common role, you could also include these roles as submodules of the common role (inside of a `roles` subdirectory). All you need for that to work is add `../roles/external/common/roles` to the `roles_path` attribute inside the `plays/ansible.cfg` (see example there).
* `*/.gitkeep`: These files can be removed, they are only included because git does not allow empty folders.
