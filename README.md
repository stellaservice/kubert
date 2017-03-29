# Kubert - Your helpful kubernetes ruby terminal friend!

## The gem relies on a second gem, [ky](https://github.com/stellaservice/ky) which may be used independently

# Install gem via `gem install kubert` as usual.  This will also install the ky gem, which handles configuration.

Kubert assumes your kubernetes config file lives in `~/.kube/config` and reads that to talk to the cluster.

Compile and Rollback actions are only available if using ky for generating your deployment yml.  Kubert checks the ky config for several values (procfile_path, deployment and image at present) to determine if ky is active and only defines compile/rollback commands if they are all configured.

ky manages the scope of a deployment as a group of related, seperate kubernetes deployments.  Typing `ky example` at the console will import example ky configuration, including kubert configuration.  You may ignore/delete most of this if not using ky itself, and focus primarily on the kubert section of the yml for a few pieces of kubert configuration...  the important ones are these:

```
project_name: "my-project"
kubert:
  contexts:
    staging: staging.example.com   # as many values here as you have distinct clusters in kubeconfig
    prod: production.example.com
  excluded_deployments: [sanitize, migration] # optional/possibly uncommon use case, see below
  default_environment: stg
  default_namespace: default       # defaults to same as default_environment, specify if different
  task_pod: console
  console_command: rails c         # optional, but no console command unless present
  command_prefix: bundle exec      # optional
  kube_config_path: ~/.kube/config # No need to specify unless you store file elsewhere
```

The project name is used by ky and assumes a metadata namespace for your app deployments in the format of `{{project_name}}-{{deployment_name}}`, so as long as your deployments obey this pattern it should be usable for you without ky.
contexts is used to create convenience functions for switching between different clusters defined in the same kubeconfig file, i.e. `kubert staging` with above config will switch/ensure your config is using staging.example.com

excluded_deployments says not to deploy the following deployments defined in your Procfile during a normal deployment, and not to rollback during a rollback.

default_environment and/or default_namespace are optional but effect pod selection if no task_pod is defined, and effect default target environment for deployment and rollback if not specified via CLI flags.

Task pod is what is used for running consoles and executing tasks.  If not defined it selects a random pod and uses that pod's type, though it is splitting on dashes so may not work if your pod type has dashes in its deployment name at present.

console_command and console_prefix are for opening a REPL and for prefixing all task commands with a common prefix

kube_config_path is probably not needed unless your kubernetes config is located elsewhere

###Example usage
```
$ kubert console                  # open a console on a task_pod
$ kubert execute rake db:migrate  # run a migration
$ kubert list web                 # list all running web pods
$ kubert sandbox                  # only if rails c/rails console is console_command above, opens console wrapped in DB transaction
$ kubert context                  # print current kubectl context/cluster
$ kubert deploy -e prd            # perform a production deployment
$ kubert rollback -e prd          # rollback a production deployment
$ kubert deploy                   # perform a deployment to the default environment
$ kubert logs web                 # tail the logs from all web pods and interleave together
```

A valid url may also be used in place of a file path for input.