# ServiceMeshControl

This repository contains scripts to run experiments on the servicemesh environment in `ServiceMesh` using methods in `ServiceMeshLearning`.

# Usage

To use the package as a whole just clone the git repository and from the base of the repository run
```julia
julia --project 
```
which opens a REPL with the environment defined in the repository. If this is the first time you might need to instantiate the environment to make sure all packages of the correct version are downloaded, in the REPL write
```julia
julia> ]instantiate
```

## Adding add a package
To only use the packages supplied in the repo, if you for example want to run something with the `ServiceMesh` RL-environment, you can add that to your own project by running
```julia
julia> ]add https://github.com/albheim/ServiceMeshControl:ServiceMesh
```
and you will have only the `ServiceMesh` package added.