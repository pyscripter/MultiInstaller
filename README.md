# MultiInstaller

This is the [Silverpoint MultiInstaller](http://www.silverpointdevelopment.com/multiinstaller/index.htm) on steroids.
It allows you to install multiple Delpi packages directly from git repositories (e.g. Github), from zip files or 
from existing folders in one-step.

**Documentation**  
Please read the  [orginal documentation](http://www.silverpointdevelopment.com/multiinstaller/index.htm) in conjuction
with the notes below.

**List of enhanacements to the original program:**
* *GIT* key  
    Example: Git=https://github.com/pyscripter/python4delphi.git  
    If the GIT key is provided Multiinstaller clones the repository.  GIT.exe must be on the Windows path.
* If you already have the sources of a component in-place you can omit both the "*Zip*" and "*Git*" keys.  The component 
  will be installed from the existing sources.
* *LIBSUFFIX* key   
  Example: LIBSUFFIX=%s0    
  Actual LibSuffix will be assumed to be the result of Format(LibSuffix, [DelphiIDEVersion] so if you install into 
  Delphi Tokyo the LibSuffix will become 250.  Athough MultiInstaller has auto-detection of the LIBSUFFIX directive
  this fails when this is inside conditional directives.
* Automatic generation of .res package files if they are missing.  Empty.res needs to be present in the same 
  directory as the MultiInstaller executable.
* *SearchPath* folders are also added to the Win64 Library search path.
* The Delphi search path (-U dcc32 flag) is also used as the include search path (-I dcc32 flag) during package compilation.

**Example Setup.ini:**
*  See [PyScripter's Setup.ini](https://github.com/pyscripter/pyscripter/blob/master/Components/ThirdParty/Setup.ini).