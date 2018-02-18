from io import open
from yaml import load
from os import (listdir, path)
from subprocess import check_output as call


def get_immediate_subdirectories(a_dir):
    return [name for name in listdir(a_dir)
            if path.isdir(path.join(a_dir, name))]


class galaxy_to_submodule(object):
    def __init__(self, roles_requirements_filepath='roles/roles_requirements.yml'):
        self.roles_requirements_filepath = roles_requirements_filepath
        file_handler = open(self.roles_requirements_filepath, 'r')
        galaxy_roles = ''
        for line in file_handler.readlines():
            galaxy_roles += line
        file_handler.close()
        self.galaxy_roles = load(galaxy_roles)

    def remove_all_submodules(self):
        call(['git', 'submodule', 'deinit', '--force', '--all'])
        submodules_status = call(['git', 'submodule', 'status'])
        # if not empty
        if submodules_status.count('\n') != 0:
            submodules_status = submodules_status.split('\n')
            del submodules_status[-1]
            for submodule_status in submodules_status:
                a, submodule_path = submodule_status.split(' ')
                call(['git', 'rm', '--force', submodule_path])

    def add_all_submodules(self):
        parent_git_url_prefix, parent_git_url_subfolder = call(
            ['git', 'remote', 'get-url', 'origin']).replace('\n', '').split(':')
        parent_git_subfolder_depth = parent_git_url_subfolder.count('/') + 1
        relative_git_path_prefix = ''
        for i in range(0, parent_git_subfolder_depth):
            relative_git_path_prefix += "../"
        for role in self.galaxy_roles:
            call(['git', 'submodule', 'add', '--force', '-b',
                  role['version'], role['src']], cwd='roles/external')
        for role in get_immediate_subdirectories('roles/external'):
            # GitLab workaroung, modules need to have relative path in order for the runner to pull them. Otherwise they don't have the access tocken embedded.
            config_node = 'submodule.roles/external/REPOSITORY.url'.replace(
                'REPOSITORY', role)
            role_url = call(
                ['git', 'config', '-f', '.gitmodules', config_node]).replace('\n', '')
            role_url = role_url.replace(
                parent_git_url_prefix + ":", relative_git_path_prefix)
            call(['git', 'config', '-f', '.gitmodules', config_node, role_url])
        call(['git', 'submodule', 'sync', '--recursive'])
        call(['git', 'submodule', 'update', '--init',
              '--remote', '--force', '--recursive'])
        call(['git', 'add', '.gitmodules'])


if __name__ == '__main__':
    gts = galaxy_to_submodule()
    gts.remove_all_submodules()
    gts.add_all_submodules()
