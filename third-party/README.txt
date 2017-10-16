
Directory third-party contains third-party components necessary for
elephant-wrapper to work. There are three components:

- 'Wapiti' and 'elephant' are stored as git submodules (see
  https://git-scm.com/book/en/v2/Git-Tools-Submodules,
  https://git-scm.com/docs/git-submodule). This is the recommended way
  to include dependency repositories, so that future bug fixes can be
  pulled into the dependent repository. Users can clone the dependent
  repository together with its dependencies: git --recursive <repo>

- 'elman' is not available as a git repository but only as a Mercurial
  repository (https://bitbucket.org/gchrupala/elman). While it seems
  possible to convert an hg repository into a git submodule (see
  https://stackoverflow.com/questions/9067283/is-there-a-way-to-use-a-mercurial-repository-as-git-submodule),
  this seems to require other software which might not be installed on
  the user's computer. This is why I cloned the hg repository and
  added it 'as is' to the git repo, in order to avoid technical issues
  for users when cloning the repo. I'm not sure whether the .hg
  directory should be included or not, currently it is.
