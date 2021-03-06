# Kubert - Your helpful kubernetes ruby terminal friend!

## The gem relies on a second gem, [ky](https://github.com/stellaservice/ky), though the two may also be used independently, other than a shared config file.

Install gem via `gem install kubert` as usual.  This will also install the ky gem, which handles configuration and manages environments and DRYing yaml for deployments.  (If anyone wanted to provide similar interoperability with [helm](http://helm.sh) that would be awesome, we might prefer using that as the more standard solution but we use ky for now for various interoperabiltiy related reasons.)

Kubert assumes your kubernetes config file lives in `~/.kube/config` and reads that to talk to the cluster.

Compile and Rollback actions are only available if using ky for generating your deployment yml.  Kubert checks the ky config for several values (procfile_path, deployment and image at present) to determine if ky is active and only defines compile/rollback commands if they are all configured.

ky manages the scope of a deployment as a group of related, seperate kubernetes deployments.  Typing `ky example` at the console will import example ky configuration, including kubert configuration.  You may ignore/delete most of this if not using ky itself, and focus primarily on the kubert section of the yml for a few pieces of kubert configuration...  the important ones are these:

```
environments: [dev, stg, prd]
secret_path: "deploy/my-project.secret.yml"
config_path: "deploy/my-project.configmap.yml"
project_name: "my-project"
kubert:
  contexts:
    staging: staging.example.com                  # as many values here as you have distinct clusters in kubeconfig
    prod: production.example.com
  excluded_deployments: [sanitize,migration]      # optional/possibly uncommon use case, see below
  default_environment: stg
  default_namespace: default                      # defaults to same as default_environment, specify if different
  task_pod: console                               # deployment id (from Procfile) for tasks/console, selected at random if blank
  console_command: rails c                        # optional, but no console command unless present
  command_prefix: bundle exec                     # optional
  kube_config_path: ~/.kube/config                # No need to specify unless you store file elsewhere
  s3_secret_path: s3://my-bucket/environments/    # If defined, must manually install aws-sdk gem and have credentials for bucket as defaults (for now)
  s3_config_path: s3://my-bucket/environments     # Ditto, with or w/o trailing slash, less likely as could be checked in but supporting for symmetry
```

project_name is used by ky and assumes a metadata namespace for your app deployments in the format of `{{project_name}}-{{deployment_name}}`, so as long as your deployments obey this pattern it should be usable for you without ky.

environments defines valid environments with overrideable configuration located in the same directory as ky config with names like `stg.yml`

secret_path and config_path will likely NOT be defined in your global ky configuration as above but in environment specific files... ky assumes one such file per environment listed in the environments config, and merges any keys defined in those files (under a configuration key) as overrides of the global ky config, but perhaps in this example dev and stg share configmap and secret so only prd needs to override these

contexts is used to create convenience functions for switching between different clusters defined in the same kubeconfig file, i.e. `kubert staging` with above config will switch/ensure your config is using staging.example.com

excluded_deployments says not to deploy the following deployments defined in your Procfile during a normal deployment, and not to rollback during a rollback.

default_environment and/or default_namespace are optional but effect pod selection if no task_pod is defined, and effect default target environment for deployment and rollback if not specified via CLI flags.

Task pod is what is used for running consoles and executing tasks.  If not defined it selects a random pod and uses that pod's type, though it is splitting on dashes so may not work if your pod type has dashes in its deployment name at present.

console_command and console_prefix are for opening a REPL and for prefixing all task commands with a common prefix

kube_config_path is probably not needed unless your kubernetes config is located elsewhere

s3_secret_path and s3_config_path tell kubert not to use the locally configured ky build path, but to read and write either/both values to a an s3 bucket
The value provided must begin with s3:// and provide bucket name and path to a folder in bucket containing one folder per environment, i.e. for
example above s3://my-bucket/environments/stg/my-project.secret.yml and s3://my-bucket/environments/stg/my-project.configmap.yml

Kubert will also download from these locations when deploying to kubernetes, and then delete when done to avoid confusion/leaking data, if specified.

### Example usage
```
$ kubert console                        # open a console on a task_pod
$ kubert execute rake db:migrate        # run a migration
$ kubert list web                       # list all running web pods
$ kubert sandbox                        # only if rails c/rails console is console_command above, opens console wrapped in DB transaction
$ kubert context                        # print current kubectl context/cluster
$ kubert deploy -e prd                  # perform a production deployment
$ kubert rollback -e prd                # rollback a production deployment
$ kubert deploy                         # perform a deployment to the default environment
$ kubert logs web                       # tail the logs from all web pods and interleave together
$ kubert env all                        # print all secret/configmap values, with secrets sanitized showing last 4 characters
$ kubert env all --cleartext-secrets    # print all secret/configmap values, with secrets fully visible
$ kubert env get secret-or-config-key   # print one env value defined in configmap or secrets for default environment
$ kubert env set key value              # update one env key/value defined in configmap or secrets for default environment
$ kubert env set key value -s           # create new env key/value defined in secrets for default environment
$ kubert env set key value -c           # create new env key/value defined in configmap for default environment
$ kubert env unset key                  # remove an env key/value defined in configmap or secrets for default environment
```
