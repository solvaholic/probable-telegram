**_File Puller_** is a GitHub Action to enable syncing selected files from other repositories.

> Thank you for reading this document!
> 
> While recklessly typing away trying to make some progress on this 
> Action I realized: I'm making a LOT of assumptions!
> 
> To help myself keep track of those, to make them available for you,
> and to create an opportunity for you to change my mind, I've organized
> my expectations and assumptions here.
> 
> If you have any feedback at all, please update or create an issue to
> share it.
> 
> Thanks again!
> 
> @solvaholic

General requirements:

- Core functionality can pull from public repositories with permissions provided by `${{ github.token }}`  
- Core functionality runs directly on a GitHub-hosted, Linux-based runner
- Core functionality can also be run locally or in other CI

Core functionality:

- Given a configuration file describing one or more combinations of **destination path**, **source repository**, and **source path**,
- copy **source path** from **source repository** to **destination path** in local repository,
- apply optionally provided **transforms**, and
- commit and push those changes
- Then update or create a pull request with a summary of changes applied
- Optionally provided **transforms** specify changes to the **destination path**

Assumptions:

- If core functionality runs on a GitHub-hosted, Linux-based runner then it runs in any general-purpose Linux Docker container, provided prerequisite tools are available
- Each **destination path** is unique
- A transform will have a prescribed syntax, for example to be used by `awk`, `sed`, or `patch`
- It's reasonable to expect a contributor to use `docker`, `git`, `gh`, `sed`, `awk`, and `patch`
- It's OK to have the user clone the destination repo, in the workflow job

<!--

Initial vision, from #1:

> There are things I'd like to share between some repositories. For example GitHub Pages assets and configurations, GitHub Actions workflows, Makefiles, and scripts. If they all go in the template, then the I think template feels kindof overdone.
> 
> However, even if you like the idea of centrally managing all those things in template, I still want a way to do the other thing: Sync selected files from other repositories.

-->
