# Installation

We used an Ubuntu 18.04 OS and CUDA 11.4 system. Installation may vary based on CUDA and OS.

There are two methods to install CircleSnake:
- From source
- From Docker

## Source
### Set up the Python environment
0. Install [mamba](https://mamba.readthedocs.io/en/latest/installation.html) (faster) or [conda](https://docs.conda.io/en/latest/miniconda.html)
```
conda env create -f environment.yml
conda activate CircleSnake
```


### Compile cuda extensions under `lib/csrc`

```
export ROOT=/path/to/snake
cd $ROOT/lib/csrc

# Export CUDA_HOME based on your CUDA version
# example: export CUDA_HOME="/usr/local/cuda-11.4"

cd dcn_v2/
python setup.py build_ext --inplace
cd ../extreme_utils
python setup.py build_ext --inplace
cd ../roi_align_layer
python setup.py build_ext --inplace
```

## Docker
```
docker run -it --gpus all bluenotebook/circlesnake
```