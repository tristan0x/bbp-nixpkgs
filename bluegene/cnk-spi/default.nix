{ stdenv
, releaseBGQPrefix ? "/bgsys/drivers/V1R2M3/ppc64"
} :


 
stdenv.mkDerivation rec {
	name = "bgq-pami-spi-libs";

	unpackPhase = '' echo "copy SPI and pami BGQ libs to store..."'';

    preferLocalBuild = true;

	dontBuild = true;

       # copy necessary libpami and associated SPI into a derivation
       # to stay isolated from system libs and native MPI libs
       # we would like to avoid side effects by including all IBM libs

	installPhase = ''
		 mkdir -p $out/{include,lib};
		 # copy all necessary PAMI files
		 cp  ${releaseBGQPrefix}/comm/lib/lib*pami* $out/lib;
		 cp -r ${releaseBGQPrefix}/comm/include/pami*h $out/include;

		 # copy all necessary SPI/CNK files
		 mkdir -p $out/include/spi
		 cp -r ${releaseBGQPrefix}/spi/lib/* $out/lib;
		 cp -r ${releaseBGQPrefix}/spi/include/* $out/include;

		 # copy all necessary hwi files
		 mkdir -p $out/include/hwi/include;
		 cp -r ${releaseBGQPrefix}/hwi/include/* $out/include/hwi/include;
		 
		 #copy all firmware related files
		 mkdir -p $out/include/firmware/include;
		 cp -r ${releaseBGQPrefix}/firmware/include/* $out/include/firmware/include;


		 #copy all cnk related files
		 mkdir -p $out/include/cnk/include;
		 cp -r ${releaseBGQPrefix}/cnk/include/* $out/include/cnk/include;




		 # fake the previous hierachy for dummy scripts
		 ln -s $out $out/spi
		 ln -s $out $out/comm
		'';

  passthru = {
	nativePrefix = releaseBGQPrefix;
  };

 }
