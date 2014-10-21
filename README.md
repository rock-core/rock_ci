This is a collection of script that can be used to automate Rock builds and
associated tasks. It is meant for continuous integration in e.g. Jenkins

Configuration variables
-----------------------
This is a list of the available variables that can be set to affect the behaviour
of the CI scripts. They can either be passed as environment variables (e.g. by
adding them as parameters to a Jenkins build) or set within the .config configuration
file (see the ROCK_CI_CONFIG_NAME variable below)

__ROCK_CI_CONFIG_NAME__: the name of the files to look for when loading
configuration (see also ROCK_CI_CONFIG_DIR below). The CI scripts load two
configuration files. The $ROCK_CI_CONFIG_NAME.config file is a shell script that
is sourced at the top of each CI script and in which configuration variables can
be set (among other things). $ROCK_CI_CONFIG_NAME.yml is the autoproj
configuration file that is going to be installed as autoproj/config.yml in the
bootstrapped autoproj environment. If either files cannot be found, the
corresponding default config is searched as well. The default config name is
obtained by replacing the part before the first dash by "default". For instance
rock-master becomes default-master. It is customary to use
job_name-matrix_variables in matrix builds as the configuration name.

__ROCK_CI_CONFIG_DIR__: directory where configuration files are stored. For each
given config name (see CONFIG_NAME below), a $CONFIG_NAME.config file is sourced
at the beginning of this shell script if it exists, and a $CONFIG_NAME.yml file
is used as the autoproj configuration file. It defaults to the conf/
subdirectory of this repository.

__ROCK_CI_BOOTSTRAP_URL__: path to the autoproj bootstrap script to run (defaults to
rock-robotics.org/stable/autoproj_bootstrap)

__ROCK_CI_RUBY__: full path to the ruby executable to use (defaults to the
system's ruby 1.9.3 binary)

__ROCK_CI_GEM__: full path to the gem executable to use (defaults to the gem
binary for ruby 1.9.3)

__ROCK_CI_AUTOPROJ_OSDEPS_MODE__: the mode in which to run the autoproj subsystem
(defaults to 'all')

__ROCK_CI_MODE__: in general, controls whether the CI operation should be done
from scratch or incrementally (when applicable). The exact behaviours and
choices is dependent on the exact script being executed:

__ROCK_CI_AUTOPROJ_OPTIONS__: additional options that should be passed to autoproj (e.g. -k or -p)

_for rock-ci-cache_:
```
ROCK_CI_MODE:
    full: delete the current cache and start caching
    incremental: update the current cache if there is one, and create one if it does not (default)
```

_for rock-ci-build_:
```
ROCK_CI_MODE:
    full-bootstrap: remove the complete dev/ directory and bootstrap fresh
    bootstrap: keep the currently checked out code in dev/. Just delete all
               build byproducts, gems and autoproj configuration
    incremental: builds from the current state of dev/. If the build has
                 been cleaned last time, the job is ignored
    auto: do a bootstrap if the last buil was successful and otherwise do an
          incremental build (default)
```

Setting up the autobuild cache
------------------------------
An autobuild cache can be setup and used by
 - set the ROCK_CI_AUTOBUILD_CACHE_DIR environment variable to the full path to the
   cache directory. This directory should ideally be accessible in all build
   nodes.
 - having a job run the rock-ci-cache script. The script expects, as arguments,
   the bootstrap configuration that should be cached. Note that it attempts to
   cache all packages that are defined, not only the ones that are selected in
   the manifest. For instance,

    rock-ci-cache git https://github.com/rock-core/buildconf-all.git
 - one can run multiple jobs with multiple configuration that share the same cache directory, simply not in parallel
