# ServiceMeshControl

This repository contains scripts to run experiments on the servicemesh environment in `ServiceMesh` using methods in `ServiceMeshLearning`.

## Usage

To use the package as a whole just clone the git repository and from the base of the repository run
```julia
julia --project 
```
which opens a REPL with the environment defined in the repository. If this is the first time you might need to instantiate the environment to make sure all packages of the correct version are downloaded, in the REPL write
```julia
julia> ]instantiate
```

### Adding add a package
To only use the packages supplied in the repo, if you for example want to run something with the `ServiceMesh` RL-environment, you can add that to your own project by running
```julia
julia> ]add https://github.com/albheim/ServiceMeshControl:ServiceMesh
```
and you will have only the `ServiceMesh` package added.

## Visualization

Running either `hyperopt.jl` or `compare_algs.jl` with `logging=true` will log environment data to a tensorboard file. This can then either be visualized using tensorboard, or the scripts in the `plotting` folder can be used to generate plots of the data.

## Typical workflow
Find environment settings you like and enter them into `ServiceMeshLearning/src/env.jl`, or use one of the already defined ones there. 

Setup your cluster as in the start of `hyperopt.jl`, but you need to provide ips to the machines you want to use. If you just want to run locally on your machine you can simply replace the `@initcluster ...` with `addprocs(N)` where `N` is the number of local workers you want.
Run `julia --project hyperopt.jl`.

Run the hyperparameter optimization, and save the optimal parameter setting.

Copy the parameters into the `compare_algs.jl` file, only the optimized ones.

Run `julia --project compare_algs.jl`.

Visualize the results using either tensorboard or the scripts in the `plotting` folder.