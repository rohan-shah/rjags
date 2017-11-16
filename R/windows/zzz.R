.check.jags.home <- function(jags.home, major)
{
    ## Check that folder jags.home actually exists and contains the DLL
    ## in the appropriate sub-folder.
    
    ## Registry entries created by the JAGS instsaller may be invalid
    ## if the user removes JAGS by manually deleting files rather than
    ## using the uninstaller. So this function is used to check that
    ## the installation still exists.
    
    if (is.null(jags.home)) return(FALSE)
    if (!is.vector(jags.home, mode="character") || length(jags.home) != 1) {
        return(FALSE)
    }
    if (!file_test("-d", jags.home)) return(FALSE)

    bindir <- file.path(jags.home, "libs", "x64")
    jags.dll <- file.path(bindir, paste("rJags", .Platform$dynlib.ext, sep=""))
    return(file.exists(jags.dll))
}


.onLoad <- function(lib, pkg)
{
### First task is to get installation directory of JAGS

    ## Major version of JAGS library should match major version
    ## of the rjags package
    jags.major <- packageVersion(pkg, lib)$major

    ## Try environment variable first
    jags.home <- system.file(package="rjags")
    if (!.check.jags.home(jags.home, jags.major)) {
        stop("The environment variable JAGS_HOME is set to\n", jags.home,
             "\nbut no JAGS installation can be found there\n")
    }

### Load the rjags dll
    library.dynam("rjags", pkg, lib)

### Set the module directory, if the option jags.moddir is not already set
    
    if (is.null(getOption("jags.moddir"))) {
        options("jags.moddir" = file.path(jags.home, "libs", "x64"))
    }

### Check that the module directory actually exists
    moddir <- getOption("jags.moddir")
    if (!file.exists(moddir)) {
        stop(moddir, " not found\n\n",
             "rjags is looking for the JAGS modules in\n", moddir,
             "\nbut this folder does not exist\n")
    }
    load.module("base", quiet=TRUE)
    wd <- getwd()
    setwd(moddir)
    load.module("bugs", quiet=TRUE)
    setwd(wd)

### Set progress bar type
    
    if (is.null(getOption("jags.pb"))) {
        options("jags.pb"="text")
    }
}

.onAttach <- function(lib, pkg)
{
    packageStartupMessage("Linked to JAGS ",
                          .Call("get_version", PACKAGE="rjags"))
    packageStartupMessage("Loaded modules: ",
                          paste(list.modules(), collapse=","))
}


.onUnload <- function(libpath)
{
    library.dynam.unload("rjags", libpath)
}
