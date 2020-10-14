# Azure DevOps PowerShell Pipelines

These pipelines will help you build, test and publish your PowerShell scripts and modules, without the hassle of maintaining a nuspec manifest. As it's using _[Bca.Nuget](https://github.com/baptistecabrera/bca-nuget)_, the nuspec will be auto-genrated at build time, all you have to do is maintain your module or script info.

It's a lighter version of what I use for all my project, but it's totally self-contained and can be used as-is or as a YAML template, as everything can be handled with parameters.

## Why use this?

- It does everything you need for PowerShell projects;
- You don't have to maintain a nuspec, everything is sourced from your module or script info;
- You can use it as-is or as a YAML template;
- Everything is managed by parameters and it's multi-stage, so if you want to run it manually and override options or run just a portion, you can;
- All you need is (everything is available with a free Azure DevOps plan):
  - Your sources with a [module manifest](https://docs.microsoft.com/en-us/powershell/scripting/developer/module/how-to-write-a-powershell-module-manifest) of [script info](https://docs.microsoft.com/en-us/powershell/module/powershellget/new-scriptfileinfo) that will be used to generate the [nuspec manifest](https://docs.microsoft.com/en-us/nuget/reference/nuspec);
  - A PowerShell Gallery account and API key ([this post](https://blog.ipswitch.com/how-to-publish-scripts-to-the-powershell-gallery) explains it pretty well);
  - A secret variable to store your API key (see [PowerShell Gallery API Key](#powershell-gallery-api-key) under [Variables](#variables) below).
  - An existing or new [Azure DevOps Artifacts feed](https://docs.microsoft.com/en-us/azure/devops/artifacts/tutorials/private-powershell-library?view=azure-devops#create-the-feed) (make sure your build service has at least contributor permissions).

## What does it do?

### Build

The build pipeline is broken down in 4 stages:
- **Initialization**:
  - retrieves the version (from script or module info);
  - checks if a version of this package already exist in the feed;
  - updates the build number.
- **Test** (by default will perform these actions on Windows, Linux and MacOS):
  - runs _[PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer)_;
  - installs dependencies if any;
  - runs _[Pester](https://github.com/pester/Pester)_ tests, if any, and code coverage;
  - publishes tests and coverage results.
- **Build**:
  - copies sources to staging;
  - installs _[Bca.Nuget](https://github.com/baptistecabrera/bca-nuget)_;
  - installs dependencies if any;
  - updates the module manifest (if applicable);
  - creates the nuspec manifest;
  - publishes pipeline artifacts.
- **Package**
  - downloads the pipeline artifacts;
  - packs the nuspec;
  - pushes the package to a personal feed.

### Release

The release pipeline is broken down in 3 stages:
- **Initialization**:
  - retrieves the version (from script or module info for the last published build artifacts);
  - updates the release number.
- **Test** (by default will perform these actions on Windows, Linux and MacOS):
  - installs the package from the personal feed;
  - runs _[Pester](https://github.com/pester/Pester)_ tests, if any, and code coverage;
  - publishes tests and coverage results.
- **Publish**:
  - installs the package from the personal feed;
  - publishes the module or script to the _[PowerShell Gallery](https://www.powershellgallery.com)_.

## How to use it

This will describe how to use as an independant pipeline, but you can refer to [this](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/templates?view=azure-devops) to use it as a YAML template, and specifically [this](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/templates?view=azure-devops#use-other-repositories) if you want to store it on another repo.

### Creating the pipelines
- In a branch of your choice (preferably a feature `branch`), copy both YAML pipeline files in a folder (preferably under `.azuredevops/pipelines`), then commit and push your changes;
- In Azure DevOps:
  - go to **Pipelines** and click the button **New pipeline**;
  - select your repo type and repo, choose **Existing Azure Pipelines YAML file**, and select the branch and path of the pipeline;
  - click the down arrow of the **Run** button, and select **Save** (you can choose to move/rename it afterwards);
  - repeat steps for the second pipeline.

### Editing the pipelines

#### Parameters

| Parameter          | Type    | Description                                                         | Build              | Release            |
| ------------------ | ------- | ------------------------------------------------------------------- | :----------------: | :----------------: |
| `psName`           | string  | Name of the module or script                                        | :heavy_check_mark: | :heavy_check_mark: |
| `psType`           | string  | Type of PowerShell (`Module` or `Script`)                           | :heavy_check_mark: | :heavy_check_mark: |
| `sourceDirectory`  | string  | Directory containing the sources                                    | :heavy_check_mark: |                    |
| `nugetName`        | string  | Name of the NuGet package                                           | :heavy_check_mark: | :heavy_check_mark: |
| `nugetFeed`        | string  | Name of the NuGet feed                                              | :heavy_check_mark: | :heavy_check_mark: |
| `nugetFeedUrl`     | string  | URL of the NuGet feed                                               |                    | :heavy_check_mark: |
| `nugetPush`        | boolean | Specify if package will be pushed to personel NuGet feed            | :heavy_check_mark: |                    |
| `psGalPub`         | boolean | Specify if script/module will be published to PowerShell Gallery    |                    | :heavy_check_mark: |
| `runAnalyzer`      | boolean | Specify if PSScriptAnalyzer will run                                | :heavy_check_mark: |                    |
| `analyzerSeverity` | string  | PSScriptAnalyzer severuty (`Information`, `Warning`, `Error`)       | :heavy_check_mark: |                    |
| `testWindows`      | boolean | Specify if the code will be tested on Windows                       | :heavy_check_mark: | :heavy_check_mark: |
| `testLinux`        | boolean | Specify if the code will be tested on Linux                         | :heavy_check_mark: | :heavy_check_mark: |
| `testMacOS`        | boolean | Specify if the code will be tested on MacOS                         | :heavy_check_mark: | :heavy_check_mark: |
| `includeTags`      | string  | Tags to filter for Pester tests (comma separated)                   | :heavy_check_mark: | :heavy_check_mark: |
| `excludeTags`      | string  | Tags to exclude for Pester tests (comma separated)                  | :heavy_check_mark: | :heavy_check_mark: |
| `coveragePath`     | string  | Path to the sources where coverage will be analyzed                 | :heavy_check_mark: | :heavy_check_mark: |

#### Triggers

By default the build pipeline will be triggered by any change on branches `master` or `develop`, but you can change this settings by editing the trigger (or by [using the skip CI tags in your commit message](https://docs.microsoft.com/en-us/azure/devops/pipelines/repos/azure-repos-git?view=azure-devops&tabs=yaml#skipping-ci-for-individual-commits)):
```yml
trigger:
  branches:
    include:
    - develop
    - master
  paths:
    exclude:
    - .azuredevops/**
    - .github/**
```

The release pipeline will be triggered by a completed build, but you have to edit the path to the build pipeline (not to the file) in the `resources` section:
```yml
# Fill in the build pipeline path in 'source'
resources:
  pipelines:
  - pipeline: Build
    source: path\to\build-piepeline
    trigger: 
      branches:
      - master
```

#### Variables

##### Agents

Both pipelines use an agent pool and different VM iamges for testing on different OS:
```yml
variables:
- name: poolName
  value: 'Azure Pipelines'
- name: vmImageWindows
  value: 'windows-latest'
- name: vmImageLinux
  value: 'ubuntu-latest'
- name: vmImageMacOS
  value: 'macOS-latest'
```

##### PowerShell Gallery API Key

The release pipeline uses a PowerShell API key to publish your script or module.

To store the PowerShell Gallery API key, you will need a secret variable.

I personally use a [variable group with secrets variables](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/variable-groups?view=azure-devops&tabs=classic) (to be able to share it between pipelines), but you can either [set a pipeline secret variable](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/variables?view=azure-devops&tabs=yaml%2Cbatch#secret-variables) or [use a variable from Azure key vault](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/variable-groups?view=azure-devops&tabs=yaml#link-secrets-from-an-azure-key-vault).

For instance, if your variable group is named `MySecretVariableGroup`, and your variable `MyPSGalleryApiKey`:
```yml
variables:
- group: MySecretVariableGroup
- name: psGalApiKey
  value: $(MyPSGalleryApiKey)
```

:warning: If you don't use a variable group, remove the line importing it.

:warning: Do not rename the variable `psGalApiKey` (or you will have to change it inside the pipeline code as well).