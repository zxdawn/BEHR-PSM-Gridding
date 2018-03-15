# BEHR PSM Gridding

This repository contains a modified version of the omi gridding package 
(https://github.com/gkuhl/omi) that works with BEHR data, as well as the
interface code to let it be called directly from the Matlab side of BEHR.

## A note on the no-he5 branch

Like the other BEHR repositories, we will follow the Git Flow paradigm
(http://nvie.com/posts/a-successful-git-branching-model/) here. This means
that the `master` branch should always be the "production" code (that is 
used to produce the published BEHR data) and `develop` is the branch that
is actively changing. 

In this repo, we essentially have two "master" branches: `master` itself and
`no-he5`. `no-he5` is a version with all of the omi package code dealing with
reading and saving HDF5 files removed, which eliminates the need to have the
Python h5py package installed.

To keep the branching model somewhat simple, the `develop` branch will be based
off `master`, meaning that it will include the HDF5 code. Then, when ready to 
deploy new code to `master`, first, any changes (from a release or hotfix branch)
into `master`, then merge from `master` into `no-he5`, taking care to remove any
references to HDF5 read/write code.

## A note on h5py

Matlab bundles its own version of HDF5 (1.8.12 as of Matlab 2017b) and Strange Things can happen if h5py is using a different HDF5 library. Unfortunately 1.8.12 is one of the HDF5 versions that isn't available in the default conda channel. So, we need to setup h5py based on hdf=1.8.12.

Download [the HDF5 source (1.8.12)](https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.12/bin/linux-x86_64/) and configure it;

```
./configure --prefix=/path/to/hdf5
make
make install
```

Build h5py against this version of HDF5.

```
python setup.py configure --hdf5=/path/to/hdf5
python setup.py install
```

This works for Python 3 with gcc only.