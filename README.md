# ServiceMeshControl

This repository contains scripts to run experiments on the servicemesh environment defined in the folder `ServiceMesh` using methods defined in the `ServiceMeshLearning` folder.

## Usage

To use the package as a whole just clone the git repository. It has been tested with both Julia v1.6 and v1.7

To install all dependencies with correct version and from the base of the repository run
```
julia --project -e "import Pkg; Pkg.instantiate()"
```

The files used to run the experiments are `hyperopt.jl` and `compare_X.jl` where `X` is for single and double environment.
To run the hyperoptimization script you need to define a cluster to work on, follow the instructions in the comments in the file.
To run the comparison scripts run 
```julia
julia --project compare_X.jl
```
where `X` is replaced by the environment you want to run.

### Adding a package
The subfolders `ServiceMesh` and `ServiceMeshLearning` are created as their own julia packages, and can thus be added and used in other projects.

For example, to use the `ServiceMesh` RL-environment, you can add that to your own project by running
```julia
julia> ]add https://github.com/albheim/ServiceMeshControl:ServiceMesh
```
and you will have only the `ServiceMesh` package added.

## Visualization

Running either `hyperopt.jl` or `compare_X.jl` with `logging=true` will log environment data to a tensorboard file. This can then either be visualized using tensorboard, or the scripts in the `plotting` folder can be used to generate plots of the data.

To run tensorboard you need to install that and start it in the folder you logged the data to. This is by default a folder `servicemesh_results` in your home directory.

To use the scripts in the plotting folder you need to activate and instantiate that environment.
To activate and run the plotting script do
```
julia --project=plotting -e "imporg Pkg; Pkg.instantiate()"
julia --project=plotting plotting/plotting_pgf.jl
```