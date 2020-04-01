# pyreadr_wheels

This is a modification of 
[multibuild](https://github.com/matthew-brett/multibuild/tree/005ace6325a4eff7f2cc9d09e5f8d1da134be40d)
to build many-linux and macos wheels for pyreadr on travis-ci and appveyor.

Not all enviroments compiled (for instance python 2.7 does not work, 32 bit doesn't work on appveyor), 
so in the yaml I only kept those that were OK.

It was setup following the instructions on the multibuild README in the
section "How to use these scripts".

The difference with the original version of multibuild is that this one
deploys the wheels to Anaconda Cloud instaead of Rackspace as the former is going to dissapear.

In order to do that a anaconda cloud account had to be set and the token retrived via WEB UI (also possible with CLI), set the Token in Travis and APPVEYOR as secret environment variable for the project, and then just upload the wheels using the Anaconda-client in .travis.yml and appveyor.yml. Interestingly as we are using plain python and not anaconda in both appveyour and travis, I had to install Anaconda-cli from github as the pypi version was too old and was causing errors.

The wheels are then visible in https://anaconda.org/ofajardo/pyreadr


In the past wheels were written back to this github repo instead. In
order to do that, the custom bash push.sh script was written (instead of using
the built in travis -ci deploy method, I just could not get it to work
properly in a reasonable amount of time). This idea comes from 
[this post](https://www.vinaygopinath.me/blog/tech/commit-to-master-branch-on-github-using-travis-ci/)
(personal notes: on the metioned post, key ideas: encrypt your github
token with the travis client as described 
[here](https://docs.travis-ci.com/user/environment-variables#Defining-Variables-in-Repository-Settings) 
(but in addition don't forget to do login with the --org flag
and also use --org flag when encrypting, otherwise you will get an error
not enough privileges or something like that because it wants you to use 
the --pro flag which is only for paid accounts), also use the message 
-m "[skip ci]" when commiting in order not to trigger a travis build, 
otherwise the push will trigger a build and will go into an infinite loop. 
This approach works well in general, the only possible problem being if
two jobs finish at the very same time and try to commit and push at the
same time into github, a race problem arises.


**The rest of this documentation was copied and contain things that are
not relevant, but I keep it here for reference:**

########################################
Building and uploading pyreadr wheels
########################################

We automate wheel building using this custom github repository that builds on
the travis-ci OSX machines, travis-ci Linux machines, and the Appveyor VMs.

The travis-ci interface for the builds is
https://travis-ci.org/MacPython/pyreadr-wheels

Appveyor interface at
https://ci.appveyor.com/project/matthew-brett/pyreadr-wheels

The driving github repository is
https://github.com/MacPython/pyreadr-wheels

How it works
============

The wheel-building repository:

* does a fresh build of any required C / C++ libraries;
* builds a pyreadr wheel, linking against these fresh builds;
* processes the wheel using delocate_ (OSX) or auditwheel_ ``repair``
  (Manylinux1_).  ``delocate`` and ``auditwheel`` copy the required dynamic
  libraries into the wheel and relinks the extension modules against the
  copied libraries;
* uploads the built wheels to a Rackspace container kindly donated by Rackspace
  to scikit-learn.

The resulting wheels are therefore self-contained and do not need any external
dynamic libraries apart from those provided as standard by OSX / Linux as
defined by the manylinux1 standard.

The ``.travis.yml`` file in this repository has a line containing the API key
for the Rackspace container encrypted with an RSA key that is unique to the
repository - see https://docs.travis-ci.com/user/encryption-keys.  This
encrypted key gives the travis build permission to upload to the Rackspace
containers we use to house the uploads.

Triggering a build
==================

You will likely want to edit the ``.travis.yml`` and ``appveyor.yml`` files to
specify the ``BUILD_COMMIT`` before triggering a build - see below.

You will need write permission to the github repository to trigger new builds
on the travis-ci interface.  Contact us on the mailing list if you need this.

You can trigger a build by:

* making a commit to the `pyreadr-wheels` repository (e.g. with `git
  commit --allow-empty`); or
* clicking on the circular arrow icon towards the top right of the travis-ci
  page, to rerun the previous build.

In general, it is better to trigger a build with a commit, because this makes
a new set of build products and logs, keeping the old ones for reference.
Keeping the old build logs helps us keep track of previous problems and
successful builds.

Which pyreadr commit does the repository build?
==================================================

The ``pyreadr-wheels`` repository will build the commit specified in the
``BUILD_COMMIT`` at the top of the ``.travis.yml`` and ``appveyor.yml`` files.
This can be any naming of a commit, including branch name, tag name or commit
hash.

Note: when making a release, it's best to only push the commit (not the tag) of
the release to the ``pyreadr`` repo, then change ``BUILD_COMMIT`` to the
commit hash, and only after all wheel builds completed successfully push the
release tag to the repo.  This avoids having to move or delete the tag in case
of an unexpected build/test issue.

Uploading the built wheels to pypi
==================================

* release container visible at
  https://3f23b170c54c2533c070-1c8a9b3114517dc5fe17b7c3f8c63a43.ssl.cf2.rackcdn.com

Be careful, these links point to containers on a distributed content delivery
network.  It can take up to 15 minutes for the new wheel file to get updated
into the containers at the links above.

When the wheels are updated, you can download them to your machine manually,
and then upload them manually to pypi, or by using twine_.  You can also use a
script for doing this, housed at :
https://github.com/MacPython/terryfy/blob/master/wheel-uploader
When the wheels are updated, you can download them to your machine manually,
and then upload them manually to pypi, or by using twine_.  You can also use a
script for doing this, housed at :
https://github.com/MacPython/terryfy/blob/master/wheel-uploader

For the ``wheel-uploader`` script, you'll need twine and `beautiful soup 4
<bs4>`_.

You will typically have a directory on your machine where you store wheels,
called a `wheelhouse`.   The typical call for `wheel-uploader` would then
be something like::

    VERSION=0.2.0
    CDN_URL=https://3f23b170c54c2533c070-1c8a9b3114517dc5fe17b7c3f8c63a43.ssl.cf2.rackcdn.com
    wheel-uploader -u $CDN_URL -s -v -w ~/wheelhouse -t all pyreadr $VERSION

where:

* ``-u`` gives the URL from which to fetch the wheels, here the https address,
  for some extra security;
* ``-s`` causes twine to sign the wheels with your GPG key;
* ``-v`` means give verbose messages;
* ``-w ~/wheelhouse`` means download the wheels from to the local directory
  ``~/wheelhouse``.

``pyreadr`` is the root name of the wheel(s) to download / upload, and
``0.2.0`` is the version to download / upload.

In order to upload the wheels, you will need something like this
in your ``~/.pypirc`` file::

    [distutils]
    index-servers =
        pypi

    [pypi]
    username:your_user_name
    password:your_password

So, in this case, `wheel-uploader` will download all wheels starting with
`pyreadr-0.2.0-` from the URL in ``$CDN_URL`` above to ``~/wheelhouse``, then
upload them to PyPI.

Of course, you will need permissions to upload to PyPI, for this to work.

.. _manylinux1: https://www.python.org/dev/peps/pep-0513
.. _twine: https://pypi.python.org/pypi/twine
.. _bs4: https://pypi.python.org/pypi/beautifulsoup4
.. _delocate: https://pypi.python.org/pypi/delocate
.. _auditwheel: https://pypi.python.org/pypi/auditwheel
