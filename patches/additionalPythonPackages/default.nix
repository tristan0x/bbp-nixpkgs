{ stdenv
, pythonPackages
, pkgs
}:


let 

	self = pythonPackages;

in 
 rec {



    # function able to gather recursively all the python dependencies of a nix python package
    # it returns the depenrencies as a list [ a b c ] 
    # used to generate module containing all the necessary python dependencies 
    gatherPythonRecDep  = x: let
                                isPythonModule = drv: if (drv.drvAttrs ? pythonPath) then true else false;
            
                                getPropDepNative = drv: if ( drv.drvAttrs ? propagatedNativeBuildInputs != null) 
                                                    then  drv.drvAttrs.propagatedNativeBuildInputs 
                                                    else [];
                                getPropDepTarget = drv: if ( drv.drvAttrs ? propagatedBuildInputs != null) 
                                                    then  drv.drvAttrs.propagatedBuildInputs 
                                                    else [];

                                getPropDep = drv: (getPropDepNative drv) ++ (getPropDepTarget drv);
 
            
                                recConcat = deps: if ( deps == [] ) then []
                                                  else [ (builtins.head deps) ] ++ (recConcat (getPropDep (builtins.head deps) ) ) 
                                                        ++ (recConcat (builtins.tail deps));

                                allRecDep = recConcat ( getPropDep x);

                                allPythonRecDep = builtins.filter isPythonModule allRecDep;

                            in  allPythonRecDep;


	future_0_16 = self.buildPythonPackage rec {
    	version = "v0.16.0";
	    name = "future-${version}";

	    src = pkgs.fetchurl {
    		url = "http://github.com/PythonCharmers/python-future/archive/${version}.tar.gz";
    		sha256 = "0dynw5hibdpykszpsyhyc966s6zshknrrp6hg4ldid9nph5zskch";
		};

	    propagatedBuildInputs = with self; stdenv.lib.optionals isPy26 [ importlib argparse ];
	    doCheck = false;

	};



	tqdm = 	pythonPackages.buildPythonPackage rec {
	    name = "tqdm-${version}";
	    version = "v4.10.0";

	    src = pkgs.fetchFromGitHub {
	        owner = "tqdm";
	        repo = "tqdm";
	        rev = "bbf08db39931fd6cdff5f8ab42e54148f8b4faa4";
	        sha256 = "08vfbc1x64mgsc9z1zxaq8gdnnvx2y29p91s6r9j1bg7g9vv6w33";

	    };

    	buildInputs = [ pythonPackages.coverage pythonPackages.flake8 pythonPackages.nose ];

	};


	nose_xunitmp = pythonPackages.buildPythonPackage rec {
			name = "nose_xunitmp-${version}";
			version = "0.4";

			src = pkgs.fetchurl {
			url = "https://pypi.python.org/packages/86/cc/ab61fd10d25d090e80326e84dcde8d6526c45265b4cee242db3f792da80f/nose_xunitmp-0.4.0.tar.gz";
			md5 = "c2d1854a9843d3171b42b64e66bbe54f";
			};

			buildInputs = with pythonPackages; [ nose ];

	}; 

	nose_testconfig = pythonPackages.buildPythonPackage rec {
			name = "nose_testconfig-${version}";
			version = "0.10";

			src = pkgs.fetchurl {
				url = "https://pypi.python.org/packages/a0/1a/9bb934f1274715083cfe8139d7af6fa78ca5437707781a1dcc39a21697b4/nose-testconfig-0.10.tar.gz";
				md5 = "2ff0a26ca9eab962940fa9b1b8e97995";
			};

			buildInputs = with pythonPackages; [ nose ];

	};           

  cython = pythonPackages.buildPythonPackage rec {
    name = "Cython-${version}";
    version = "0.25.2";

    src = pkgs.fetchurl {
      url = "https://pypi.io/packages/source/C/Cython/${name}.tar.gz";
      sha256 = "01h3lrf6d98j07iakifi81qjszh6faa37ibx7ylva1vsqbwx2hgi";
    };

    setupPyBuildFlags = ["--build-base=$out"];

    buildInputs = with pythonPackages; [ pkgs.pkgconfig ];

   };
    

  ordereddict = pythonPackages.buildPythonPackage rec {
    name = "ordereddict-1.1";

    src = pkgs.fetchurl {
      url = "http://pypi.python.org/packages/source/o/ordereddict/${name}.tar.gz";
      md5 = "a0ed854ee442051b249bfad0f638bbec";
    };

   };


  #backport from NixOS 16.09
  ipython = pythonPackages.buildPythonPackage rec {
    version = "5.2.1";
    name = "ipython-${version}";

    src = pkgs.fetchurl {
      url = "mirror://pypi/i/ipython/${name}.tar.gz";
      sha256 = "04dafc37c8876e10e797264302e4333dbcd2854ef6d16bb57cc12ce26515bfdb";
    };

    prePatch = stdenv.lib.optionalString stdenv.isDarwin ''
      substituteInPlace setup.py --replace "'gnureadline'" " "
    '';

    buildInputs = with self; [ nose pkgs.glibcLocales pygments ] ++ stdenv.lib.optionals isPy27 [mock];

    propagatedBuildInputs = with pythonPackages;
      [ 
      backports_shutil_get_terminal_size 
      decorator pickleshare prompt_toolkit
      simplegeneric traitlets requests2 pathlib2 pexpect
      pygments setuptools30
      ]
      ++ stdenv.lib.optionals stdenv.isDarwin [appnope];

    LC_ALL="en_US.UTF-8";

    doCheck = false; # Circular dependency with ipykernel

    checkPhase = ''
      nosetests
    '';

    passthru = {
        pythonDeps = (gatherPythonRecDep ipython);
    };

  };


  #  backport from NixOS 16.09
  jupyter_client = pythonPackages.buildPythonPackage rec {
    version = "4.4.0";
    name = "jupyter_client-${version}";

    src = pkgs.fetchFromGitHub {
      owner = "jupyter";
      repo = "jupyter_client";
      rev = "67cc27d5b4ef565a172057a0a9b76e350a19a134";
      sha256 = "1f71rwm6hfxl5hpjs5p562izgqpm6w92gk429pbayhjmlv901lwk";
    };

    buildInputs = with self; [ nose ];
    propagatedBuildInputs = with self; [traitlets jupyter_core pyzmq] ++ stdenv.lib.optional isPyPy py;

    checkPhase = ''
      nosetests -v
    '';

    # Circular dependency with ipykernel
    doCheck = false;

  };


  # backport from NixOS 16.09
  jupyter_core = pythonPackages.buildPythonPackage rec {
    version = "4.2.1";
    name = "jupyter_core-${version}";

    src = pkgs.fetchFromGitHub {
      owner = "jupyter";
      repo = "jupyter_core";
      rev = "f81f34068b5c38b452ab65837f6c5bd98c0bac41";
      sha256 = "0bn1k4gwp5kvwar6zd7yvqaji2n6bnx5ydczv4xqqywl0f34hmi7";
    };

    buildInputs = with self; [ pytest mock ];
    propagatedBuildInputs = with self; [ ipython traitlets];

    checkPhase = ''
      py.test
    '';

    # Several tests fail due to being in a chroot
    doCheck = false;
  };



  # backport from NixOS 16.09
  setuptools30 = stdenv.mkDerivation rec {
      pname = "setuptools";
      shortName = "${pname}-${version}";
      name = "${pythonPackages.python.libPrefix}-${shortName}";

      version = "30.2.0";

      src = pkgs.fetchurl {
        url = "mirror://pypi/${builtins.substring 0 1 pname}/${pname}/${shortName}.tar.gz";
        sha256 = "f865709919903e3399343c0b3c42f95e9aeddc41e38cfb334fb2bb5dfa384857";
      };

      buildInputs = [ pythonPackages.python pythonPackages.wrapPython ];
      doCheck = false;  # requires pytest
      installPhase = ''
          dst=$out/${pythonPackages.python.sitePackages}
          mkdir -p $dst
          export PYTHONPATH="$dst:$PYTHONPATH"
          ${pythonPackages.python.interpreter} setup.py install --prefix=$out
          wrapPythonPrograms
      '';

      pythonPath = [];
    };

  # Backport from NixOS 16.09
  prompt_toolkit = pythonPackages.buildPythonPackage rec {
    name = "prompt_toolkit-${version}";
    version = "1.0.9";

    src = pkgs.fetchurl {
      sha256 = "172r15k9kwdw2lnajvpz1632dd16nqz1kcal1p0lq5ywdarj6rfd";
      url = "mirror://pypi/p/prompt_toolkit/${name}.tar.gz";
    };
  #  checkPhase = ''
  #    rm prompt_toolkit/win32_types.py
  #    py.test -k 'not test_pathcompleter_can_expanduser'
  #  '';

    buildInputs = with self; [ pytest ];
    propagatedBuildInputs = with self; [ docopt six wcwidth pygments ];

  };


  # backport from NixOS 16.09
  backports_shutil_get_terminal_size = pythonPackages.buildPythonPackage rec {
    name = "backports.shutil_get_terminal_size-${version}";
    version = "1.0.0";

    src = pkgs.fetchurl {
      url = "mirror://pypi/b/backports.shutil_get_terminal_size/${name}.tar.gz";
      sha256 = "713e7a8228ae80341c70586d1cc0a8caa5207346927e23d09dcbcaf18eadec80";
    };

  };



  # backport from NixOS 16.09 
  traitlets = pythonPackages.buildPythonPackage rec {
    version = "4.3.1";
    name = "traitlets-${version}";

    src = pkgs.fetchurl {
      url = "mirror://pypi/t/traitlets/${name}.tar.gz";
      sha256 = "ba8c94323ccbe8fd792e45d8efe8c95d3e0744cc8c085295b607552ab573724c";
    };

    LC_ALL = "en_US.UTF-8";

    preConfigure = ''
        mkdir -p $out
    '';

    buildInputs = with pythonPackages; [ pkgs.glibcLocales pytest mock ];
    propagatedBuildInputs = with pythonPackages; [ipython_genutils decorator enum34];

    checkPhase = ''
      py.test $out
    '';

    };


  # backport from NixOS 16.09 
  ipython_genutils = pythonPackages.buildPythonPackage rec {
    version = "0.1.0";
    name = "ipython_genutils-${version}";

    src = pkgs.fetchurl {
      url = "mirror://pypi/i/ipython_genutils/${name}.tar.gz";
      sha256 = "3a0624a251a26463c9dfa0ffa635ec51c4265380980d9a50d65611c3c2bd82a6";
    };

    LC_ALL = "en_US.UTF-8";
    buildInputs = with self; [ nose pkgs.glibcLocales ];

    checkPhase = ''
      nosetests -v ipython_genutils/tests
    '';

   };

  # backport from NixOS 16.09

  pathlib2 = pythonPackages.buildPythonPackage rec {
    name = "pathlib2-${version}";
    version = "2.1.0";

    src = pkgs.fetchurl {
      url = "mirror://pypi/p/pathlib2/${name}.tar.gz";
      sha256 = "deb3a960c1d55868dfbcac98432358b92ba89d95029cddd4040db1f27405055c";
    };

    propagatedBuildInputs = with self; [ six ];

  };


  # backport from NixOS 16.09
  simplegeneric = pythonPackages.buildPythonPackage rec {
    version = "0.8.1";
    name = "simplegeneric-${version}";
    
    src = pkgs.fetchurl {
      url = "https://pypi.python.org/packages/source/s/simplegeneric/${name}.zip";
      sha256 = "dc972e06094b9af5b855b3df4a646395e43d1c9d0d39ed345b7393560d0b9173";
    };
    
  };


  # backport from NixOS 16.09
  pickleshare = pythonPackages.buildPythonPackage rec {
    version = "0.5";
    name = "pickleshare-${version}";
    
    src = pkgs.fetchurl {
      url = "https://pypi.python.org/packages/source/p/pickleshare/${name}.tar.gz";
      sha256 = "c0be5745035d437dbf55a96f60b7712345b12423f7d0951bd7d8dc2141ca9286";
    };
    
    propagatedBuildInputs = with self; [pathpy];
    
  };



  # backport from NixOS 16.09
  ipykernel = pythonPackages.buildPythonPackage rec {
    version = "4.5.2";
    name = "ipykernel-${version}";

    src = pkgs.fetchFromGitHub {
      owner = "ipython";
      repo = "ipykernel";
      rev = "c3b09fc7f9f2d38ca01b6742dcd70d4b9fe56aae";
      sha256 = "05a5pvfd123prs6hmfhjgj58kp6ygwx418icfvkhi3pn5ri9z61b";
    };

    buildInputs = with pythonPackages; [ nose ] ++ stdenv.lib.optionals isPy27 [mock];
    propagatedBuildInputs = with pythonPackages; [
      ipython
      jupyter_client
      pexpect
      traitlets
      tornado
    ];

    # Tests require backends.
    # I don't want to add all supported backends as propagatedBuildInputs
    doCheck = false;

    passthru = {
        pythonDeps = (gatherPythonRecDep ipykernel);
    };


  };

}


